import { Http, ApiResponse } from '../common/Http';
import { KpEntry, kpOf } from '../common/KnowledgeCatalog';
import { questionsOf, judge } from '../common/QuestionBank';
import { PracticeQuestion, PracticeQuestionsData, JudgeResult } from '../model/QuestionModels';

// 后端未就绪，先走本地 mock（题目取 common/QuestionBank 的本地题库）。
// 后端联调时改 false 即可切到真接口，出入参结构已对齐
const USE_MOCK: boolean = true;

// mock 网络耗时（毫秒），用来验证交卷中禁用防重复的交互
const MOCK_DELAY_MS: number = 600;

// 一次抽题的题量上限
const QUESTION_COUNT: number = 20;

// 单题作答记录。userAnswer 是选项字母 A/B/C/D，前端不传对错
export interface BatchAnswer {
  questionId: string;
  userAnswer: string;
}

// 判题请求体
interface JudgeAnswerBody {
  questionId: string;
  userAnswer: string;
  kpId: string;
}

// 答题卡单格
export interface AnswerCardCell {
  questionId: string;
  correct: boolean;
  userAnswer: string;    // 用户所选字母
  correctOption: string; // 正确答案字母
}

// 知识点掌握度，字段由后端聚合
export interface KnowledgeMastery {
  knowledgePoint: string;
  correct: number;
  total: number;
  accuracy: number;  // 百分数数值，如 60
}

// 数据对比：与上次练习、与合格线。后端未给的字段为 null，报告页显示 --
export interface PracticeComparison {
  lastAccuracy: number | null;    // 上次正确率
  deltaVsLast: number | null;     // 较上次变化，正负百分点
  deltaVsPassLine: number | null; // 较合格线(60)变化，正负百分点
}

// 练习报告，由 POST /practice/batch-submit 一次性返回。
// 所有展示数据只来自这里，前端不做任何计算
export interface PracticeReport {
  itemId: string;
  itemName: string;        // 知识条目名
  practiceType: string;    // 练习类型，如 基础知识·单选练习
  submitTime: string;      // 交卷时间，如 2026-10-12 20:15:08
  correctCount: number;    // 答对题数
  total: number;           // 总题数
  accuracy: number | null; // 正确率百分比；后端未给时为 null，报告页显示 --
  duration: number;        // 练习时长秒数
  compare: PracticeComparison;
  answerCard: AnswerCardCell[];
  mastery: KnowledgeMastery[];
}

// 练习域接口。路径与 docs/api_spec.md 一一对应，改接口先改文档再改这里
export class PracticeApi {
  // 按知识点抽题。kpId 见 common/KnowledgeCatalog；返回的题目不含答案，判题走 answer()
  static async questions(kpId: string, token: string): Promise<ApiResponse<PracticeQuestionsData>> {
    if (USE_MOCK) {
      return PracticeApi.mockQuestions(kpId);
    }
    const path: string = `/practice/questions?kpId=${encodeURIComponent(kpId)}&count=${QUESTION_COUNT}`;
    return Http.get<PracticeQuestionsData>(path, token);
  }

  // 单题作答：即选即判，返回对错、正确选项与解析
  static async answer(questionId: string, userAnswer: string, kpId: string,
    token: string): Promise<ApiResponse<JudgeResult>> {
    if (USE_MOCK) {
      return PracticeApi.mockAnswer(kpId, questionId, userAnswer);
    }
    const body: JudgeAnswerBody = { questionId: questionId, userAnswer: userAnswer, kpId: kpId };
    return Http.post<JudgeResult>('/practice/answer', body, token);
  }

  // 批量提交一次练习的全部作答。成功时 data 是完整报告，失败时 data 是 null
  static async batchSubmit(itemId: string, answers: BatchAnswer[], token: string): Promise<ApiResponse<PracticeReport>> {
    if (USE_MOCK) {
      return PracticeApi.mockReport(itemId, answers);
    }
    // 请求体为作答数组，itemId 作为查询参数传入
    return Http.post<PracticeReport>(`/practice/batch-submit?itemId=${itemId}`, answers, token);
  }

