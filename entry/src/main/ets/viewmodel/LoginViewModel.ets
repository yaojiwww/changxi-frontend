import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { AppConfig } from '../common/AppConfig';
import { TokenStore } from '../common/TokenStore';
import { OnboardingCache } from '../common/OnboardingCache';
import { GoalCache } from '../common/GoalModel';
import { ExamDateCache } from '../common/ExamDateModel';
import { ProfileCache, isValidPhone } from '../common/ProfileModel';
import { TokenIdentity } from '../common/TokenIdentity';
import { AuthApi } from '../api/AuthApi';
import { CODE_OK } from '../common/Http';

// 验证码倒计时秒数（与后端验证码有效期无关，只用于防连点）
const COUNTDOWN_SECONDS: number = 60;

// 登录/注册页 ViewModel：持有全部表单状态与取数逻辑，不碰 UI。
// 失败一律 throw Error，由页面 catch 后 toast。
@ObservedV2
export class LoginViewModel {
  @Trace phone: string = '';
  @Trace password: string = '';
  @Trace code: string = '';              // 注册模式下的短信验证码
  @Trace agreed: boolean = false;
  @Trace isLoading: boolean = false;
  @Trace modeRegister: boolean = false;  // false=登录，true=注册
  @Trace isSending: boolean = false;     // 验证码请求中
  @Trace countdown: number = 0;          // 验证码倒计时剩余秒数

  // 登录/注册成功后才有意义：true 表示要走引导页
  @Trace needOnboarding: boolean = false;

  private timerId: number = -1;

  // 页面 aboutToAppear 调一次，把配置与本地存储准备好
  async init(context: common.Context): Promise<void> {
    await AppConfig.load(context);
    await TokenStore.init(context);
    await OnboardingCache.init(context);
    await GoalCache.init(context);
    await ExamDateCache.init(context);
    await ProfileCache.init(context);
  }

  // 登录/注册切换。清掉另一模式残留的验证码与倒计时，避免误提交
  switchMode(register: boolean): void {
    this.modeRegister = register;
    this.code = '';
    this.clearCountdown();
  }

  // 发送注册验证码。开发期验证码只打到后端终端，接口成功即开始倒计时
  async sendCode(): Promise<void> {
    if (this.isSending || this.countdown > 0) {
      return;
    }
    if (this.phone === '') {
      throw new Error('请先输入手机号');
    }
    if (!isValidPhone(this.phone)) {
      throw new Error('手机号格式不正确');
    }

    this.isSending = true;
    try {
      const res = await AuthApi.sendCode(this.phone);
      if (res.code !== CODE_OK) {
        throw new Error(res.message);
      }
      this.startCountdown();
    } catch (err) {
      throw this.toDisplayError(err);
    } finally {
      this.isSending = false;
    }
  }

  // 提交：按当前模式走登录或注册
  async submit(): Promise<void> {
    if (this.modeRegister) {
      await this.register();
    } else {
      await this.login();
    }
  }

  // 登录。成功返回；失败 throw Error，message 可直接展示
  async login(): Promise<void> {
    if (this.phone === '') {
      throw new Error('手机号不能为空');
    }
    if (this.password === '') {
      throw new Error('密码不能为空');
    }
    if (!this.agreed) {
      throw new Error('请先阅读并同意用户协议与隐私政策');
    }

    this.isLoading = true;
    try {
      const res = await AuthApi.login(this.phone, this.password);
      if (res.code !== CODE_OK || res.data === null) {
        throw new Error(res.message);           // 业务失败：后端给了 message
      }
      await this.afterAuth(res.data, false);
    } catch (err) {
      throw this.toDisplayError(err);
    } finally {
      this.isLoading = false;
    }
  }

  // 注册。成功后响应与登录一致（data 是 token），后续处理完全复用 afterAuth
  private async register(): Promise<void> {
    if (this.phone === '') {
      throw new Error('手机号不能为空');
    }
    if (!isValidPhone(this.phone)) {
      throw new Error('手机号格式不正确');
    }
    if (this.code === '') {
      throw new Error('验证码不能为空');
    }
    if (this.code.length !== 6) {
      throw new Error('验证码为 6 位数字');
    }
    if (this.password === '') {
      throw new Error('密码不能为空');
    }
    if (this.password.length < 6) {
      throw new Error('密码长度不能少于 6 位');
    }
    if (!this.agreed) {
      throw new Error('请先阅读并同意用户协议与隐私政策');
    }

    this.isLoading = true;
    try {
      const res = await AuthApi.register(this.phone, this.code, this.password);
      if (res.code !== CODE_OK || res.data === null) {
        throw new Error(res.message);
      }
      await this.afterAuth(res.data, true);
    } catch (err) {
      throw this.toDisplayError(err);
    } finally {
      this.isLoading = false;
    }
  }

  // 登录/注册成功后的共同收尾：存 token → 绑定当前账号 → 换号清缓存 → 判断是否走引导页。
  // 新注册账号的完成标记一定不存在，所以自然会进 OnboardingPage，不需要额外特判。
  private async afterAuth(token: string, isRegister: boolean): Promise<void> {
    await TokenStore.save(token);

    const accountKey: string = TokenIdentity.accountKey(token, this.phone);
    const previous: string = await OnboardingCache.setCurrentUser(accountKey);
    if (previous !== '' && previous !== accountKey) {
      // 换账号：上一个人的目标级别、考试日期、昵称不能留给下一个人
      await GoalCache.clear();
      await ExamDateCache.clear();
      await ProfileCache.clear();
    }
    if (previous === '' && !isRegister) {
      // 旧版本升级后的第一次登录：把设备级 done 迁到当前账号，老用户不重弹引导
      await OnboardingCache.migrateLegacyDone();
    }
    if (isRegister) {
      // 与后端注册默认昵称保持一致：学员 + 手机号后 4 位
      const tail: string = this.phone.length >= 4
        ? this.phone.substring(this.phone.length - 4)
        : this.phone;
      await ProfileCache.saveNickname('学员' + tail);
    }

    this.needOnboarding = !(await OnboardingCache.isDone());
  }

  // 统一错误文案：网络层异常（超时/连不上/body 不是 JSON）带 code；业务错误没有
  private toDisplayError(err: Object): Error {
    const be: BusinessError = err as BusinessError;
    if (be.code !== undefined) {
      return new Error(`网络异常(${be.code})，请检查网络或服务器`);
    }
    return err as Error;
  }

  private startCountdown(): void {
    this.clearCountdown();
    this.countdown = COUNTDOWN_SECONDS;
    this.timerId = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0) {
        this.clearCountdown();
      }
    }, 1000);
  }

  private clearCountdown(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.countdown = 0;
  }

  // 页面 aboutToDisappear 调，防止定时器在页面销毁后继续跑
  dispose(): void {
    this.clearCountdown();
  }
}
