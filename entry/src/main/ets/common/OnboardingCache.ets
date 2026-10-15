import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 新用户引导（设置备考目标）完成标记：写 preferences，重启后仍生效。
// 首次登录 isDone() 为 false → 进引导页；点「开始备考」或「跳过」后置 true → 之后登录直接进首页
const STORE_NAME: string = 'changxi_onboarding';
const KEY_DONE: string = 'done';

export class OnboardingCache {
  private static store: preferences.Preferences | undefined = undefined;

  // 打开存储。幂等，可多页调用
  static async init(context: common.Context): Promise<void> {
    if (OnboardingCache.store === undefined) {
      OnboardingCache.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
  }

  // 是否已完成引导
  static async isDone(): Promise<boolean> {
    const store = OnboardingCache.store;
    if (store === undefined) {
      return false;
    }
    return await store.get(KEY_DONE, false) as boolean;
  }

  // 标记引导完成（开始备考 / 跳过都算）
  static async markDone(): Promise<void> {
    const store = OnboardingCache.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_DONE, true);
    await store.flush();
  }
}
