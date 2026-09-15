
import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';
import { TokenManager } from './tokenManager';
import { HttpResponseCode, HttpRequestHeader, ApiResponse } from './apiTypes';
import { ChatRequest, SSECallbacks, BackendMessage } from './apiTypes';


export interface ChatSSEMessage {
  type: 'message' | 'end' | 'error' | 'artifact';
  content?: string;
  artifact?: string;
  conversationId?: string;
}

export interface DoneFlag {
  value: boolean;
}

// 2. 定义请求参数接口， 定义 HTTP 请求的完整参数结构（请求方法；请求头对象；请求体数据；连接/读取超时时间）
interface HttpRequestOptions {
  method: http.RequestMethod;
  header: HttpRequestHeader;
  extraData?: string;
  connectTimeout?: number;
  readTimeout?: number;
}

// ==================== 顶层工具函数（避免嵌套函数报错） ====================

// ArrayBuffer 转字符串（不依赖 util.TextDecoder，避免兼容性问题）
function arrayBufferToString(buffer: ArrayBuffer): string {
  let uint8Array = new Uint8Array(buffer);
  let result = '';
  for (let i = 0; i < uint8Array.length; i++) {
    result += String.fromCharCode(uint8Array[i]);
  }
  return result;
}

// 解析单行 SSE 数据（提取到顶层，避免嵌套函数报错）
function parseSSELine(
  line: string,
  callbacks: SSECallbacks,
  isDoneRef: DoneFlag
): void {
  let trimmed = line.trim();
  if (!trimmed.startsWith('data:')) {
    return;
  }
  let jsonStr = trimmed.substring(5).trim();
  if (jsonStr === '[DONE]') {
    isDoneRef.value = true;
    return;
  }
  try {
    let sseData: ChatSSEMessage = JSON.parse(jsonStr) as ChatSSEMessage;
    // 处理 message 事件（包含可选的 artifact 字段）
    if (sseData.type === 'message') {
      // 如果有 artifact 字段，先触发 artifact 回调
      if (sseData.artifact) {
        callbacks.onArtifact(sseData.artifact);
      }
      // 再触发 message 回调（追加文本）
      if (sseData.content) {
        callbacks.onMessage(sseData.content);
      }
    } else if (sseData.type === 'artifact') {
      // 兼容：如果后端把 artifact 作为独立事件发送
      if (sseData.artifact) {
        callbacks.onArtifact(sseData.artifact);
      }
    } else if (sseData.type === 'end') {
      callbacks.onEnd(sseData.conversationId || '');
      isDoneRef.value = true;
    } else if (sseData.type === 'error') {
      callbacks.onError(sseData.content || '未知错误');
      isDoneRef.value = true;
    }
  } catch (e) {
    console.error('解析SSE JSON数据失败:', e);
  }
}

// 基础地址属性
export class ApiService {
  private static baseURL: string = 'http://your-backend-url.com/api/v1'; // 替换为实际基础地址

  // 核心请求方法；<T> ： 让返回值类型动态适配不同接口。 接口路径，方法，实体数据

  public static async httpRequest<T>(path: string, method: http.RequestMethod, data?: Object): Promise<T> {
    let httpRequest = http.createHttp();
    let url = `${ApiService.baseURL}${path}`;

    // 组装url,把基础地址和接口路径拼起来

    // 准备基础请求头
    let header: HttpRequestHeader = {
      'Content-Type': 'application/json'
    };

    try {
      // --- 请求拦截器 (Request Interceptor) ---
      // 自动获取本地 Token 并添加到 Header 中
      let token = await TokenManager.getToken();
      if (token !== null) {
        header.Authorization = `Bearer ${token}`;
      }

      // 准备请求参数选项;设置超时时间为 5 秒
      let options: HttpRequestOptions = {
        method: method,
        header: header,
        connectTimeout: 5000,
        readTimeout: 5000
      };
      if (data && method === http.RequestMethod.POST) {
        options.extraData = JSON.stringify(data);
      }
      // 如果是 POST 请求且有数据，把数据转成 JSON 字符串放入 extraData

      // 发起网络请求
      let resp = await httpRequest.request(url, options);

      // --- 响应拦截器 (Response Interceptor) ---
      if (resp.responseCode === 200) {
        let resData = JSON.parse(resp.result as string) as ApiResponse<T>;
        if (resData.code === 0) {
          return resData.data;    // 成功：返回 data 字段
        } else {
          // 业务逻辑错误抛出
          throw new Error(resData.message);
        }
      } else {
        // 网络错误或服务器错误抛出
        throw new Error(`请求失败，状态码: ${resp.responseCode}`);
      }

    } catch (err) {
      // ArkTS 要求 catch 的 err 必须明确指定类型
      let error = err as BusinessError;
      console.error(`网络请求异常: ${error.message}`);

      // 如果是 401 可以调用 TokenManager.logout() 跳转登录页
      if (error.message.includes('状态码: 401')) {
        await TokenManager.logout();
      }
      // 向上抛出标准 Error 对象，避免 arkts-limited-throw 报错
      throw new Error(error.message);

    } finally {
      // 销毁请求对象，释放资源
      httpRequest.destroy();
    }
  }
}


// ==================== SSE 流式聊天请求 ====================
export function startChatStream(
  params: ChatRequest,
  token: string,
  callbacks: SSECallbacks
) {
  // 1. 构造完整的请求 URL（模拟器用 10.0.2.2，真机改成电脑的局域网 IP）
  const url = `http://10.0.2.2:8080/api/v1/chat`; // 注意这里根据实际情况替换

  // 2. 创建 http 请求对象
  let httpRequest = http.createHttp();

  // 3. 准备请求头
  const header: HttpRequestHeader = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };

  // 4. 缓冲区：处理 SSE 数据分包问题（一次 dataReceive 可能只收到半个事件）
  let buffer = '';
  let isDoneRef: DoneFlag = { value: false };

  // 5. 设置响应体监听，处理 SSE 数据流
  httpRequest.on('dataReceive', (data: ArrayBuffer) => {
    // 用顶层函数转字符串（不依赖 util.TextDecoder）
    let receivedText = arrayBufferToString(data);
    // 拼接到缓冲区
    buffer += receivedText;

    // 按 \n 分割，逐行解析
    let lines = buffer.split('\n');
    // 最后一行可能是不完整的数据，放回 buffer 等下次拼接
    buffer = lines.pop() || '';

    for (const line of lines) {
      parseSSELine(line, callbacks, isDoneRef);
      if (isDoneRef.value) {
        break;
      }
    }
  });

  // 6. 发起请求（使用 HttpRequestOptions 接口类型，避免类型报错）
  let requestOptions: HttpRequestOptions = {
    method: http.RequestMethod.POST,
    header: header,
    extraData: JSON.stringify(params),
    connectTimeout: 5000,
    readTimeout: 0 // SSE 流式请求不设读取超时，0 表示无限等待
  };

  httpRequest.request(url, requestOptions)
    .then(() => {
      console.info('SSE请求发送成功，等待数据流...');
    })
    .catch((err: Error) => {
      console.error('SSE请求发送失败:', err.message);
      callbacks.onError(err.message);
      httpRequest.destroy();
    });
}