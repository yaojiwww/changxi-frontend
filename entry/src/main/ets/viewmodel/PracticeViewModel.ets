// 知识点练习页的 ViewModel：持有全部作答状态与取数逻辑，不碰 UI。
// 页面只做渲染与路由；判题、解析、收藏、错题入库都在这里。
// 取数失败一律 throw Error，由页面 catch 后 toast。
import { common } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { AppConfig } from '../common/AppConfig';
import { TokenStore } from '../common/TokenStore';
import { CODE_OK, ApiResponse } from '../common/Http';
import { FavoritesStore, FavoriteItem } from '../common/FavoritesStore';
import { WrongBookStore } from '../common/WrongBookStore';
import { GoalModel, GoalCache } from '../common/GoalModel';
import { KpEntry, resolveKp } from '../common/KnowledgeCatalog';
import { questionsOf, answerIndexOf } from '../common/QuestionBank';
import { PracticeQuestion, PracticeQuestionsData, JudgeResult } from '../model/QuestionModels';
import { PracticeApi } from '../api/PracticeApi';
import { FavoritesApi } from '../api/FavoritesApi';

// 选项字母：与 options 数组下标一一对应
const OPTION_LETTERS: string[] = ['A', 'B', 'C', 'D'];

// 一道题的作答态。@ObservedV2 + @Trace：页面直接读字段，改动自动刷新
@ObservedV2
export class PracticeItem {
  questionId: string = '';
  stem: string = '';
  options: string[] = [];
  knowledgePoint: string = '';
  @Trace picked: string = '';          // 用户所选字母，'' = 未作答
  @Trace judged: boolean = false;      // 是否已判定
  @Trace correct: boolean = false;     // 判定结果：是否答对
  @Trace correctOption: string = '';   // 正确选项字母，未判定时为空串
  @Trace explanation: string = '';     // 解析，未判定时为空串

  constructor(q: PracticeQuestion) {
    this.questionId = q.questionId;
    this.stem = q.stem;
    this.options = q.options;
    this.knowledgePoint = q.knowledgePoint;
  }

  // 记下判定结果（对错、正确选项、解析一次性写入）
  markJudged(result: JudgeResult): void {
    this.judged = true;
    this.correct = result.correct;
    this.correctOption = result.correctOption;
    this.explanation = result.explanation;
  }
}

@ObservedV2
export class PracticeViewModel {
  @Trace hasBank: boolean = false;   // 该知识点是否有题：false 时页面显示占位
  @Trace kpName: string = '';        // 知识点完整名，显示在题干卡上方
  @Trace total: number = 0;          // 知识点题库总题量，进度条与 x/N 按它算
  @Trace items: PracticeItem[] = [];
  @Trace cur: number = 0;
  @Trace done: boolean = false;      // 已做到本章节最后一题
  @Trace starred: boolean = false;   // 当前题收藏状态

  private kpId: string = '';
  private token: string = '';
  private judging: Promise<void> | undefined = undefined;   // 正在进行的判题请求

  // 页面 aboutToAppear 调一次：准备配置/本地存储，再按章节名 + 报考级别取题
  async init(context: common.Context, pageTitle: string): Promise<void> {
    await AppConfig.load(context);
    await TokenStore.init(context);
    await FavoritesStore.init(context);
    await WrongBookStore.init(context);
    await GoalCache.load(context);   // 报考级别是章节消歧的依据（幂等，可多页调用）
    this.token = await TokenStore.read();

    const goal: GoalModel = AppStorageV2.connect(GoalModel, () => new GoalModel())!;
    const kp: KpEntry | undefined = resolveKp(pageTitle, goal.levelIndex);
    if (kp === undefined) {
      // 尚无题库的章节：保持占位页，不报错
      this.hasBank = false;
      return;
    }

    this.kpId = kp.kpId;
    this.kpName = kp.label;
    this.total = kp.total;
    this.items = this.toItems(await this.loadQuestions(kp));
    this.hasBank = this.items.length > 0;
    this.cur = 0;
    this.done = false;
    this.refreshStar();
  }

  // 取题：先走后端接口，失败或为空则退回本地题库（与每日一练的兜底策略一致，界面不提示）
  private async loadQuestions(kp: KpEntry): Promise<PracticeQuestion[]> {
    try {
      const res: ApiResponse<PracticeQuestionsData> = await PracticeApi.questions(kp.kpId, this.token);
      if (res.code === CODE_OK && res.data !== null && res.data.questions.length > 0) {
        return res.data.questions;
      }
    } catch (err) {
      // 网络异常：继续走本地题库
    }
    return questionsOf(kp.kpId);
  }

  private toItems(list: PracticeQuestion[]): PracticeItem[] {
    const out: PracticeItem[] = [];
    for (let i = 0; i < list.length; i++) {
      out.push(new PracticeItem(list[i]));
    }
    return out;
  }

