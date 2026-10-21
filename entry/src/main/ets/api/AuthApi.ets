import { Http, ApiResponse } from '../common/Http';

// 登录请求体：字段与 docs/api_spec.md 一致。
// ArkTS 不允许无类型的对象字面量，所以每个请求体都要像这样先声明接口
export interface LoginRequest {
  number: string;
  password: string;
}

// 发送验证码请求体。purpose 固定传 register；开发期验证码只打到服务端终端
export interface SendCodeRequest {
  number: string;
  purpose: string;
}

// 注册请求体。code 是短信验证码（字符串），不是响应体里的业务码
export interface RegisterRequest {
  number: string;
  code: string;
  password: string;
}

// 认证域接口。路径与 docs/api_spec.md 一一对应，改接口先改文档再改这里
export class AuthApi {
  // 登录。成功时 data 是 token 字符串，失败时 data 是 null
  static login(phone: string, password: string): Promise<ApiResponse<string>> {
    const body: LoginRequest = { number: phone, password: password };
    return Http.post<string>('/auth/login', body);
  }

  // 发送注册验证码。成功时 data 是 null（验证码不通过接口返回）
  static sendCode(phone: string): Promise<ApiResponse<string>> {
    const body: SendCodeRequest = { number: phone, purpose: 'register' };
    return Http.post<string>('/auth/send-code', body);
  }

  // 注册。成功响应与登录逐字节一致：data 都是 token，后续处理可完全复用
  static register(phone: string, code: string, password: string): Promise<ApiResponse<string>> {
    const body: RegisterRequest = { number: phone, code: code, password: password };
    return Http.post<string>('/auth/register', body);
  }
}
