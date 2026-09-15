import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';

export class TokenManager {
  // 定义一个静态的实例变量，用于缓存 preferences 对象
  private static pref: dataPreferences.Preferences | null = null;
  // 定义一个标志位，防止重复初始化
  private static isInitialized: boolean = false;

  /**
   * 初始化 Preferences。
   */
  static async init(context: Context): Promise<void> {
    if (TokenManager.isInitialized) return;
    try {
      TokenManager.pref = await dataPreferences.getPreferences(context, 'user_prefs');
      TokenManager.isInitialized = true;
    } catch (e) {
      let err = e as BusinessError;
      console.error('TokenManager 初始化失败: ' + err.message);
    }
  }

  /**
   * 安全地获取 Token。如果未初始化则自动返回 null，避免报错。
   */
  static async getToken(): Promise<string | null> {
    if (!TokenManager.pref) return null;
    let token: dataPreferences.ValueType = await TokenManager.pref.get('token', '');
    return token as string;
  }

  /**
   * 安全地保存 Token。
   */
  static async setToken(token: string): Promise<void> {
    if (!TokenManager.pref) return;
    await TokenManager.pref.put('token', token);
    await TokenManager.pref.flush();
  }

  /**
   * 安全地获取用户ID。
   */
  static async getUserId(): Promise<string | null> {
    if (!TokenManager.pref) return null;
    let userId: dataPreferences.ValueType = await TokenManager.pref.get('userId', '');
    return userId as string;
  }

  /**
   * 安全地保存用户ID。
   */
  static async setUserId(userId: string): Promise<void> {
    if (!TokenManager.pref) return;
    await TokenManager.pref.put('userId', userId);
    await TokenManager.pref.flush();
  }

  /**
   * 登出（清除所有本地数据）。
   */
  static async logout(): Promise<void> {
    if (!TokenManager.pref) return;
    await TokenManager.pref.clear();    // 清除所有键值对
    await TokenManager.pref.flush();
  }
}