  // ===== 当前题只读视图（页面读这些，不直接碰 items 下标） =====

  current(): PracticeItem | undefined {
    if (this.cur < 0 || this.cur >= this.items.length) {
      return undefined;
    }
    return this.items[this.cur];
  }

  count(): number {
    return this.items.length;
  }

  stemText(): string {
    const item: PracticeItem | undefined = this.current();
    return item !== undefined ? item.stem : '';
  }

  optionList(): string[] {
    const item: PracticeItem | undefined = this.current();
    return item !== undefined ? item.options : [];
  }

  picked(): string {
    const item: PracticeItem | undefined = this.current();
    return item !== undefined ? item.picked : '';
  }

  answered(): boolean {
    return this.picked() !== '';
  }

  judged(): boolean {
    const item: PracticeItem | undefined = this.current();
    return item !== undefined && item.judged;
  }

  correctOption(): string {
    const item: PracticeItem | undefined = this.current();
    return item !== undefined ? item.correctOption : '';
  }

  explanation(): string {
    const item: PracticeItem | undefined = this.current();
    return item !== undefined ? item.explanation : '';
  }

  isCorrect(): boolean {
    const item: PracticeItem | undefined = this.current();
    return item !== undefined && item.judged && item.correct;
  }

  isLast(): boolean {
    return this.cur === this.items.length - 1;
  }

  // 进度条宽度：按知识点题库总题量计算（如第 1 题 / 358 题）
  progressPct(): number {
    return this.total > 0 ? (this.cur + 1) / this.total * 100 : 0;
  }

  // 本轮答对题数
  correctCount(): number {
    let n = 0;
    for (let i = 0; i < this.items.length; i++) {
      if (this.items[i].judged && this.items[i].correct) {
        n++;
      }
    }
    return n;
  }

  // ===== 交互 =====

  // 选答：记录选项，随后取判定结果（对错与解析由接口给，mock 阶段是本地题库）
  async pick(letter: string): Promise<void> {
    if (this.judged() || this.done) {
      return;
    }
    const item: PracticeItem | undefined = this.current();
    if (item === undefined) {
      return;
    }
    item.picked = letter;
    const task: Promise<void> = this.judge(item, letter);
    this.judging = task;
    await task;
  }

  // 判题：请求判定结果并写回题目。失败 throw，由页面 toast
  private async judge(item: PracticeItem, letter: string): Promise<void> {
    const res: ApiResponse<JudgeResult> = await PracticeApi.answer(item.questionId, letter, this.kpId, this.token);
    if (res.code !== CODE_OK || res.data === null) {
      throw new Error(res.message);
    }
    item.markJudged(res.data);
  }

  // 下一题 / 完成练习。调用前页面已确认本题有作答
  async next(): Promise<void> {
    const item: PracticeItem | undefined = this.current();
    if (item === undefined) {
      return;
    }
    // 选答后立刻点下一题时，判题可能还在路上：先等它回来，避免漏记错题
    const judging: Promise<void> | undefined = this.judging;
    if (judging !== undefined && !item.judged) {
      try {
        await judging;
      } catch (err) {
        // 判题失败：按未判定处理，不阻断翻页
      }
    }
    // 离开本题前终判：答错则静默写入错题本
    if (item.judged && !item.correct) {
      await WrongBookStore.markWrong(item.questionId, item.stem, item.options.slice(),
        OPTION_LETTERS.indexOf(item.correctOption), item.knowledgePoint, 'practice');
    }
    if (this.isLast()) {
      this.done = true;
    } else {
      this.cur++;
      this.refreshStar();
    }
  }

  prev(): void {
    if (this.done) {
      this.done = false;   // 完成页回退到最后一题
      return;
    }
    if (this.cur > 0) {
      this.cur--;
      this.refreshStar();
    }
  }

  // ===== 收藏星标 =====

  refreshStar(): void {
    const item: PracticeItem | undefined = this.current();
    this.starred = item !== undefined && FavoritesStore.isFavorited(item.questionId);
  }

  async toggleStar(): Promise<void> {
    const item: PracticeItem | undefined = this.current();
    if (item === undefined) {
      return;
    }
    if (this.starred) {
      await FavoritesApi.cancel(item.questionId, this.token);
      this.starred = false;
      return;
    }
    const favorite: FavoriteItem = {
      questionId: item.questionId,
      stem: item.stem,
      options: item.options.slice(),
      answer: this.answerIndexOf(item),
      knowledgePoint: item.knowledgePoint,
      source: 'practice',
      favoritedAt: Date.now()
    };
    await FavoritesApi.add(favorite, this.token);
    this.starred = true;
  }

  // 收藏 / 错题本存的是选项下标：判定过就用判定结果，否则回本地题库查
  private answerIndexOf(item: PracticeItem): number {
    if (item.judged) {
      return OPTION_LETTERS.indexOf(item.correctOption);
    }
    return answerIndexOf(this.kpId, item.questionId);
  }
}
