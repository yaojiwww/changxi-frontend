// 收藏本地存储：mock 阶段充当「数据库」，联调后由 FavoritesApi 直连后端
// 与错题本完全独立，互不影响（一道题可同时存在于收藏与错题本）
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AccountScope } from './AccountScope';
import { ScopedPrefs } from './ScopedPrefs';

const STORE_NAME: string = 'changxi_favorites';
const KEY_ITEMS: string = 'items';

// 收藏的题目快照
export interface FavoriteItem {
  questionId: string;
  stem: string;
  options: string[];
  answer: number;          // 正确选项下标 0-3
  knowledgePoint: string;  // 知识点分类
  source: string;          // 来源：practice / daily
  favoritedAt: number;     // 收藏时间戳（毫秒），用于今日/近一周筛选
}

// 知识点分类 + 数量（列表页分类头行）
export interface FavoriteCategory {
  category: string;
  count: number;
  items: FavoriteItem[];
}

// 收藏列表查询结果
export interface FavoriteListResult {
  categories: FavoriteCategory[];
  total: number;
}

// 时间范围：all 全部 / today 今日 / week 近一周
export function timeRangeHit(at: number, timeRange: string): boolean {
  const now = Date.now();
  if (timeRange === 'today') {
    const d: Date = new Date();
    d.setHours(0, 0, 0, 0);
    return at >= d.getTime();
  }
  if (timeRange === 'week') {
    return at >= now - 7 * 24 * 3600 * 1000;
  }
  return true;
}

export class FavoritesStore {
  private static store: preferences.Preferences | undefined = undefined;
  private static items: FavoriteItem[] = [];
  private static loaded: boolean = false;

  static async init(context: common.Context): Promise<void> {
    await AccountScope.init(context);
    if (FavoritesStore.store === undefined) {
      FavoritesStore.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    if (!FavoritesStore.loaded) {
      const raw: string = await ScopedPrefs.read(FavoritesStore.store, KEY_ITEMS);
      try {
        const parsed: FavoriteItem[] = raw === '' ? [] : JSON.parse(raw) as FavoriteItem[];
        FavoritesStore.items = parsed;
      } catch (e) {
        FavoritesStore.items = [];
      }
      FavoritesStore.loaded = true;
    }
  }

  // 持久化。任何增删后都必须调用
  private static async flush(): Promise<void> {
    const store = FavoritesStore.store;
    if (store === undefined) {
      return;
    }
    await ScopedPrefs.write(store, KEY_ITEMS, JSON.stringify(FavoritesStore.items));
  }

  // 换号/退出登录时清掉内存，下次 init 会重新读当前账号的数据
  static reset(): void {
    FavoritesStore.items = [];
    FavoritesStore.loaded = false;
  }

  // 删除指定账号的收藏（换号/注销时用），不影响当前内存
  static async clearAccount(accountKey: string): Promise<void> {
    const store = FavoritesStore.store;
    if (store === undefined) {
      return;
    }
    await ScopedPrefs.clearAccount(store, accountKey, [KEY_ITEMS]);
  }

  static isFavorited(questionId: string): boolean {
    for (let i = 0; i < FavoritesStore.items.length; i++) {
      if (FavoritesStore.items[i].questionId === questionId) {
        return true;
      }
    }
    return false;
  }

  // 加入收藏。已存在则不重复添加
  static async add(item: FavoriteItem): Promise<void> {
    if (FavoritesStore.isFavorited(item.questionId)) {
      return;
    }
    FavoritesStore.items.push(item);
    await FavoritesStore.flush();
  }

  // 取消收藏：立即从列表与存储中移除
  static async remove(questionId: string): Promise<void> {
    const next: FavoriteItem[] = [];
    for (let i = 0; i < FavoritesStore.items.length; i++) {
      if (FavoritesStore.items[i].questionId !== questionId) {
        next.push(FavoritesStore.items[i]);
      }
    }
    FavoritesStore.items = next;
    await FavoritesStore.flush();
  }

  // 按时间范围过滤 + 按知识点分类分组。category 非空时只取该分类
  static query(timeRange: string, category: string): FavoriteListResult {
    const categories: FavoriteCategory[] = [];
    const index: Map<string, FavoriteCategory> = new Map<string, FavoriteCategory>();
    let total = 0;

    for (let i = 0; i < FavoritesStore.items.length; i++) {
      const it: FavoriteItem = FavoritesStore.items[i];
      if (!timeRangeHit(it.favoritedAt, timeRange)) {
        continue;
      }
      if (category !== '' && category !== '不限' && it.knowledgePoint !== category) {
        continue;
      }
      total++;
      let cat: FavoriteCategory | undefined = index.get(it.knowledgePoint);
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

  // 取某分类下全部收藏题（重练页用）
  static categoryItems(timeRange: string, category: string): FavoriteItem[] {
    const res: FavoriteListResult = FavoritesStore.query(timeRange, category);
    const out: FavoriteItem[] = [];
    for (let i = 0; i < res.categories.length; i++) {
      const arr: FavoriteItem[] = res.categories[i].items;
      for (let j = 0; j < arr.length; j++) {
        out.push(arr[j]);
      }
    }
    return out;
  }
}
