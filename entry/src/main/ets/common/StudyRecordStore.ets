// 学习记录统一存储：每日一练 / 知识点练习 / 模拟考试 三模块共用
// 交卷成功生成报告后，各答题页调用 add() 追加一条，学习数据页读取展示并可回看报告
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AccountScope } from './AccountScope';
import { ScopedPrefs } from './ScopedPrefs';

const STORE_NAME: string = 'changxi_study_records';
const KEY_RECORDS: string = 'records';

// 记录类型
export type StudyRecordType = 'daily' | 'exam' | 'knowledge';

// 统一学习记录对象
export interface StudyRecord {
  id: string;                              // 唯一 ID
  type: StudyRecordType;                   // 来源模块
  title: string;                           // 试卷/知识条目名称
  score: string;                           // 分数或正确率，如 '85分' 或 '80%'
  date: string;                            // 交卷时间 YYYY-MM-DD HH:mm:ss
  timestamp: number;                       // 交卷时间戳，用于倒序
  detailData: string;                      // 完整报告 JSON 字符串（PracticeReport / ExamFinished），回看时解析
}

// 类型标签文案
export function studyTypeLabel(type: StudyRecordType): string {
  if (type === 'daily') {
    return '每日一练';
  }
  if (type === 'exam') {
    return '模拟考';
  }
  return '知识点';
}

export class StudyRecordStore {
  private static store: preferences.Preferences | undefined = undefined;
  private static records: StudyRecord[] = [];
  private static loaded: boolean = false;

  static async init(context: common.Context): Promise<void> {
    await AccountScope.init(context);
    if (StudyRecordStore.store === undefined) {
      StudyRecordStore.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    if (!StudyRecordStore.loaded) {
      const raw: string = await ScopedPrefs.read(StudyRecordStore.store, KEY_RECORDS);
      try {
        StudyRecordStore.records = raw === '' ? [] : JSON.parse(raw) as StudyRecord[];
      } catch (e) {
        StudyRecordStore.records = [];
      }
      StudyRecordStore.loaded = true;
    }
  }

  // 持久化。任何增删后都必须调用
  private static async flush(): Promise<void> {
    const store = StudyRecordStore.store;
    if (store === undefined) {
      return;
    }
    await ScopedPrefs.write(store, KEY_RECORDS, JSON.stringify(StudyRecordStore.records));
  }

  // 换号/退出登录时清掉内存，下次 init 会重新读当前账号的数据
  static reset(): void {
    StudyRecordStore.records = [];
    StudyRecordStore.loaded = false;
  }

  // 删除指定账号的学习记录（换号/注销时用），不影响当前内存
  static async clearAccount(accountKey: string): Promise<void> {
    const store = StudyRecordStore.store;
    if (store === undefined) {
      return;
    }
    await ScopedPrefs.clearAccount(store, accountKey, [KEY_RECORDS]);
  }

  // 追加一条学习记录并落库
  static async add(record: StudyRecord): Promise<void> {
    StudyRecordStore.records.push(record);
    await StudyRecordStore.flush();
  }

  // 取全部记录，按时间戳倒序（最新在前）
  static getAll(): StudyRecord[] {
    return StudyRecordStore.records.slice().sort((a: StudyRecord, b: StudyRecord): number =>
      b.timestamp - a.timestamp);
  }

  // 生成唯一记录 ID：时间戳 + 随机后缀，避免同毫秒冲突
  static newId(): string {
    return `${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  }
}
