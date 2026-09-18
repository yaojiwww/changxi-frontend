import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 本地登录态存储。
 *
 * 重要：init() 必须在 App 启动时调用一次（见 EntryAbility.onCreate），
 * 否则 pref 一直是 null，getToken() 永远返回 null、setToken() 静默失败，
 * 整条登录链路会无声地断掉 —— 这是重构前真实存在的问题。
 */
export class TokenManager {
  private static pref: dataPreferences.Preferences | null = null;
  private static isInitialized: boolean = false;

  static async init(context: Context): Promise<void> {
    if (TokenManager.isInitialized) {
      return;
    }
    try {
      TokenManager.pref = await dataPreferences.getPreferences(context, 'user_prefs');
      TokenManager.isInitialized = true;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`[TokenManager] 初始化失败: ${err.message}`);
    }
  }

  /** 没初始化时大声报错，避免又变成静默失败 */
  private static assertReady(): boolean {
    if (!TokenManager.pref) {
      console.error('[TokenManager] 尚未初始化！请确认 EntryAbility.onCreate 里调用了 TokenManager.init(this.context)');
      return false;
    }
    return true;
  }

  /** 未登录返回 null（空字符串也视为未登录） */
  static async getToken(): Promise<string | null> {
    if (!TokenManager.assertReady()) {
      return null;
    }
    const value: dataPreferences.ValueType = await TokenManager.pref!.get('token', '');
    const token = value as string;
    return token.length > 0 ? token : null;
  }

  static async setToken(token: string): Promise<void> {
    if (!TokenManager.assertReady()) {
      return;
    }
    await TokenManager.pref!.put('token', token);
    await TokenManager.pref!.flush();
  }

  static async getUserId(): Promise<string | null> {
    if (!TokenManager.assertReady()) {
      return null;
    }
    const value: dataPreferences.ValueType = await TokenManager.pref!.get('userId', '');
    const userId = value as string;
    return userId.length > 0 ? userId : null;
  }

  static async setUserId(userId: string): Promise<void> {
    if (!TokenManager.assertReady()) {
      return;
    }
    await TokenManager.pref!.put('userId', userId);
    await TokenManager.pref!.flush();
  }

  /** 清空本地登录态 */
  static async clear(): Promise<void> {
    if (!TokenManager.assertReady()) {
      return;
    }
    await TokenManager.pref!.clear();
    await TokenManager.pref!.flush();
  }
}