  // ===== mock 实现。结构与真接口完全一致，联调时整段删除 =====

  private static delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout(resolve, ms);
    });
  }

  // 抽题：本地题库即时返回（练习页没有 loading 态，慢一点就会出现空页闪动）
  private static mockQuestions(kpId: string): Promise<ApiResponse<PracticeQuestionsData>> {
    return new Promise<ApiResponse<PracticeQuestionsData>>((resolve: (v: ApiResponse<PracticeQuestionsData>) => void): void => {
      const kp: KpEntry | undefined = kpOf(kpId);
      if (kp === undefined) {
        resolve({ code: 1004, message: '知识点不存在', data: null });
        return;
      }
      resolve({
        code: 0,
        message: 'ok',
        data: {
          kpId: kpId,
          kpName: kp.label,
          total: kp.total,
          questions: questionsOf(kpId)
        }
      });
    });
  }

  // 判题：本地题库查答案，与后端 /practice/answer 的返回结构一致
  private static mockAnswer(kpId: string, questionId: string, userAnswer: string): Promise<ApiResponse<JudgeResult>> {
    return new Promise<ApiResponse<JudgeResult>>((resolve: (v: ApiResponse<JudgeResult>) => void): void => {
      const result: JudgeResult | undefined = judge(kpId, questionId, userAnswer);
      if (result === undefined) {
        resolve({ code: 1004, message: '题目不存在', data: null });
        return;
      }
      resolve({ code: 0, message: 'ok', data: result });
    });
  }

  private static mockReport(itemId: string, answers: BatchAnswer[]): Promise<ApiResponse<PracticeReport>> {
    return new Promise<ApiResponse<PracticeReport>>((resolve: (v: ApiResponse<PracticeReport>) => void): void => {
      PracticeApi.delay(MOCK_DELAY_MS).then((): void => {
        const kp: KpEntry | undefined = kpOf(itemId);
        const kpLabel: string = kp !== undefined ? kp.label : '';
        const card: AnswerCardCell[] = [];
        const tally: Map<string, number[]> = new Map<string, number[]>();
        let correctCount = 0;

        for (let i = 0; i < answers.length; i++) {
          const judged: JudgeResult | undefined = judge(itemId, answers[i].questionId, answers[i].userAnswer);
          const isRight: boolean = judged !== undefined && judged.correct;
          const correctOption: string = judged !== undefined ? judged.correctOption : '';
          if (isRight) {
            correctCount++;
          }
          card.push({
            questionId: answers[i].questionId,
            correct: isRight,
            userAnswer: answers[i].userAnswer,
            correctOption: correctOption
          });

          const kpName: string = kpLabel !== '' ? kpLabel : '综合';
          const hit = tally.get(kpName);
          if (hit === undefined) {
            tally.set(kpName, [isRight ? 1 : 0, 1]);
          } else {
            hit[0] += isRight ? 1 : 0;
            hit[1] += 1;
          }
        }

        const mastery: KnowledgeMastery[] = [];
        tally.forEach((v: number[], k: string): void => {
          mastery.push({
            knowledgePoint: k,
            correct: v[0],
            total: v[1],
            accuracy: Math.round(v[0] * 100 / v[1])
          });
        });

        const total = answers.length;
        const accuracy = total > 0 ? Math.round(correctCount * 100 / total) : 0;
        const report: PracticeReport = {
          itemId: itemId,
          itemName: kpLabel,
          practiceType: '基础知识 · 单选练习',
          submitTime: PracticeApi.formatNow(),
          correctCount: correctCount,
          total: total,
          accuracy: accuracy,
          duration: 186,
          compare: {
            lastAccuracy: 72,
            deltaVsLast: accuracy - 72,
            deltaVsPassLine: accuracy - 60
          },
          answerCard: card,
          mastery: mastery
        };
        resolve({ code: 0, message: 'ok', data: report });
      });
    });
  }

  // 生成当前时间字符串，格式 YYYY-MM-DD HH:mm:ss
  private static formatNow(): string {
    const d: Date = new Date();
    const p = (n: number): string => (n < 10 ? '0' + n : '' + n);
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ` +
      `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
  }
}
