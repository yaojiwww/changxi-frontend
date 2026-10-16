import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { AppConfig } from '../common/AppConfig';
import { TokenStore } from '../common/TokenStore';
import { OnboardingCache } from '../common/OnboardingCache';
import { AuthApi } from '../api/AuthApi';
import { CODE_OK } from '../common/Http';

// 登录页 ViewModel：持有全部登录态与取数逻辑，不碰 UI。
// 失败一律 throw Error，由页面 catch 后 toast。
@ObservedV2
export class LoginViewModel {
  @Trace phone: string = '';
  @Trace password: string = '';
  @Trace agreed: boolean = false;
  @Trace isLoading: boolean = false;

  // 登录成功后才有意义：true 表示要走引导页
  @Trace needOnboarding: boolean = false;

  // 页面 aboutToAppear 调一次，把配置与本地存储准备好
  async init(context: common.Context): Promise<void> {
    await AppConfig.load(context);
    await TokenStore.init(context);
    await OnboardingCache.init(context);
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
      await TokenStore.save(res.data);
      this.needOnboarding = !(await OnboardingCache.isDone());
    } catch (err) {
      // 网络层异常（超时 / 连不上 / body 不是 JSON）带 code；业务错误没有
      const be = err as BusinessError;
      if (be.code !== undefined) {
        throw new Error(`网络异常(${be.code})，请检查网络或服务器`);
      }
      throw err as Error;
    } finally {
      this.isLoading = false;
    }
  }
}
