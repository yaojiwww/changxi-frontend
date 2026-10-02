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

// 通用网络请求。业务接口不直接用这里，而是经 api/ 目录下的类调用
export class Http {
  // 发起 POST。token 传了就带 Authorization 头
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
      // 所以这里不看 responseCode，直接解析 body，成功与否交给 code 判断。
      return JSON.parse(response.result as string) as ApiResponse<T>;
    } finally {
      request.destroy();   // 用完必须销毁，否则连接会泄漏
    }
  }
}
