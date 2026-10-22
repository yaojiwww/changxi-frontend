import { Http, ApiResponse } from '../common/Http';

// 后端未就绪，先走本地 mock。后端联调时改 false 即可切到真接口，出入参结构已对齐
const USE_MOCK: boolean = true;

// mock 网络耗时（毫秒），用来验证交卷中禁用防重复的交互
const MOCK_DELAY_MS: number = 600;

// 单题作答记录。userAnswer 是选项字母 A/B/C/D，前端不传对错
export interface BatchAnswer {
  questionId: string;
  userAnswer: string;
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
  compare: PracticeComparison | null;   // 首次练习/演示报告没有历史对比时为 null
  answerCard: AnswerCardCell[];
  mastery: KnowledgeMastery[];
}

// 练习域接口。路径与 docs/api_spec.md 一一对应，改接口先改文档再改这里
export class PracticeApi {
  // 批量提交一次练习的全部作答。成功时 data 是完整报告，失败时 data 是 null
  static async batchSubmit(itemId: string, answers: BatchAnswer[], token: string): Promise<ApiResponse<PracticeReport>> {
    if (USE_MOCK) {
      return PracticeApi.mockReport(itemId, answers);
    }
    // 请求体为作答数组，itemId 作为查询参数传入
    return Http.post<PracticeReport>(`/practice/batch-submit?itemId=${itemId}`, answers, token);
  }

  // ===== mock 实现。结构与真接口完全一致，联调时整段删除 =====

  // 各题正确答案字母，与 PracticeData 中的题目顺序对应
  private static readonly CORRECT_LETTERS: string[] = ['A', 'B', 'B', 'C', 'B'];

  // mock 里固定判错的题号下标（演示答题卡红色状态）
  private static readonly WRONG_QUESTION_INDEX: number = 2;

  // 知识点归属，与 PracticeData 中的题目顺序对应
  private static readonly KNOWLEDGE_POINTS: string[] = [
    '未成年人保护法',
    '托育机构安全管理',
    '强制报告制度',
    '托育机构设置标准',
    '职业道德基本要求'
  ];

  private static delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout(resolve, ms);
    });
  }

  private static mockReport(itemId: string, answers: BatchAnswer[]): Promise<ApiResponse<PracticeReport>> {
    return new Promise<ApiResponse<PracticeReport>>((resolve: (v: ApiResponse<PracticeReport>) => void): void => {
      PracticeApi.delay(MOCK_DELAY_MS).then((): void => {
        const card: AnswerCardCell[] = [];
        const tally: Map<string, number[]> = new Map<string, number[]>();
        let correctCount = 0;

        for (let i = 0; i < answers.length; i++) {
          const expected = i < PracticeApi.CORRECT_LETTERS.length ? PracticeApi.CORRECT_LETTERS[i] : 'A';
          const user = answers[i].userAnswer;
          // 第 3 题固定判错，用来演示错题流程
          const isRight = user === expected && i !== PracticeApi.WRONG_QUESTION_INDEX;
          if (isRight) {
            correctCount++;
          }
          card.push({
            questionId: answers[i].questionId,
            correct: isRight,
            userAnswer: user,
            correctOption: expected
          });

          const kp = i < PracticeApi.KNOWLEDGE_POINTS.length ? PracticeApi.KNOWLEDGE_POINTS[i] : '综合';
          const hit = tally.get(kp);
          if (hit === undefined) {
            tally.set(kp, [isRight ? 1 : 0, 1]);
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
          itemName: '相关法律法规及其它试题',
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
