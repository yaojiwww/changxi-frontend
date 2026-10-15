import { Http, ApiResponse } from '../common/Http';
import { WrongBookStore, WrongListResult, WrongItem } from '../common/WrongBookStore';

// 后端未就绪，先走本地 mock。联调时改 false 即可切到真接口。
// 三次答对消除逻辑在本文件（后端侧）执行，前端只读 correctCount 画进度
const USE_MOCK: boolean = true;

const MOCK_DELAY_MS: number = 300;

// 单题作答记录
export interface WrongAnswer {
  questionId: string;
  userAnswer: string;  // 选项字母 A/B/C/D
}

// 错题重练单题结果
export interface RepracticeResult {
  questionId: string;
  correctCount: number;  // 当前答对进度 0-3
  eliminated: boolean;   // 是否已达到 3 次被消除
}

interface OkData {
}

// 错题域接口。路径与 docs/api_spec.md 一一对应，改接口先改文档再改这里
export class WrongApi {
  // 错题分类及列表（含重练答对次数）。timeRange: all/today/week/stubborn
  static async list(category: string, timeRange: string, token: string): Promise<ApiResponse<WrongListResult>> {
    if (USE_MOCK) {
      return new Promise<ApiResponse<WrongListResult>>((resolve: (v: ApiResponse<WrongListResult>) => void): void => {
        resolve({ code: 0, message: 'ok', data: WrongBookStore.query(timeRange, category) });
      });
    }
    const q: string = `category=${encodeURIComponent(category)}&timeRange=${timeRange}`;
    return Http.get<WrongListResult>(`/wrong/list?${q}`, token);
  }

  // 错题重练批量提交。返回每题当前答对次数与是否已消除
  static async repractice(answers: WrongAnswer[], token: string): Promise<ApiResponse<RepracticeResult[]>> {
    if (USE_MOCK) {
      return WrongApi.mockRepractice(answers);
    }
    return Http.post<RepracticeResult[]>('/wrong/repractice', answers, token);
  }

  // 取某分类下全部错题（重练页用）
  static categoryItems(timeRange: string, category: string): WrongItem[] {
    return WrongBookStore.categoryItems(timeRange, category);
  }

  // ===== mock 实现：模拟后端的三次答对判定，联调时整段删除 =====

  private static delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout(resolve, ms);
    });
  }

  private static mockRepractice(answers: WrongAnswer[]): Promise<ApiResponse<RepracticeResult[]>> {
    return new Promise<ApiResponse<RepracticeResult[]>>((resolve: (v: ApiResponse<RepracticeResult[]>) => void): void => {
      WrongApi.delay(MOCK_DELAY_MS).then((): void => {
        const results: RepracticeResult[] = [];
        for (let i = 0; i < answers.length; i++) {
          const item: WrongItem | undefined = WrongBookStore.get(answers[i].questionId);
          if (item === undefined) {
            continue;
          }
          const expectedLetter: string = WrongApi.letterOf(item.answer);
          if (answers[i].userAnswer === expectedLetter) {
            // 答对：答对次数 +1，达到 3 次彻底移除
            // 注意 bumpCorrect 异步，这里用同步读改写保证返回值准确
            item.correctCount++;
            if (item.correctCount >= 3) {
              WrongBookStore.eliminate(item.questionId);
              results.push({
                questionId: item.questionId,
                correctCount: 3,
                eliminated: true
              });
            } else {
              WrongBookStore.flushPublic();
              results.push({
                questionId: item.questionId,
                correctCount: item.correctCount,
                eliminated: false
              });
            }
          } else {
            // 答错：保留在错题本，答对进度重置为 0
            item.correctCount = 0;
            item.wrongCount++;
            item.lastWrongAt = Date.now();
            WrongBookStore.flushPublic();
            results.push({
              questionId: item.questionId,
              correctCount: 0,
              eliminated: false
            });
          }
        }
        resolve({ code: 0, message: 'ok', data: results });
      });
    });
  }

  private static letterOf(index: number): string {
    const letters: string[] = ['A', 'B', 'C', 'D'];
    return index >= 0 && index < letters.length ? letters[index] : '';
  }
}
