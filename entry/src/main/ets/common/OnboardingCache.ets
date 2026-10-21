import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 新用户引导（设置备考目标）完成标记：写 preferences，重启后仍生效。
//
// ★ 完成标记按账号存：key 是 done_<账号键>，不再是一台设备一个布尔值。
//   之前只有一个全局 done，任何账号点过「开始备考/跳过」后，新注册的账号
//   也会被直接放进首页，引导页永远看不到——这就是「写了配置页却用不上」的根因。
//
// 账号键由 TokenIdentity 从登录 token 里取（id_<userId>），登录流程会先调
// setCurrentUser 再问 isDone，所以这里的无参方法始终作用于当前账号。
const STORE_NAME: string = 'changxi_onboarding';
const KEY_DONE: string = 'done';                 // 旧版本的设备级标记，只用于升级迁移
const KEY_CURRENT_USER: string = 'currentUser';  // 当前账号键，退出登录后保留

export class OnboardingCache {
  private static store: preferences.Preferences | undefined = undefined;
  private static currentUser: string = '';

  // 打开存储并读回当前账号。幂等，可多页调用
  static async init(context: common.Context): Promise<void> {
    if (OnboardingCache.store === undefined) {
      OnboardingCache.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    if (OnboardingCache.currentUser === '') {
      OnboardingCache.currentUser = await OnboardingCache.store.get(KEY_CURRENT_USER, '') as string;
    }
  }

  // 登录/注册成功后调用：把当前账号切到 accountKey。
  // 返回上一个账号键（首次绑定/旧版本升级时为空串），调用方据此判断是否换号。
  static async setCurrentUser(accountKey: string): Promise<string> {
    const previous: string = OnboardingCache.currentUser;
    OnboardingCache.currentUser = accountKey;
    const store = OnboardingCache.store;
    if (store !== undefined) {
      await store.put(KEY_CURRENT_USER, accountKey);
      await store.flush();
    }
    return previous;
  }

  // 当前账号是否已完成引导
  static async isDone(): Promise<boolean> {
    const store = OnboardingCache.store;
    if (store === undefined) {
      return false;
    }
    const user: string = OnboardingCache.currentUser;
    if (user === '') {
      return await store.get(KEY_DONE, false) as boolean;   // 还没绑定账号时退回旧逻辑
    }
    return await store.get(OnboardingCache.doneKey(user), false) as boolean;
  }

  // 标记当前账号引导完成（开始备考 / 跳过都算）
  static async markDone(): Promise<void> {
    const store = OnboardingCache.store;
    if (store === undefined) {
      return;
    }
    const user: string = OnboardingCache.currentUser;
    const key: string = user === '' ? KEY_DONE : OnboardingCache.doneKey(user);
    await store.put(key, true);
    await store.flush();
  }

  // 旧版本升级迁移：老用户第一次登录时，把设备级 done 复制到当前账号名下，
  // 避免升级后所有老用户被重新弹一次引导页。新注册账号不会调用它。
  static async migrateLegacyDone(): Promise<void> {
    const store = OnboardingCache.store;
    const user: string = OnboardingCache.currentUser;
    if (store === undefined || user === '') {
      return;
    }
    const legacy: boolean = await store.get(KEY_DONE, false) as boolean;
    if (!legacy) {
      return;
    }
    await store.put(OnboardingCache.doneKey(user), true);
    await store.flush();
  }

  private static doneKey(accountKey: string): string {
    return 'done_' + accountKey;
  }
}
