import { http } from '@kit.NetworkKit';
import { AppConfig } from './AppConfig';

// 后端统一响应结构，见 docs/api_spec.md
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T | null;
}

// 业务码：0 表示成功
export const CODE_OK: number = 0;
// 未登录 / 令牌无效 / 已登出。见 changxi-backend/src/api_response.cj
export const CODE_UNAUTHORIZED: number = 1003;

// 令牌失效时的统一回调。EntryAbility 注册，负责清理会话并回登录页
export type AuthFailureHandler = () => void;

// 通用网络请求。业务接口不直接用这里，而是经 api/ 目录下的类调用
export class Http {
  private static authFailureHandler: AuthFailureHandler | undefined = undefined;

  static setAuthFailureHandler(handler: AuthFailureHandler): void {
    Http.authFailureHandler = handler;
  }

  // 解析响应体。后端约定：即使 HTTP 是 4xx，body 仍是 {code,message,data}，
  // 所以优先按业务码判断；body 不是约定结构时才按 HTTP 状态报错。
  // 业务码 1003 会触发全局回调，避免每个调用方各写一遍「跳登录」。
  private static parse<T>(response: http.HttpResponse, path: string): ApiResponse<T> {
    let parsed: ApiResponse<T> | null = null;
    try {
      parsed = JSON.parse(response.result as string) as ApiResponse<T>;
    } catch (err) {
      parsed = null;
    }

    if (parsed !== null && parsed.code !== undefined) {
      if (parsed.code === CODE_UNAUTHORIZED) {
        const handler: AuthFailureHandler | undefined = Http.authFailureHandler;
        if (handler !== undefined) {
          handler();
        }
      }
      return parsed;
    }

    // 非 JSON / 结构不对：带着 HTTP 状态抛出去，调用方按网络异常处理
    throw new Error(`HTTP ${response.responseCode}（${path}）`);
  }
  // 发起 GET。token 传了就带 Authorization 头
  static async get<T>(path: string, token?: string): Promise<ApiResponse<T>> {
    const cfg = AppConfig.get();
    const request = http.createHttp();
    try {
      const headers: Record<string, string> = {};
      if (token !== undefined && token !== '') {
        headers['Authorization'] = `Bearer ${token}`;
      }

      const response = await request.request(cfg.baseUrl + cfg.apiPrefix + path, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: cfg.connectTimeout,
        readTimeout: cfg.readTimeout
      });

      // 与 post 相同的约定：body 是约定结构时以 code 为准，否则按 HTTP 状态报错
      return Http.parse<T>(response, path);
    } finally {
      request.destroy();
    }
  }

  static async post<T>(
    path: string,
    body: object,
    token?: string
  ): Promise<ApiResponse<T>> {
    const cfg = AppConfig.get();
    const request = http.createHttp();
    try {
      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token !== undefined && token !== '') {
        headers['Authorization'] = `Bearer ${token}`;
      }

      const response = await request.request(cfg.baseUrl + cfg.apiPrefix + path, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(body),
        connectTimeout: cfg.connectTimeout,
        readTimeout: cfg.readTimeout
      });

      // 约定：失败时 HTTP 状态码是 4xx，但 body 结构不变。
      // 所以优先解析 body、按 code 判断；不是约定结构时才按 HTTP 状态报错。
      return Http.parse<T>(response, path);
    } finally {
      request.destroy();   // 用完必须销毁，否则连接会泄漏
    }
  }
}
