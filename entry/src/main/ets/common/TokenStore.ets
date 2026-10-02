import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'changxi_user';
const KEY_TOKEN: string = 'token';

// 登录令牌的本地存储：写到磁盘，App 重启后仍能读到
export class TokenStore {
  private static store: preferences.Preferences | undefined = undefined;

  // 打开存储。重复调用不会重复打开
  static async init(context: common.Context): Promise<void> {
    if (TokenStore.store === undefined) {
      TokenStore.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
  }

  // 登录成功后保存 token
  static async save(token: string): Promise<void> {
    const store = TokenStore.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_TOKEN, token);
    await store.flush();     // 不 flush 只写在内存里，重启就没了
  }

  // 取 token。没有则返回空串
  static async read(): Promise<string> {
    const store = TokenStore.store;
    if (store === undefined) {
      return '';
    }
    return await store.get(KEY_TOKEN, '') as string;
  }

  // 退出登录时清掉
  static async clear(): Promise<void> {
    const store = TokenStore.store;
    if (store === undefined) {
      return;
    }
    await store.delete(KEY_TOKEN);
    await store.flush();
  }
}
