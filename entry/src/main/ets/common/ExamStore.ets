// 模拟考试本地缓存：进行中考试（断点续答）+ 已考成绩记录
// Mock 阶段充当「数据库」，联调后由后端接管
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'changxi_exam';
const KEY_PROGRESS: string = 'progress';   // 进行中记录（同一时间仅一套）
const KEY_FINISHED: string = 'finished';   // 已考记录数组

// 进行中考试记录
export interface ExamProgress {
  paperId: string;
  paperTitle: string;
  answers: string[];   // 已作答，下标与题目一致，空串未答
  index: number;       // 当前题下标
  deadline: number;    // 交卷截止时间戳（进入时刻 + 90 分钟）
  startTime: number;   // 开考时间戳
}

// 已考记录：完整成绩报告快照
export interface ExamFinished {
  paperId: string;
  paperTitle: string;
  score: number;          // 总分（百分制）
  total: number;          // 总题数
  correctCount: number;   // 答对题数
  duration: number;       // 练习时长秒
  submitTime: string;     // 交卷时间 YYYY-MM-DD HH:mm:ss
  answerCard: ExamAnswerCell[];   // 每题作答与对错
  parses: ExamParseItem[];        // 答错题解析
}

// 答题卡单格
export interface ExamAnswerCell {
  questionId: string;
  correct: boolean;
  userAnswer: string;     // 选项字母，未答为 ''
  correctOption: string;  // 正确答案字母
}

// 试卷解析条目
export interface ExamParseItem {
  questionId: string;
  stem: string;
  userAnswer: string;
  correctOption: string;
  explanation: string;
}

export class ExamStore {
  private static store: preferences.Preferences | undefined = undefined;
  private static progress: ExamProgress | null = null;
  private static finished: ExamFinished[] = [];
  private static loaded: boolean = false;

  static async init(context: common.Context): Promise<void> {
    if (ExamStore.store === undefined) {
      ExamStore.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    if (!ExamStore.loaded) {
      const p = await ExamStore.store.get(KEY_PROGRESS, '') as string;
      if (p !== '') {
        try {
          ExamStore.progress = JSON.parse(p) as ExamProgress;
        } catch (e) {
          ExamStore.progress = null;
        }
      }
      const f = await ExamStore.store.get(KEY_FINISHED, '[]') as string;
      try {
        ExamStore.finished = JSON.parse(f) as ExamFinished[];
      } catch (e) {
        ExamStore.finished = [];
      }
      ExamStore.loaded = true;
    }
  }

  // ===== 进行中记录 =====

  static getProgress(): ExamProgress | null {
    return ExamStore.progress;
  }

  static async saveProgress(p: ExamProgress): Promise<void> {
    ExamStore.progress = p;
    const store = ExamStore.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_PROGRESS, JSON.stringify(p));
    await store.flush();
  }

  // 交卷后清除：悬浮栏随之消失
  static async clearProgress(): Promise<void> {
    ExamStore.progress = null;
    const store = ExamStore.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_PROGRESS, '');
    await store.flush();
  }

  // ===== 已考记录 =====

  static getFinished(paperId: string): ExamFinished | null {
    for (let i = 0; i < ExamStore.finished.length; i++) {
      if (ExamStore.finished[i].paperId === paperId) {
        return ExamStore.finished[i];
      }
    }
    return null;
  }

  // 是否已考过
  static isFinished(paperId: string): boolean {
    return ExamStore.getFinished(paperId) !== null;
  }

  // 写入/覆盖已考记录
  static async saveFinished(r: ExamFinished): Promise<void> {
    const next: ExamFinished[] = [];
    for (let i = 0; i < ExamStore.finished.length; i++) {
      if (ExamStore.finished[i].paperId !== r.paperId) {
        next.push(ExamStore.finished[i]);
      }
    }
    next.push(r);
    ExamStore.finished = next;
    const store = ExamStore.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_FINISHED, JSON.stringify(next));
    await store.flush();
  }
}
