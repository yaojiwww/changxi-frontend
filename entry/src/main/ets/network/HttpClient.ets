import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';
import { TokenManager } from './TokenManager';
import { AppConfig } from './AppConfig';
import { ApiResponse, HttpRequestHeader } from './ApiTypes';

interface HttpRequestOptions {
  method: http.RequestMethod;
  header: HttpRequestHeader;
  extraData?: string;
  connectTimeout?: number;
  readTimeout?: number;
}

/**
 * 普通 HTTP 请求（非流式）。
 * 自动带 Token，自动拆 { code, message, data } 信封，只把 data 交给上层。
 */
export class HttpClient {

  /** GET，params 会拼成 query string */
  static async get<T>(path: string, params?: Map<string, string>): Promise<T> {
    let fullPath = path;
    if (params && params.size > 0) {
      const parts: string[] = [];
      params.forEach((value: string, key: string) => {
        parts.push(`${key}=${encodeURIComponent(value)}`);
      });
      fullPath = `${path}?${parts.join('&')}`;
    }
    return HttpClient.request<T>(fullPath, http.RequestMethod.GET);
  }

  /** POST，body 会序列化成 JSON */
  static async post<T>(path: string, body?: Object): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.POST, body);
  }

  private static async request<T>(path: string, method: http.RequestMethod, body?: Object): Promise<T> {
    // 确保配置已从 app_config.json 加载，再拼地址
    await AppConfig.ensureLoaded();
    const httpRequest = http.createHttp();
    const url = AppConfig.url(path);

    const header: HttpRequestHeader = { 'Content-Type': 'application/json' };

    try {
      // 请求拦截：自动附加 Token
      const token = await TokenManager.getToken();
      if (token !== null) {
        header.Authorization = `Bearer ${token}`;
      }

      const options: HttpRequestOptions = {
        method: method,
        header: header,
        connectTimeout: AppConfig.CONNECT_TIMEOUT,
        readTimeout: AppConfig.READ_TIMEOUT
      };
      if (body && method === http.RequestMethod.POST) {
        options.extraData = JSON.stringify(body);
      }

      const resp = await httpRequest.request(url, options);

      // ---- 响应拦截 ----
      // 关键：本后端的业务错误会带非 200 的 HTTP 状态码，
      // 实测登录失败返回 400 + {"code":2,"message":"手机号未注册","data":{}}。
      // 所以必须先尝试解析响应体拿到真正的 message，
      // 不能一看到非 200 就抛"状态码 400"——那样用户只会看到一串数字。
      let parsed: ApiResponse<T> | null = null;
      try {
        parsed = JSON.parse(resp.result as string) as ApiResponse<T>;
      } catch (parseErr) {
        parsed = null;
      }

      if (resp.responseCode === 401) {
        await TokenManager.clear();
        throw new Error(parsed !== null ? parsed.message : '登录已过期，请重新登录');
      }

      // 响应体不是 JSON，只能退回报状态码
      if (parsed === null) {
        throw new Error(`请求失败，状态码: ${resp.responseCode}`);
      }

      // 成功判定看业务 code，不看 HTTP 状态码。
      // 已知 code:2 = 失败；成功值文档没写，0 和 200 都先当成功。
      if (parsed.code !== 0 && parsed.code !== 200) {
        throw new Error(parsed.message);
      }
      return parsed.data;

    } catch (e) {
      const err = e as BusinessError;
      console.error(`[HttpClient] ${method} ${url} 失败: ${err.message}`);
      throw new Error(err.message);
    } finally {
      httpRequest.destroy();
    }
  }
}
