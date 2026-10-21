import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// =============================================================================
// 当前账号的作用域
//
// 本地缓存（收藏/错题/学习记录/考试进度）都必须是「每个账号一份」，
// 否则同一台设备换号后会把上一个人的数据带过去。
//
// 账号键由 TokenIdentity 从登录 token 的 sub 取（id_<userId>），
// 取不到时退回 phone_<手机号>。这里只负责保存/读取这个键，
// 并把它拼进 preferences 的 key 前缀：id_12:items。
//
// 为什么单独一个类：OnboardingCache 和四个业务 Store 都要用，
// 如果放在 OnboardingCache 里，业务 Store 就要反向依赖引导逻辑。
// =============================================================================
const STORE_NAME: string = 'changxi_account';
const KEY_CURRENT: string = 'currentAccount';

export class AccountScope {
  private static store: preferences.Preferences | undefined = undefined;
  private static currentKey: string = '';

  // 打开存储并读回上次登录的账号键。幂等，可多模块调用
  static async init(context: common.Context): Promise<void> {
    if (AccountScope.store === undefined) {
      AccountScope.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    if (AccountScope.currentKey === '') {
      AccountScope.currentKey = await AccountScope.store.get(KEY_CURRENT, '') as string;
    }
  }

  // 当前账号键。未登录/旧版本升级前可能为空串
  static current(): string {
    return AccountScope.currentKey;
  }

  static isSignedIn(): boolean {
    return AccountScope.currentKey !== '';
  }

  // 把基础 key 拼成当前账号的 key。没有账号时退回设备级 key，
  // 兼容旧版本数据，也保证登录页等未绑定账号的场景仍能读写。
  static scopedKey(baseKey: string): string {
    const account: string = AccountScope.currentKey;
    if (account === '') {
      return baseKey;
    }
    return `${account}:${baseKey}`;
  }

  // 登录/注册成功后切到 accountKey，返回上一个账号键。
  // 返回空串表示首次绑定（旧版本升级或全新安装）。
  static async set(accountKey: string): Promise<string> {
    const previous: string = AccountScope.currentKey;
    AccountScope.currentKey = accountKey;
    const store = AccountScope.store;
    if (store !== undefined) {
      await store.put(KEY_CURRENT, accountKey);
      await store.flush();
    }
    return previous;
  }

  // 注销账号后解除绑定，下次登录按首次绑定处理
  static async clear(): Promise<void> {
    AccountScope.currentKey = '';
    const store = AccountScope.store;
    if (store !== undefined) {
      await store.delete(KEY_CURRENT);
      await store.flush();
    }
  }
}
