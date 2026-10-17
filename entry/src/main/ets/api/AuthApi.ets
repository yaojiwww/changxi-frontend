import { Http, ApiResponse } from '../common/Http';

// 登录请求体：字段与 docs/api_spec.md 一致。
// ArkTS 不允许无类型的对象字面量，所以每个请求体都要像这样先声明接口
export interface LoginRequest {
  number: string;
  password: string;
}

// 认证域接口。路径与 docs/api_spec.md 一一对应，改接口先改文档再改这里
export class AuthApi {
  // 登录。成功时 data 是 token 字符串，失败时 data 是 null
  static login(phone: string, password: string): Promise<ApiResponse<string>> {
    const body: LoginRequest = { number: phone, password: password };
    return Http.post<string>('/auth/login', body);
  }
}
