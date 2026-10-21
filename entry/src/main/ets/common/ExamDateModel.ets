import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

import { AppStorageV2 } from '@kit.ArkUI';

// 考试目标日期跨页共享模型：@Trace 字段变更会驱动首页倒计时与设置页回显同步刷新
@ObservedV2
export class ExamDateModel {
  @Trace dateStr: string = '';   // YYYY-MM-DD，空串表示未设置
}

// 解析 YYYY-MM-DD 为本地时间 0 点的 Date。格式非法时返回当前时间
export function parseExamDate(dateStr: string): Date {
  const parts: string[] = dateStr.split('-');
  if (parts.length !== 3) {
    return new Date();
  }
  const y: number = Number.parseInt(parts[0], 10);
  const m: number = Number.parseInt(parts[1], 10) - 1;
  const d: number = Number.parseInt(parts[2], 10);
  return new Date(y, m, d);
}

// 中文格式显示：2026年10月13日
export function formatExamDateCN(dateStr: string): string {
  const parts: string[] = dateStr.split('-');
  if (parts.length !== 3) {
    return '未设置';
  }
  return parts[0] + '年' + Number.parseInt(parts[1], 10).toString()
    + '月' + Number.parseInt(parts[2], 10).toString() + '日';
}

// 距考试天数：今天为 0，已过为负数，未设置为 0
export function daysUntil(dateStr: string): number {
  if (dateStr === '') {
    return 0;
  }
  const target: Date = parseExamDate(dateStr);
  const now: Date = new Date();
  const todayStart: number = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const targetStart: number = new Date(target.getFullYear(), target.getMonth(), target.getDate()).getTime();
  return Math.round((targetStart - todayStart) / 86400000);
}

const STORE_NAME: string = 'changxi_exam_date';
const KEY_DATE: string = 'dateStr';

// 考试日期本地缓存：写 preferences，重启后仍能回显
export class ExamDateCache {
  private static store: preferences.Preferences | undefined = undefined;

  // 只打开存储，不读值。登录流程换号清数据时用
  static async init(context: common.Context): Promise<void> {
    if (ExamDateCache.store === undefined) {
      ExamDateCache.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
  }

  // 打开存储并把缓存写回共享模型。幂等，可多页调用
  static async load(context: common.Context): Promise<void> {
    await ExamDateCache.init(context);
    const store = ExamDateCache.store;
    if (store === undefined) {
      return;
    }
    const model = AppStorageV2.connect(ExamDateModel, () => new ExamDateModel())!;
    const saved = await store.get(KEY_DATE, '') as string;
    model.dateStr = saved;
  }

  // 选择器确认后落库，并同步共享模型。失败不碰缓存
  static async saveDate(dateStr: string): Promise<void> {
    const model = AppStorageV2.connect(ExamDateModel, () => new ExamDateModel())!;
    model.dateStr = dateStr;
    const store = ExamDateCache.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_DATE, dateStr);
    await store.flush();
  }

  // 换账号时清空：缓存和共享模型一起回到未设置
  static async clear(): Promise<void> {
    const model = AppStorageV2.connect(ExamDateModel, () => new ExamDateModel())!;
    model.dateStr = '';
    const store = ExamDateCache.store;
    if (store === undefined) {
      return;
    }
    await store.delete(KEY_DATE);
    await store.flush();
  }
}
