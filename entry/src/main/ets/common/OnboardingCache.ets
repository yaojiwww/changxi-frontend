import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AccountScope } from './AccountScope';

// 新用户引导（设置备考目标）完成标记：写 preferences，重启后仍生效。
//
// ★ 完成标记按账号存：key 是 done_<账号键>，不再是一台设备一个布尔值。
//   之前只有一个全局 done，任何账号点过「开始备考/跳过」后，新注册的账号
//   也会被直接放进首页，引导页永远看不到——这就是「写了配置页却用不上」的根因。
//
// 当前账号键统一由 AccountScope 保存（四个业务 Store 也要用），这里不再自己存一份。
// 登录流程会先调 setCurrentUser 再问 isDone，所以无参方法始终作用于当前账号。
const STORE_NAME: string = 'changxi_onboarding';
const KEY_DONE: string = 'done';                 // 旧版本的设备级标记，只用于升级迁移
const KEY_LEGACY_CURRENT_USER: string = 'currentUser';  // 旧版本账号键，仅用于迁移到 AccountScope

export class OnboardingCache {
  private static store: preferences.Preferences | undefined = undefined;

  // 打开存储并读回当前账号。幂等，可多页调用
  static async init(context: common.Context): Promise<void> {
    await AccountScope.init(context);
    if (OnboardingCache.store === undefined) {
      OnboardingCache.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    // 旧版本把账号键存在这里，升级后搬到 AccountScope，避免老用户被当成未绑定账号
    if (AccountScope.current() === '') {
      const legacyUser = await OnboardingCache.store.get(KEY_LEGACY_CURRENT_USER, '') as string;
      if (legacyUser !== '') {
        await AccountScope.set(legacyUser);
        // 迁移后删除旧 key，否则注销账号清空 AccountScope 后，下次启动又会被它复活
        await OnboardingCache.store.delete(KEY_LEGACY_CURRENT_USER);
        await OnboardingCache.store.flush();
      }
    }
  }

  // 登录/注册成功后调用：把当前账号切到 accountKey。
  // 返回上一个账号键（首次绑定/旧版本升级时为空串），调用方据此判断是否换号。
  static async setCurrentUser(accountKey: string): Promise<string> {
    return await AccountScope.set(accountKey);
  }

  // 当前账号是否已完成引导
  static async isDone(): Promise<boolean> {
    const store = OnboardingCache.store;
    if (store === undefined) {
      return false;
    }
    const user: string = AccountScope.current();
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
    const user: string = AccountScope.current();
    const key: string = user === '' ? KEY_DONE : OnboardingCache.doneKey(user);
    await store.put(key, true);
    await store.flush();
  }

  // 旧版本升级迁移：老用户第一次登录时，把设备级 done 复制到当前账号名下，
  // 避免升级后所有老用户被重新弹一次引导页。新注册账号不会调用它。
  static async migrateLegacyDone(): Promise<void> {
    const store = OnboardingCache.store;
    const user: string = AccountScope.current();
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

  // 注销账号时删除该账号的引导完成标记
  static async clearAccount(accountKey: string): Promise<void> {
    const store = OnboardingCache.store;
    if (store === undefined || accountKey === '') {
      return;
    }
    await store.delete(OnboardingCache.doneKey(accountKey));
    await store.flush();
  }

  private static doneKey(accountKey: string): string {
    return 'done_' + accountKey;
  }
}
