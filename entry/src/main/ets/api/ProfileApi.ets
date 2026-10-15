import { Http, ApiResponse } from '../common/Http';

// GET /user/profile 返回的资料结构，字段与 docs/api_spec.md 一致
export interface UserProfileData {
  avatarUrl: string;
  nickname: string;
  phone: string;
  userId: string;
  wechatBound: boolean;
}

// GET /user/learning-stats 返回的学习统计，字段与 docs/api_spec.md 一致。
// 每个字段都可能为 null，调用方负责对 null 做占位兜底
export interface LearningStatsData {
  studyDays: number | null;
  totalAnswers: number | null;
  accuracy: number | null;
  studyHours: number | null;
}

// 个人信息域接口。路径与 docs/api_spec.md 一一对应，改接口先改文档再改这里
export class ProfileApi {
  // 学习数据统计：连续学习天数 / 累计答题 / 平均正确率 / 学习时长
  static learningStats(token: string): Promise<ApiResponse<LearningStatsData>> {
    return Http.get<LearningStatsData>('/user/learning-stats', token);
  }

  // 获取头像、昵称、手机号、微信绑定状态
  static profile(token: string): Promise<ApiResponse<UserProfileData>> {
    return Http.get<UserProfileData>('/user/profile', token);
  }

  // 更新头像（body 带本地图片 uri）
  static updateAvatar(token: string, avatarUri: string): Promise<ApiResponse<string>> {
    const body: AvatarUpdateRequest = { avatarUri: avatarUri };
    return Http.post<string>('/user/update/avatar', body, token);
  }

  // 更新昵称
  static updateNickname(token: string, nickname: string): Promise<ApiResponse<string>> {
    const body: NicknameUpdateRequest = { nickname: nickname };
    return Http.post<string>('/user/update/nickname', body, token);
  }

  // 发送手机号验证码
  static sendSmsCode(token: string, phone: string): Promise<ApiResponse<string>> {
    return Http.get<string>(`/user/send-sms-code?phone=${phone}`, token);
  }

  // 提交新手机号和验证码
  static updatePhone(token: string, phone: string, code: string): Promise<ApiResponse<string>> {
    const body: PhoneUpdateRequest = { phone: phone, code: code };
    return Http.post<string>('/user/update/phone', body, token);
  }

  // 绑定微信
  static bindWechat(token: string): Promise<ApiResponse<string>> {
    let emptyRequest: NicknameUpdateRequest = {} as NicknameUpdateRequest;
    return Http.post<string>('/user/bind/wechat', emptyRequest, token);
  }
}

interface AvatarUpdateRequest {
  avatarUri: string;
}

interface NicknameUpdateRequest {
  nickname: string;
}

interface PhoneUpdateRequest {
  phone: string;
  code: string;
}
