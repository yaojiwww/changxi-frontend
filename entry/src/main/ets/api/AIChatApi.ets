import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo } from '@kit.CoreFileKit';
import { AppConfig } from '../common/AppConfig';
import { ApiResponse, CODE_OK } from '../common/Http';
import { Utf8ChunkDecoder } from '../common/Utf8ChunkDecoder';

const DOMAIN = 0x0000;
const TAG = 'AIChatApi';

// 后端 AI 接口路径（相对 AppConfig.apiPrefix）
const PATH: string = '/ai/chat';
// 聊天图片上传：multipart/form-data，字段名 file；返回 data.url 供 /ai/chat 引用
const UPLOAD_PATH: string = '/ai/upload';
// 图片上传比普通接口慢，给 60 秒
const UPLOAD_READ_TIMEOUT_MS: number = 60000;

// 读超时。别的接口沿用配置里的 10 秒，但 Dify 的智能体要先想、再调工具，
// 首字经常十几秒才到，10 秒会在它开口之前就把连接掐了。
const AI_READ_TIMEOUT_MS: number = 180000;

// 一轮提问的请求体
export interface AIChatRequest {
  query: string;
  conversationId: string;   // 上一轮后端下发的会话 ID，首轮传空串
  mode: string;             // AI_MODE_SOLVE / AI_MODE_PLAN，见 model/ChatModels
  imageUrl: string;         // 先经 /ai/upload 换来的图片地址，无图传空串
}

// POST /ai/upload 的返回数据
export interface AIUploadData {
  url: string;
}

// 后端下发的一个流式事件。字段名跟 Dify 的事件保持一致（后端只转发不改名）：
//   message / agent_message —— answer 是增量文本
//   message_end             —— 本轮结束
//   error                   —— 出错，message 是原因
// conversationId 每个事件都带，取到就存下，下一轮带上即多轮记忆。
export interface AIChatEvent {
  event: string;
  answer?: string;
  conversationId?: string;
  message?: string;
}

// 流式回调。内容是边收边出的，所以走回调而不是等 Promise 返回一个整段
export interface AIChatHandlers {
  onDelta: (text: string) => void;          // 一段增量文本
  onConversationId: (id: string) => void;   // 会话 ID
  onFail: (message: string) => void;        // 流里的 error 事件
}

