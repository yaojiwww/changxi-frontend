// AI实操历史本地存储：每完成一次分析自动归档一条（按账号隔离）
// 说明：后端暂无实操历史接口，先落盘；接后端时只需改本文件，页面不用动。
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AccountScope } from './AccountScope';
import { ScopedPrefs } from './ScopedPrefs';

const STORE_NAME: string = 'changxi_ai_practice';
const KEY_ITEMS: string = 'history';

// 一条实操分析记录
export interface AIPracticeRecord {
  sceneIndex: number;   // 场景下标，回看结果时按此还原
  sceneName: string;    // 场景名快照（场景常量调整后仍能显示当时的名字）
  imageUri: string;     // 当时用的照片 URI；示例照片为空串
  useDemo: boolean;     // true = 用的内置示例照片（缩略图用 demo_scene 兜底）
  score: number;        // 达标度快照（列表徽标）
  date: string;         // 时间 YYYY-MM-DD HH:mm:ss（与学习记录同一格式）
  timestamp: number;    // 时间戳，用于倒序
}

export class AIPracticeHistoryStore {
  private static store: preferences.Preferences | undefined = undefined;
  private static items: AIPracticeRecord[] = [];
  // 已加载数据的账号键：换号后 key 变了要重新读盘（SessionService 只管另外四个 Store，这里自管）
  private static tag: string = '';
  private static loaded: boolean = false;

  static async init(context: common.Context): Promise<void> {
    await AccountScope.init(context);
    if (AIPracticeHistoryStore.store === undefined) {
      AIPracticeHistoryStore.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    const accountKey: string = AccountScope.current();
    if (!AIPracticeHistoryStore.loaded || accountKey !== AIPracticeHistoryStore.tag) {
      const raw: string = await ScopedPrefs.read(AIPracticeHistoryStore.store, KEY_ITEMS);
      AIPracticeHistoryStore.items = AIPracticeHistoryStore.parse(raw);
      AIPracticeHistoryStore.loaded = true;
      AIPracticeHistoryStore.tag = accountKey;
    }
  }

  // 解析失败一律退回空列表，避免一条脏数据把整个浮窗打崩
  private static parse(raw: string): AIPracticeRecord[] {
    if (raw === '') {
      return [];
    }
    try {
      const parsed: AIPracticeRecord[] = JSON.parse(raw) as AIPracticeRecord[];
      return Array.isArray(parsed) ? parsed : [];
    } catch (e) {
      return [];
    }
  }

  // 持久化。任何新增后都必须调用
  private static async flush(): Promise<void> {
    const store = AIPracticeHistoryStore.store;
    if (store === undefined) {
      return;
    }
    await ScopedPrefs.write(store, KEY_ITEMS, JSON.stringify(AIPracticeHistoryStore.items));
  }

  // 全部记录（新→旧）
  static getAll(): AIPracticeRecord[] {
    return AIPracticeHistoryStore.items.slice()
      .sort((a: AIPracticeRecord, b: AIPracticeRecord): number => b.timestamp - a.timestamp);
  }

  // 追加一条（页面在「分析完成」时调用），时间戳与日期字符串在此生成
  static async add(sceneIndex: number, sceneName: string, imageUri: string,
    useDemo: boolean, score: number): Promise<void> {
    const now: number = Date.now();
    AIPracticeHistoryStore.items.push({
      sceneIndex: sceneIndex,
      sceneName: sceneName,
      imageUri: imageUri,
      useDemo: useDemo,
      score: score,
      date: AIPracticeHistoryStore.formatDateTime(now),
      timestamp: now
    });
    await AIPracticeHistoryStore.flush();
  }

  private static pad2(n: number): string {
    return n < 10 ? '0' + n : '' + n;
  }

  private static formatDateTime(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getFullYear()}-${AIPracticeHistoryStore.pad2(d.getMonth() + 1)}` +
      `-${AIPracticeHistoryStore.pad2(d.getDate())}` +
      ` ${AIPracticeHistoryStore.pad2(d.getHours())}:${AIPracticeHistoryStore.pad2(d.getMinutes())}` +
      `:${AIPracticeHistoryStore.pad2(d.getSeconds())}`;
  }
}
