import { Http, ApiResponse } from '../common/Http';

// 版本更新信息，字段与 docs/api_spec.md 一致
export interface AppVersionInfo {
  version: string;
  force: boolean;
  note: string;
}

interface EmptyParams {
}

// 用户/账号域接口。路径与 docs/api_spec.md 一一对应，改接口先改文档再改这里
export class UserApi {
  // 考试时间。成功时 data 是日期字符串，未设置或失败时 data 是 null
  static examDate(token: string): Promise<ApiResponse<string>> {
    return Http.get<string>('/user/exam-date', token);
  }

  // 检查版本更新。成功时 data 是最新版本信息，失败时 data 是 null
  static appVersion(token?: string): Promise<ApiResponse<AppVersionInfo>> {
    return Http.get<AppVersionInfo>('/app/version', token);
  }

  // 退出登录。是否成功都由调用方决定是否清本地 token。
  // 文档 #4 写的请求体含 number，但客户端未存手机号，按 token 鉴权传空对象
  static logout(token: string): Promise<ApiResponse<string>> {
    return Http.post<string>('/auth/logout', {} as EmptyParams, token);
  }

  // 注销账号。成功后服务端删除账号，调用方负责清本地并回登录页
  static deleteAccount(token: string): Promise<ApiResponse<string>> {
    return Http.post<string>('/account/delete', {} as EmptyParams, token);
  }
}