// AI 伴学接口。契约见本文件顶部注释，改接口先改这里再改后端
export class AIChatApi {
  // 上传一张聊天图片，返回后端可访问的 URL。
  // 相册 URI 是临时授权，不能直接交给 http 的 filePath（部分机型读不到），
  // 所以先经 fileIo 读成 ArrayBuffer，再用 multiFormDataList 上传。
  static async uploadImage(uri: string, token: string): Promise<string> {
    const cfg = AppConfig.get();
    const request = http.createHttp();
    const lower: string = uri.toLowerCase();
    const isPng: boolean = lower.endsWith('.png');
    const fileName: string = isPng ? 'chat.png' : 'chat.jpg';
    const contentType: string = isPng ? 'image/png' : 'image/jpeg';

    try {
      const data: ArrayBuffer = AIChatApi.readFile(uri);
      const headers: Record<string, string> = {};
      if (token !== undefined && token !== '') {
        headers['Authorization'] = `Bearer ${token}`;
      }

      const response = await request.request(cfg.baseUrl + cfg.apiPrefix + UPLOAD_PATH, {
        method: http.RequestMethod.POST,
        header: headers,
        // 不要手动设置 Content-Type，multipart 的 boundary 由网络层生成
        multiFormDataList: [{
          name: 'file',
          contentType: contentType,
          remoteFileName: fileName,
          data: data
        }],
        connectTimeout: cfg.connectTimeout,
        readTimeout: UPLOAD_READ_TIMEOUT_MS
      });

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`图片上传失败（HTTP ${response.responseCode}）`);
      }
      const res = JSON.parse(response.result as string) as ApiResponse<AIUploadData>;
      if (res.code !== CODE_OK || res.data === null || res.data.url === '') {
        throw new Error(res.message !== '' ? res.message : '图片上传失败');
      }
      return res.data.url;
    } catch (err) {
      // 上传失败统一成一句用户能看懂的话，避免把底层异常直接弹出来
      throw new Error(`图片上传失败：${(err as Error).message}`);
    } finally {
      request.destroy();
    }
  }

  // 读取相册 URI 指向的文件。fileIo 能直接打开 Picker 授权过的 URI
  private static readFile(uri: string): ArrayBuffer {
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    try {
      const stat = fileIo.statSync(file.fd);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      return buffer;
    } finally {
      fileIo.closeSync(file);
    }
  }

  // 发一轮提问，边收边回调。
  // resolve：整轮跑完（含「流里回了 error 事件」的情况，那种走 onFail）。
  // reject：连流都没建立起来（网络异常、后端在流式之前按统一契约回了错误信封）。
  //
  // ★ 这里**只有流式一条路**，不再有"拿不到流就退化成一次性请求"的降级分支。
  //   历史：预览器里 util.TextDecoder 是 mock、解码永远得到空串，当时的判断是
  //   "流式在预览器里跑不通"，于是加了降级——结果就是预览器上整段回答在最后
  //   一起蹦出来，看起来根本不流式。真正坏的只有解码那一步，换成
  //   common/Utf8ChunkDecoder 之后流式在预览器上本来就是通的，降级路径反而成了
  //   一个会把真问题盖住的第二实现。宁可直接报错，也不要一条悄悄改行为的分支。
  static stream(body: AIChatRequest, token: string, handlers: AIChatHandlers): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (reason: Error) => void): void => {
      const cfg = AppConfig.get();
      const url: string = cfg.baseUrl + cfg.apiPrefix + PATH;
      const request = http.createHttp();
      // 一个请求一个解码器：它是"跨块"有状态的，不能两个流共用
      const decoder = new Utf8ChunkDecoder();

      let pending: string = '';      // 还没凑齐一个完整 SSE 事件的残留文本
      let raw: string = '';          // 原始响应文本，用来识别「后端压根没走流式」
      let sawEvent: boolean = false; // 是否解析出过任何 SSE 事件
      let settled: boolean = false;

      const finish = (err: Error | undefined): void => {
        if (settled) {
          return;
        }
        settled = true;
        request.off('dataReceive');
        request.off('dataEnd');
        request.destroy();   // 用完必须销毁，否则连接会泄漏
        if (err === undefined) {
          resolve();
        } else {
          reject(err);
        }
      };

      request.on('dataReceive', (data: ArrayBuffer): void => {
        const text: string = decoder.decode(new Uint8Array(data));
        if (text === '') {
          return;   // 这一块整个是个被切开的字符，等下一块拼完再说
        }
        raw += text;
        // 统一成 \n 再切：不同网关可能给 \r\n。每次都规整整段残留是必要的——
        // 万一 \r 和 \n 被切在两个 chunk 里，只规整新来的那截就会漏掉这一对
        pending = (pending + text).split('\r\n').join('\n');
        // SSE 事件之间以空行分隔，一次可能到齐好几个
        let sep: number = pending.indexOf('\n\n');
        while (sep >= 0) {
          const block: string = pending.substring(0, sep);
          pending = pending.substring(sep + 2);
          if (AIChatApi.dispatchBlock(block, handlers)) {
            sawEvent = true;
          }
          sep = pending.indexOf('\n\n');
        }
      });

      request.on('dataEnd', (): void => {
        // 收尾：最后一个事件后面不一定带空行
        const tail: string = pending.trim();
        pending = '';
        if (tail !== '' && AIChatApi.dispatchBlock(tail, handlers)) {
          sawEvent = true;
        }
        if (!sawEvent) {
          // 一个事件都没解析出来，说明响应根本不是流：多半是流建立之前就失败了，
          // 后端按统一契约回了 JSON 信封。把它的 message 提出来当原因，
          // 比抛一句「AI 没有响应」有用得多
          finish(AIChatApi.beforeStreamError(raw));
          return;
        }
        finish(undefined);
      });

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token !== undefined && token !== '') {
        headers['Authorization'] = `Bearer ${token}`;
      }
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(body),
        connectTimeout: cfg.connectTimeout,
        readTimeout: AI_READ_TIMEOUT_MS
      };

      hilog.info(DOMAIN, TAG, 'POST %{public}s（流式）', url);
      // 流式必须用 requestInStream：普通 request() 会把整个响应攒完才交出来，
      // 逐字上屏就没了。dataReceive/dataEnd 要在发起之前订阅好
      request.requestInStream(url, options).then((code: number): void => {
        hilog.info(DOMAIN, TAG, '← %{public}d', code);
      }).catch((err: Error): void => {
        finish(new Error(`AI 请求失败：${err.message}`));
      });
    });
  }

  // ---------------------------------------------------------------------------
  // 解析一个 SSE 事件块并派发。返回是否真的派发了一个事件。
  // ---------------------------------------------------------------------------
  private static dispatchBlock(block: string, handlers: AIChatHandlers): boolean {
    let payload: string = '';
    const lines: string[] = block.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const line: string = lines[i].trim();
      if (!line.startsWith('data:')) {
        continue;   // 忽略注释行（比如后端开流时那句 ": stream opened"）、event: 行等
      }
      const part: string = line.substring(5).trim();
      if (part === '') {
        continue;
      }
      // SSE 规范允许一个事件拆成多行 data:，按换行拼回去
      payload = payload === '' ? part : `${payload}\n${part}`;
    }
    if (payload === '') {
      return false;
    }
    AIChatApi.dispatch(payload, handlers);
    return true;
  }

  // 处理一个事件
  private static dispatch(payload: string, handlers: AIChatHandlers): void {
    let ev: AIChatEvent;
    try {
      ev = JSON.parse(payload) as AIChatEvent;
    } catch (err) {
      // 坏掉的事件（解析失败、结构不对）直接跳过，别让一个坏事件毁掉整轮回答
      hilog.warn(DOMAIN, TAG, '跳过解析不了的事件：%{public}s', payload);
      return;
    }

    const cid: string | undefined = ev.conversationId;
    if (cid !== undefined && cid !== '') {
      handlers.onConversationId(cid);
    }

    if (ev.event === 'error') {
      const reason: string | undefined = ev.message;
      handlers.onFail(reason !== undefined && reason !== '' ? reason : 'AI 服务出错');
      return;
    }

    const delta: string | undefined = ev.answer;
    if (delta !== undefined && delta !== '') {
      handlers.onDelta(delta);
    }
  }

  // 流建立之前的失败：后端回的是项目统一的 JSON 信封（HTTP 4xx）
  private static beforeStreamError(raw: string): Error {
    const text: string = raw.trim();
    if (text.startsWith('{')) {
      try {
        const res: ApiResponse<Object> = JSON.parse(text) as ApiResponse<Object>;
        const msg: string = res.message !== undefined && res.message !== '' ? res.message : 'AI 服务暂不可用';
        return new Error(msg);
      } catch (err) {
        // 不是合法 JSON：往下走，用兜底文案
      }
    }
    if (text === '') {
      return new Error('AI 没有返回任何内容，请稍后再试');
    }
    const head: string = text.length > 80 ? text.substring(0, 80) + '…' : text;
    return new Error(`AI 返回了无法识别的内容：${head}`);
  }
}
