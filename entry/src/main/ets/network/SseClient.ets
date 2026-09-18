import http from '@ohos.net.http';
import { AppConfig } from './AppConfig';
import { HttpRequestHeader, ChatRequest, SseEvent, SSECallbacks } from './ApiTypes';
import { Utf8Decoder } from '../utils/Utf8Decoder';

interface SseRequestOptions {
  method: http.RequestMethod;
  header: HttpRequestHeader;
  extraData?: string;
  connectTimeout?: number;
  readTimeout?: number;
}

/** 内部状态：是否已收到结束信号 */
interface DoneFlag {
  value: boolean;
}

function parseSseLine(line: string, callbacks: SSECallbacks, done: DoneFlag): void {
  const trimmed = line.trim();
  if (!trimmed.startsWith('data:')) {
    return;
  }
  const jsonStr = trimmed.substring(5).trim();
  if (jsonStr === '[DONE]') {
    done.value = true;
    return;
  }
  try {
    const event = JSON.parse(jsonStr) as SseEvent;
    if (event.type === 'message') {
      if (event.content) {
        callbacks.onMessage(event.content);
      }
    } else if (event.type === 'end') {
      callbacks.onEnd(event.conversationId || '');
      done.value = true;
    } else if (event.type === 'error') {
      callbacks.onError(event.content || '未知错误');
      done.value = true;
    }
  } catch (e) {
    console.error(`[SseClient] SSE JSON 解析失败: ${jsonStr}`);
  }
}

/**
 * SSE 流式聊天。
 *
 * 返回一个取消函数 —— 页面销毁时必须调用，否则连接和监听会一直挂着。
 * （重构前没有这个出口，离开页面后流还在跑。）
 */
export async function startChatStream(
  params: ChatRequest,
  token: string,
  callbacks: SSECallbacks
): Promise<() => void> {
  await AppConfig.ensureLoaded();
  const url = AppConfig.url('/chat');
  const httpRequest = http.createHttp();

  const header: HttpRequestHeader = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`
  };

  // 解码器保存跨包状态，解决汉字被切在两个数据包里的问题
  const decoder = new Utf8Decoder();
  let buffer = '';
  const done: DoneFlag = { value: false };
  let closed = false;

  const cleanup = () => {
    if (closed) {
      return;
    }
    closed = true;
    httpRequest.off('dataReceive');
    httpRequest.destroy();
  };

  httpRequest.on('dataReceive', (data: ArrayBuffer) => {
    if (done.value) {
      return;
    }
    buffer += decoder.decode(data);

    const lines = buffer.split('\n');
    // 最后一行可能不完整，留到下一包再拼
    buffer = lines.pop() || '';

    for (const line of lines) {
      parseSseLine(line, callbacks, done);
      if (done.value) {
        cleanup();
        break;
      }
    }
  });

  const options: SseRequestOptions = {
    method: http.RequestMethod.POST,
    header: header,
    extraData: JSON.stringify(params),
    connectTimeout: AppConfig.CONNECT_TIMEOUT,
    readTimeout: 0   // 流式请求不设读超时
  };

  httpRequest.request(url, options)
    .then(() => {
      // 收尾：把解码器里残留的最后一点字节吐出来
      const tail = buffer + decoder.flush();
      if (tail.trim().length > 0 && !done.value) {
        parseSseLine(tail, callbacks, done);
      }
      cleanup();
    })
    .catch((err: Error) => {
      console.error(`[SseClient] 请求失败: ${err.message}`);
      callbacks.onError(err.message);
      cleanup();
    });

  return cleanup;
}
