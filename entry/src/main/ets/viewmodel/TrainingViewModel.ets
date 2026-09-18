import { FirstAidStep, ActionType } from '../model/FirstAidStep';
import { TestQuestion } from '../model/TestQuestion';
import { ScenarioType, ScenarioItem, AgeOptionItem, SCENARIO_LIST } from '../model/Scenario';
import { FirstAidRepository } from '../repository/FirstAidRepository';
import { QuestionRepository } from '../repository/QuestionRepository';

/** 培训流程所处的阶段 */
export enum TrainingStage {
  IDLE = 'idle',                     // 首页，什么弹窗都没有
  SELECT_SCENARIO = 'select',        // 场景选择弹窗
  PRE_TEST = 'pre_test',             // 摸底测试
  TRAINING = 'training',             // 分步培训
  POST_TEST = 'post_test'            // 结业测试
}

/** 每轮测试抽几道题 */
const QUESTION_COUNT: number = 5;

/**
 * 急救培训的全部业务状态和流程控制。
 *
 * 规则：这里不 import 任何 UI 相关的东西（不用 router、不用 promptAction），
 * View 只负责把状态画出来、把用户操作转成这里的方法调用。
 */
@Observed
export class TrainingViewModel {
  // ---- 流程状态 ----
  stage: TrainingStage = TrainingStage.IDLE;
  scenarioKey: ScenarioType | null = null;

  // ---- 场景选择 ----
  scenarioList: ScenarioItem[] = SCENARIO_LIST;
  selectedIndex: number = -1;
  showAgeSelector: boolean = false;
  pendingCategory: ScenarioItem | null = null;

  // ---- 培训步骤 ----
  steps: FirstAidStep[] = [];
  stepIndex: number = 0;
  isStepCompleted: boolean = false;
  showDetailInfo: boolean = false;

  // ---- 测试 ----
  questions: TestQuestion[] = [];
  questionIndex: number = 0;
  selectedOption: number = -1;

  // ---- 加载与错误 ----
  isLoading: boolean = false;
  errorMessage: string = '';

  // ==================== 派生状态（View 直接读，不要自己算）====================

  get hasCurrentStep(): boolean {
    return this.stepIndex < this.steps.length;
  }

  /** View 直接读扁平值，不用自己处理 null（ArkTS 对 getter 的类型收窄支持有限） */
  get currentStepTitle(): string {
    return this.hasCurrentStep ? this.steps[this.stepIndex].title : '';
  }

  get currentStepDescription(): string {
    return this.hasCurrentStep ? this.steps[this.stepIndex].description : '';
  }

  /** UniversalAction 需要完整的 step 对象；无步骤时给一个安全的空对象 */
  get currentStep(): FirstAidStep {
    if (this.hasCurrentStep) {
      return this.steps[this.stepIndex];
    }
    return { id: '', title: '', description: '', actionType: ActionType.TAP };
  }

  get hasCurrentQuestion(): boolean {
    return this.questionIndex < this.questions.length;
  }

  get currentQuestionContent(): string {
    return this.hasCurrentQuestion ? this.questions[this.questionIndex].content : '暂无题目';
  }

  get currentQuestionOptions(): string[] {
    return this.hasCurrentQuestion ? this.questions[this.questionIndex].options : [];
  }

  /** 题目总数取实际返回的条数，不写死 */
  get totalQuestions(): number {
    return this.questions.length;
  }

  get isLastQuestion(): boolean {
    return this.questionIndex >= this.questions.length - 1;
  }

  /** 步骤全部走完 */
  get isAllStepsDone(): boolean {
    return this.steps.length > 0 && this.stepIndex >= this.steps.length;
  }

  get isTestStage(): boolean {
    return this.stage === TrainingStage.PRE_TEST || this.stage === TrainingStage.POST_TEST;
  }

  get pendingCategoryTitle(): string {
    return this.pendingCategory !== null ? this.pendingCategory.title : '';
  }

  get pendingAgeOptions(): AgeOptionItem[] {
    if (this.pendingCategory !== null && this.pendingCategory.ageOptions) {
      return this.pendingCategory.ageOptions;
    }
    return [];
  }

  // ==================== 场景选择 ====================

