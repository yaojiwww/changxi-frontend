import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConfig } from './AppConfig';

const DOMAIN = 0x0000;
const TAG = 'Http';

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
  // HttpResponse.result 的类型是 string | Object | ArrayBuffer，统一成字符串
  private static textOf(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result as string;
    }
    if (result instanceof ArrayBuffer) {
      return util.TextDecoder.create('utf-8').decodeToString(new Uint8Array(result as ArrayBuffer));
    }
    return JSON.stringify(result);
  }

  // 解析响应体。空体和「不是 JSON」都抛出带 METHOD、URL、状态码的错。
  // 以前这里直接 JSON.parse，一份空响应体只会得到一句没有任何上下文的
  // 「Unexpected Text in JSON: Empty Text」，联调时根本看不出是哪条请求挂了。
  private static parse<T>(method: string, url: string, statusCode: number,
    result: string | Object | ArrayBuffer): ApiResponse<T> {
    const raw: string = Http.textOf(result);
    if (raw.trim() === '') {
      hilog.error(DOMAIN, TAG, '%{public}s %{public}s 响应体为空 (HTTP %{public}d)', method, url, statusCode);
      throw new Error(`接口无响应体：${method} ${url} (HTTP ${statusCode})`);
    }
    try {
      return JSON.parse(raw) as ApiResponse<T>;
    } catch (err) {
      // 拿到了内容但不是合法 JSON：截一段原文带进报错，直接能看出后端回了什么
      const head: string = raw.length > 160 ? raw.substring(0, 160) + '…' : raw;
      hilog.error(DOMAIN, TAG, '%{public}s %{public}s 响应不是 JSON (HTTP %{public}d)：%{public}s',
        method, url, statusCode, head);
      throw new Error(`接口返回的不是 JSON：${method} ${url} (HTTP ${statusCode})，原文 ${head}`);
    }
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

      const url = cfg.baseUrl + cfg.apiPrefix + path;
      hilog.info(DOMAIN, TAG, 'GET %{public}s', url);

      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: cfg.connectTimeout,
        readTimeout: cfg.readTimeout
      });

      hilog.info(DOMAIN, TAG, '← %{public}d %{public}s',
        response.responseCode, response.result as string);

      // 与 post 相同的约定：成败只看 body 里的 code
      return Http.parse<T>('GET', url, response.responseCode, response.result);
    } finally {
      request.destroy();
    }
  }

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

      const url = cfg.baseUrl + cfg.apiPrefix + path;
      // 故意不打 body：登录请求里带明文密码，日志会落盘
      hilog.info(DOMAIN, TAG, 'POST %{public}s', url);

      const response = await request.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(body),
        connectTimeout: cfg.connectTimeout,
        readTimeout: cfg.readTimeout
      });

      hilog.info(DOMAIN, TAG, '← %{public}d %{public}s',
        response.responseCode, response.result as string);

      // 约定：失败时 HTTP 状态码是 4xx，但 body 结构不变。
      // 所以这里不看 responseCode，直接解析 body，成功与否交给 code 判断。
      return Http.parse<T>('POST', url, response.responseCode, response.result);
    } finally {
      request.destroy();   // 用完必须销毁，否则连接会泄漏
    }
  }
}
