import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 「是否已经开始学习」标记：写 preferences，重启后仍生效。
// 未开始 → 首页主按钮显示「开始学习」；已开始 → 显示「继续练习」
const STORE_NAME: string = 'changxi_study';
const KEY_STARTED: string = 'started';

export class StudyCache {
  private static store: preferences.Preferences | undefined = undefined;

  // 打开存储。幂等，可多页调用
  static async init(context: common.Context): Promise<void> {
    if (StudyCache.store === undefined) {
      StudyCache.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
  }

  // 是否已开始学习
  static async isStarted(): Promise<boolean> {
    const store = StudyCache.store;
    if (store === undefined) {
      return false;
    }
    return await store.get(KEY_STARTED, false) as boolean;
  }

  // 标记已开始学习（点「开始学习」时写入）
  static async markStarted(): Promise<void> {
    const store = StudyCache.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_STARTED, true);
    await store.flush();
  }
}