  /** 打开场景选择弹窗，并重置上一轮的残留状态 */
  openScenarioPicker(): void {
    this.stage = TrainingStage.SELECT_SCENARIO;
    this.selectedIndex = -1;
    this.showAgeSelector = false;
    this.pendingCategory = null;
    this.scenarioKey = null;
    this.steps = [];
    this.questions = [];
    this.stepIndex = 0;
    this.isStepCompleted = false;
    this.showDetailInfo = false;
    this.errorMessage = '';
  }

  /** 关闭所有弹窗回到首页 */
  closeAll(): void {
    this.stage = TrainingStage.IDLE;
    this.showAgeSelector = false;
    this.pendingCategory = null;
    this.errorMessage = '';
  }

  highlightScenario(index: number): void {
    this.selectedIndex = index;
  }

  /** 点"下一步"：需要选年龄就进二级，否则直接开始 */
  async confirmScenario(): Promise<void> {
    if (this.selectedIndex < 0 || this.selectedIndex >= this.scenarioList.length) {
      return;
    }
    const item = this.scenarioList[this.selectedIndex];
    if (item.key === null) {
      this.pendingCategory = item;
      this.showAgeSelector = true;
      return;
    }
    await this.startScenario(item.key);
  }

  backToScenarioList(): void {
    this.showAgeSelector = false;
    this.pendingCategory = null;
  }

  async chooseAge(key: ScenarioType): Promise<void> {
    this.showAgeSelector = false;
    this.pendingCategory = null;
    await this.startScenario(key);
  }

  // ==================== 加载数据 ====================

  /** 选定场景，拉取步骤和摸底题目 */
  private async startScenario(key: ScenarioType): Promise<void> {
    this.scenarioKey = key;
    this.stepIndex = 0;
    this.isStepCompleted = false;
    this.showDetailInfo = false;
    this.questionIndex = 0;
    this.selectedOption = -1;
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const steps = await FirstAidRepository.getSteps(key);
      const questions = await QuestionRepository.getQuestions(key, QUESTION_COUNT);
      this.steps = steps;
      this.questions = questions;
      // 没题目就跳过摸底，直接进培训
      this.stage = questions.length > 0 ? TrainingStage.PRE_TEST : TrainingStage.TRAINING;
    } catch (e) {
      const err = e as Error;
      this.errorMessage = `加载失败：${err.message}`;
      this.stage = TrainingStage.SELECT_SCENARIO;
    } finally {
      this.isLoading = false;
    }
  }

  /** 重新抽题，进入结业测试 */
  private async loadPostTest(): Promise<void> {
    if (this.scenarioKey === null) {
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      this.questions = await QuestionRepository.getQuestions(this.scenarioKey, QUESTION_COUNT);
      this.questionIndex = 0;
      this.selectedOption = -1;
      this.stage = TrainingStage.POST_TEST;
    } catch (e) {
      const err = e as Error;
      this.errorMessage = `加载结业测试失败：${err.message}`;
    } finally {
      this.isLoading = false;
    }
  }

  // ==================== 测试流程 ====================

  selectOption(index: number): void {
    this.selectedOption = index;
  }

  /** 下一题；已是最后一题则结束本轮测试 */
  nextQuestion(): void {
    if (!this.isLastQuestion) {
      this.questionIndex++;
      this.selectedOption = -1;
      return;
    }
    this.finishTest();
  }

  /** 跳过整轮测试 */
  skipTest(): void {
    this.finishTest();
  }

  private finishTest(): void {
    if (this.stage === TrainingStage.PRE_TEST) {
      this.stage = TrainingStage.TRAINING;
    } else {
      this.stage = TrainingStage.IDLE;
    }
  }

  // ==================== 培训步骤 ====================

  /** 子组件完成交互动作时回调 */
  completeStep(): void {
    this.isStepCompleted = true;
  }

  showDetail(): void {
    this.showDetailInfo = true;
  }

  hideDetail(): void {
    this.showDetailInfo = false;
  }

  /** 下一步；已是最后一步则推进到"全部完成" */
  nextStep(): void {
    if (this.stepIndex < this.steps.length - 1) {
      this.stepIndex++;
      this.isStepCompleted = false;
      this.showDetailInfo = false;
      return;
    }
    this.stepIndex = this.steps.length;   // 越界 = 全部完成
  }

  /** 完成页点"前往结业测试" */
  async gotoPostTest(): Promise<void> {
    await this.loadPostTest();
  }
}
