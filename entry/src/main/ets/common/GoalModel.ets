import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

import { AppStorageV2 } from '@kit.ArkUI';

// 当前目标级别：0 初级 / 1 中级 / 2 高级（全局唯一真源）
export const LEVEL_BEGINNER: number = 0;
export const LEVEL_INTERMEDIATE: number = 1;
export const LEVEL_ADVANCED: number = 2;

// 目标级别短名：初级 / 中级 / 高级
export function levelShortName(levelIndex: number): string {
  if (levelIndex === LEVEL_BEGINNER) {
    return '初级';
  }
  if (levelIndex === LEVEL_ADVANCED) {
    return '高级';
  }
  return '中级';
}

// 目标级别全名：初级保育员 / 中级保育员 / 高级保育员
export function levelFullName(levelIndex: number): string {
  return levelShortName(levelIndex) + '保育员';
}

// 目标级别跨页共享模型：@Trace 字段变更会驱动所有引用页面刷新
@ObservedV2
export class GoalModel {
  @Trace levelIndex: number = LEVEL_BEGINNER;   // 默认初级（新用户跳过引导时即从初级开始）
}

const STORE_NAME: string = 'changxi_goal';
const KEY_LEVEL: string = 'levelIndex';

// 目标级别本地缓存：写 preferences，重启后仍能回显。缓存为空则回退默认中级
export class GoalCache {
  private static store: preferences.Preferences | undefined = undefined;

  // 打开存储并把缓存写回共享模型。幂等，可多页调用
  static async load(context: common.Context): Promise<void> {
    if (GoalCache.store === undefined) {
      GoalCache.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    const model = AppStorageV2.connect(GoalModel, () => new GoalModel())!;
    // 缓存为空时按初级兜底（新用户跳过引导即从初级开始）
    const level = await GoalCache.store.get(KEY_LEVEL, LEVEL_BEGINNER) as number;
    if (level >= LEVEL_BEGINNER && level <= LEVEL_ADVANCED) {
      model.levelIndex = level;
    }
  }

  // 切换目标成功后落库，并同步共享模型。失败不碰缓存
  static async saveLevel(levelIndex: number): Promise<void> {
    const model = AppStorageV2.connect(GoalModel, () => new GoalModel())!;
    model.levelIndex = levelIndex;
    const store = GoalCache.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_LEVEL, levelIndex);
    await store.flush();
  }
}
