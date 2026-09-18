import { HttpClient } from '../network/HttpClient';
import { TokenManager } from '../network/TokenManager';
import {
  SendCodeRequest, RegisterRequest, LoginRequest, LogoutRequest, CodePurpose
} from '../network/ApiTypes';

/**
 * 认证数据源。
 *
 * 原来这几个请求直接写在 Index.ets 顶部，参数写死成 '13800138000' / 'MyPass123'，
 * 而且没有任何地方调用它们 —— 现在收拢到这里，参数由调用方传入。
 *
 * ── 后端接口契约 ──────────────────────────────
 * POST /api/v1/auth/send-code  { number, purpose }        → data: null
 * POST /api/v1/auth/register   { number, code, password } → data: "<token 字符串>"
 * POST /api/v1/auth/login      { number, password }       → data: "<token 字符串>"
 * POST /api/v1/auth/logout     { number }                 → data: null
 *
 * 全部沿用 { code, message, data } 信封，code === 0 表示成功。
 * ────────────────────────────────────────────
 */
export class AuthRepository {

  static async sendCode(phone: string, purpose: CodePurpose): Promise<void> {
    const body: SendCodeRequest = { number: phone, purpose: purpose };
    await HttpClient.post<null>('/auth/send-code', body);
  }

  /** 注册成功后直接落盘 Token */
  static async register(phone: string, code: string, password: string): Promise<void> {
    const body: RegisterRequest = { number: phone, code: code, password: password };
    const token = await HttpClient.post<string>('/auth/register', body);
    await TokenManager.setToken(token);
  }

  /** 登录成功后直接落盘 Token */
  static async login(phone: string, password: string): Promise<void> {
    const body: LoginRequest = { number: phone, password: password };
    const token = await HttpClient.post<string>('/auth/login', body);
    await TokenManager.setToken(token);
  }

  /** 无论后端是否成功，本地登录态都要清掉 */
  static async logout(phone: string): Promise<void> {
    const body: LogoutRequest = { number: phone };
    try {
      await HttpClient.post<string>('/auth/logout', body);
    } catch (e) {
      const err = e as Error;
      console.error(`[AuthRepository] 登出接口失败，仍清除本地登录态: ${err.message}`);
    }
    await TokenManager.clear();
  }

  static async isLoggedIn(): Promise<boolean> {
    const token = await TokenManager.getToken();
    return token !== null;
  }
}
