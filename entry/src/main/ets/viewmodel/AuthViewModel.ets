import { AuthRepository } from '../repository/AuthRepository';
import { CodePurpose } from '../network/ApiTypes';

/**
 * 登录 / 注册业务状态。
 *
 * 取代原来写在 Index.ets 顶部、参数写死成 '13800138000' / 'MyPass123'
 * 且无人调用的那四个函数。
 */
@Observed
export class AuthViewModel {
  phone: string = '';
  code: string = '';
  password: string = '';

  isLoggedIn: boolean = false;
  isLoading: boolean = false;
  errorMessage: string = '';
  /** 验证码发送成功后置为 true，供 UI 显示"已发送" */
  codeSent: boolean = false;

  updatePhone(v: string): void {
    this.phone = v;
  }

  updateCode(v: string): void {
    this.code = v;
  }

  updatePassword(v: string): void {
    this.password = v;
  }

  async refreshLoginState(): Promise<void> {
    this.isLoggedIn = await AuthRepository.isLoggedIn();
  }

  async sendCode(purpose: CodePurpose): Promise<void> {
    if (this.phone.length === 0) {
      this.errorMessage = '请先填写手机号';
      return;
    }
    await this.run(async () => {
      await AuthRepository.sendCode(this.phone, purpose);
      this.codeSent = true;
    });
  }

  async register(): Promise<void> {
    await this.run(async () => {
      await AuthRepository.register(this.phone, this.code, this.password);
      this.isLoggedIn = true;
    });
  }

  async login(): Promise<void> {
    await this.run(async () => {
      await AuthRepository.login(this.phone, this.password);
      this.isLoggedIn = true;
    });
  }

  async logout(): Promise<void> {
    await this.run(async () => {
      await AuthRepository.logout(this.phone);
      this.isLoggedIn = false;
    });
  }

  /** 统一处理 loading 和错误，避免每个方法都抄一遍 try/catch */
  private async run(action: () => Promise<void>): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      await action();
    } catch (e) {
      const err = e as Error;
      this.errorMessage = err.message;
    } finally {
      this.isLoading = false;
    }
  }
}
