import { preferences } from '@kit.ArkData';
import { AccountScope } from './AccountScope';

// =============================================================================
// 按账号隔离的 preferences 读写
//
// 四个业务 Store（收藏/错题/学习记录/考试）结构一样：
// 一个 JSON 字符串存在一个 key 里。这里把「拼账号前缀 + 旧数据迁移 + 删账号」收在一处，
// 避免每个 Store 各写一遍，也避免以后加 Store 时又漏掉隔离。
//
// 旧版本数据迁移：升级后第一次以某个账号读写时，如果账号 key 不存在、
// 设备级 key 有值，就把旧值复制到账号下并删除设备级 key。只发生一次。
// =============================================================================
export class ScopedPrefs {
  // 读当前账号下的字符串值；没有则返回 ''
  static async read(store: preferences.Preferences, baseKey: string): Promise<string> {
    const key: string = AccountScope.scopedKey(baseKey);
    // 用 has 而不是「值为空」判断：考试进度清空后会显式写 ''，
    // 不能把它当成「没有数据」再去接手旧版本数据。
    if (await store.has(key)) {
      return await store.get(key, '') as string;
    }
    if (AccountScope.current() === '') {
      return '';
    }

    // 当前账号还没有数据：尝试接手旧版本的设备级数据
    if (!await store.has(baseKey)) {
      return '';
    }
    const legacy = await store.get(baseKey, '') as string;
    await store.put(key, legacy);
    await store.flush();
    await store.delete(baseKey);
    await store.flush();
    return legacy;
  }

  // 写当前账号下的字符串值
  static async write(store: preferences.Preferences, baseKey: string, value: string): Promise<void> {
    await store.put(AccountScope.scopedKey(baseKey), value);
    await store.flush();
  }

  // 删除指定账号的这些 key（换号/注销时用）。accountKey 为空时不做事
  static async clearAccount(store: preferences.Preferences, accountKey: string,
    baseKeys: string[]): Promise<void> {
    if (accountKey === '') {
      return;
    }
    for (let i = 0; i < baseKeys.length; i++) {
      await store.delete(`${accountKey}:${baseKeys[i]}`);
    }
    await store.flush();
  }
}
