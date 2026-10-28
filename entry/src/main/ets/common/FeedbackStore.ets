// 意见反馈本地存储：问卷提交后先存在本机（按账号隔离）
// 说明：后端暂无反馈接口，所以这里先把答卷落盘，方便后续「拉取/上报」接入；
// 届时只需把 add() 改成 POST 调用（或保留本地副本 + 上报），页面无需改动。
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AccountScope } from './AccountScope';
import { ScopedPrefs } from './ScopedPrefs';

const STORE_NAME: string = 'changxi_feedback';
const KEY_ITEMS: string = 'submissions';

// 一份答卷：answers 为 5 题的答案（前 4 题为选项文案，第 5 题为开放建议文本，可为空）
export interface FeedbackSubmission {
  answers: string[];
  submittedAt: number;   // 提交时间戳（毫秒），按时间倒序展示
}

export class FeedbackStore {
  private static store: preferences.Preferences | undefined = undefined;
  private static items: FeedbackSubmission[] = [];
  // 已加载数据的账号键：换号后 key 变了要重新读盘（SessionService 只管另外四个 Store，这里自管）
  private static tag: string = '';
  private static loaded: boolean = false;

  static async init(context: common.Context): Promise<void> {
    await AccountScope.init(context);
    if (FeedbackStore.store === undefined) {
      FeedbackStore.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    const accountKey: string = AccountScope.current();
    if (!FeedbackStore.loaded || accountKey !== FeedbackStore.tag) {
      FeedbackStore.items = FeedbackStore.parse(await ScopedPrefs.read(FeedbackStore.store, KEY_ITEMS));
      FeedbackStore.loaded = true;
      FeedbackStore.tag = accountKey;
    }
  }

  // 解析失败一律退回空列表，避免一条脏数据把整个页面打崩
  private static parse(raw: string): FeedbackSubmission[] {
    if (raw === '') {
      return [];
    }
    try {
      const parsed: FeedbackSubmission[] = JSON.parse(raw) as FeedbackSubmission[];
      return Array.isArray(parsed) ? parsed : [];
    } catch (e) {
      return [];
    }
  }

  // 持久化。任何新增后都必须调用
  private static async flush(): Promise<void> {
    const store = FeedbackStore.store;
    if (store === undefined) {
      return;
    }
    await ScopedPrefs.write(store, KEY_ITEMS, JSON.stringify(FeedbackStore.items));
  }

  // 全部答卷（新→旧）
  static getAll(): FeedbackSubmission[] {
    return FeedbackStore.items.slice().sort((a: FeedbackSubmission, b: FeedbackSubmission): number =>
      b.submittedAt - a.submittedAt);
  }

  // 最新一份答卷（没有则 undefined），页面回显「已提交」状态用
  static latest(): FeedbackSubmission | undefined {
    const all = FeedbackStore.getAll();
    return all.length > 0 ? all[0] : undefined;
  }

  // 追加一份答卷并落盘
  static async add(answers: string[]): Promise<void> {
    FeedbackStore.items.push({ answers: answers, submittedAt: Date.now() });
    await FeedbackStore.flush();
  }
}
