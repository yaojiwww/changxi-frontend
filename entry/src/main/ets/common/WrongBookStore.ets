// 错题本本地存储：mock 阶段充当「数据库」，联调后由 WrongApi 直连后端
// 与收藏完全独立，互不影响；三次答对消除逻辑在 WrongApi（后端侧）执行
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { timeRangeHit } from './FavoritesStore';
import { AccountScope } from './AccountScope';
import { ScopedPrefs } from './ScopedPrefs';

const STORE_NAME: string = 'changxi_wrongbook';
const KEY_ITEMS: string = 'items';

// 错题本中的题目快照 + 消除进度
export interface WrongItem {
  questionId: string;
  stem: string;
  options: string[];
  answer: number;          // 正确选项下标 0-3
  knowledgePoint: string;  // 知识点分类
  source: string;          // 来源：practice / daily
  lastWrongAt: number;     // 最近答错时间戳（毫秒）
  wrongCount: number;      // 累计答错次数
  correctCount: number;    // 重练连续答对次数 0-2，达到 3 即被消除
}

// 知识点分类 + 数量 + 题目（列表页分类头行 + 题目明细）
export interface WrongCategory {
  category: string;
  count: number;
  items: WrongItem[];
}

export interface WrongListResult {
  categories: WrongCategory[];
  total: number;
}

// 顽固错题：曾重练过但尚未消除（1-2 次）或累计答错 ≥3 次
export function isStubborn(item: WrongItem): boolean {
  return item.correctCount > 0 || item.wrongCount >= 3;
}

export class WrongBookStore {
  private static store: preferences.Preferences | undefined = undefined;
  private static items: WrongItem[] = [];
  private static loaded: boolean = false;

  static async init(context: common.Context): Promise<void> {
    await AccountScope.init(context);
    if (WrongBookStore.store === undefined) {
      WrongBookStore.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    if (!WrongBookStore.loaded) {
      const raw: string = await ScopedPrefs.read(WrongBookStore.store, KEY_ITEMS);
      try {
        const parsed: WrongItem[] = raw === '' ? [] : JSON.parse(raw) as WrongItem[];
        WrongBookStore.items = parsed;
      } catch (e) {
        WrongBookStore.items = [];
      }
      WrongBookStore.loaded = true;
    }
  }

  private static async flush(): Promise<void> {
    const store = WrongBookStore.store;
    if (store === undefined) {
      return;
    }
    await ScopedPrefs.write(store, KEY_ITEMS, JSON.stringify(WrongBookStore.items));
  }

  // 换号/退出登录时清掉内存，下次 init 会重新读当前账号的数据
  static reset(): void {
    WrongBookStore.items = [];
    WrongBookStore.loaded = false;
  }

  // 删除指定账号的错题（换号/注销时用），不影响当前内存
  static async clearAccount(accountKey: string): Promise<void> {
    const store = WrongBookStore.store;
    if (store === undefined) {
      return;
    }
    await ScopedPrefs.clearAccount(store, accountKey, [KEY_ITEMS]);
  }

  // 供 WrongApi（后端侧 mock）在直接改条目字段后落库
  static async flushPublic(): Promise<void> {
    await WrongBookStore.flush();
  }

  static get(questionId: string): WrongItem | undefined {
    for (let i = 0; i < WrongBookStore.items.length; i++) {
      if (WrongBookStore.items[i].questionId === questionId) {
        return WrongBookStore.items[i];
      }
    }
    return undefined;
  }

  // 答错时调用：新题入本，已有题刷新错次与时间；重练答错时把答对进度重置为 0
  static async markWrong(questionId: string, stem: string, options: string[],
    answer: number, knowledgePoint: string, source: string): Promise<void> {
    const found: WrongItem | undefined = WrongBookStore.get(questionId);
    const now = Date.now();
    if (found !== undefined) {
      found.lastWrongAt = now;
      found.wrongCount++;
      found.correctCount = 0;   // 三次答对机制：答错即重置
    } else {
      WrongBookStore.items.push({
        questionId: questionId,
        stem: stem,
        options: options,
        answer: answer,
        knowledgePoint: knowledgePoint,
        source: source,
        lastWrongAt: now,
        wrongCount: 1,
        correctCount: 0
      });
    }
    await WrongBookStore.flush();
  }

  // 重练答对时由 WrongApi（后端侧）调用：答对次数 +1
  static async bumpCorrect(questionId: string): Promise<WrongItem | undefined> {
    const found: WrongItem | undefined = WrongBookStore.get(questionId);
    if (found === undefined) {
      return undefined;
    }
    found.correctCount++;
    await WrongBookStore.flush();
    return found;
  }

  // 达到 3 次：从列表与存储中彻底移除（消除）
  static async eliminate(questionId: string): Promise<void> {
    await WrongBookStore.remove(questionId);
  }

  static async remove(questionId: string): Promise<void> {
    const next: WrongItem[] = [];
    for (let i = 0; i < WrongBookStore.items.length; i++) {
      if (WrongBookStore.items[i].questionId !== questionId) {
        next.push(WrongBookStore.items[i]);
      }
    }
    WrongBookStore.items = next;
    await WrongBookStore.flush();
  }

  // 按时间范围（可叠加顽固条件）+ 知识点分类分组
  static query(timeRange: string, category: string): WrongListResult {
    const categories: WrongCategory[] = [];
    const index: Map<string, WrongCategory> = new Map<string, WrongCategory>();
    let total = 0;

    for (let i = 0; i < WrongBookStore.items.length; i++) {
      const it: WrongItem = WrongBookStore.items[i];
      if (timeRange === 'stubborn') {
        if (!isStubborn(it)) {
          continue;
        }
      } else if (!timeRangeHit(it.lastWrongAt, timeRange)) {
        continue;
      }
      if (category !== '' && category !== '不限' && it.knowledgePoint !== category) {
        continue;
      }
      total++;
      let cat: WrongCategory | undefined = index.get(it.knowledgePoint);
      if (cat === undefined) {
        cat = { category: it.knowledgePoint, count: 0, items: [] };
        index.set(it.knowledgePoint, cat);
        categories.push(cat);
      }
      cat.count++;
      cat.items.push(it);
    }
    return { categories: categories, total: total };
  }

  // 取某分类下全部错题（重练页用）
  static categoryItems(timeRange: string, category: string): WrongItem[] {
    const res: WrongListResult = WrongBookStore.query(timeRange, category);
    const out: WrongItem[] = [];
    for (let i = 0; i < res.categories.length; i++) {
      const arr: WrongItem[] = res.categories[i].items;
      for (let j = 0; j < arr.length; j++) {
        out.push(arr[j]);
      }
    }
    return out;
  }
}
