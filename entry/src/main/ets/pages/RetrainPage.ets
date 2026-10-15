// 重练答题页：收藏重练 / 错题重练共用（params.source 区分）
// UI 与练习页一致：无进度、无对错标签、无提交按钮，点选自动跳下一题
// 收藏题提供【取消收藏】；错题源结束后调 POST /wrong/repractice 提交
// 结束只提示「重练完成」并返回列表刷新，不跳练习报告页
import { FavoritesStore, FavoriteItem } from '../common/FavoritesStore';
import { WrongBookStore, WrongItem } from '../common/WrongBookStore';
import { WrongApi, WrongAnswer, RepracticeResult } from '../api/WrongApi';
import { TokenStore } from '../common/TokenStore';

// 路由参数
export interface RetrainParams {
  source: string;      // favorite / wrong
  category: string;    // 知识点分类，'不限' 表示全部
  timeRange: string;   // all / today / week / stubborn
}

const OPTION_LETTERS: string[] = ['A', 'B', 'C', 'D'];
const ADVANCE_DELAY_MS: number = 150;
const SOURCE_FAVORITE: string = 'favorite';
const SOURCE_WRONG: string = 'wrong';

// 重练用的统一题目视图
interface RetrainQuestion {
  questionId: string;
  stem: string;
  options: string[];
  answer: number;          // 收藏题有本地答案，错题为 -1 由后端判
  knowledgePoint: string;
}

@Entry
@ComponentV2
struct RetrainPage {
  @Local source: string = SOURCE_FAVORITE;
  @Local category: string = '';
  @Local timeRange: string = 'all';
  @Local title: string = '重练';

  @Local questions: RetrainQuestion[] = [];
  @Local currentIndex: number = 0;
  @Local selectedIndex: number = -1;
  @Local advancing: boolean = false;
  @Local submitting: boolean = false;
  @Local submitFailed: boolean = false;
  @Local starred: boolean = false;

  private answers: string[] = [];
  private advanceTimer: number = -1;
  private token: string = '';

  async aboutToAppear(): Promise<void> {
    const params = this.getUIContext().getRouter().getParams() as RetrainParams | undefined;
    if (params !== undefined) {
      this.source = params.source;
      this.category = params.category;
      this.timeRange = params.timeRange;
    }
    this.title = this.source === SOURCE_WRONG ? '错题重练' : '收藏重练';

    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      await FavoritesStore.init(context);
      await WrongBookStore.init(context);
    }
    this.token = await TokenStore.read();
    this.loadQuestions();
  }

  aboutToDisappear(): void {
    if (this.advanceTimer !== -1) {
      clearTimeout(this.advanceTimer);
      this.advanceTimer = -1;
    }
  }

  // 只加载该分类下的收藏题 / 错题
  private loadQuestions(): void {
    const list: RetrainQuestion[] = [];
    if (this.source === SOURCE_WRONG) {
      const items: WrongItem[] = WrongBookStore.categoryItems(this.timeRange, this.category);
      for (let i = 0; i < items.length; i++) {
        list.push({
          questionId: items[i].questionId,
          stem: items[i].stem,
          options: items[i].options,
          answer: items[i].answer,
          knowledgePoint: items[i].knowledgePoint
        });
      }
    } else {
      const items: FavoriteItem[] = FavoritesStore.categoryItems(this.timeRange, this.category);
      for (let i = 0; i < items.length; i++) {
        list.push({
          questionId: items[i].questionId,
          stem: items[i].stem,
          options: items[i].options,
          answer: items[i].answer,
          knowledgePoint: items[i].knowledgePoint
        });
      }
    }
    this.questions = list;
    this.answers = [];
    for (let i = 0; i < list.length; i++) {
      this.answers.push('');
    }
    this.refreshStar();
  }

  private goBack(): void {
    if (this.advanceTimer !== -1) {
      clearTimeout(this.advanceTimer);
      this.advanceTimer = -1;
    }
    this.getUIContext().getRouter().back();
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  private get currentQuestion(): RetrainQuestion {
    return this.questions[this.currentIndex];
  }

  private get isLastQuestion(): boolean {
    return this.currentIndex === this.questions.length - 1;
  }

  private refreshStar(): void {
    if (this.source !== SOURCE_FAVORITE || this.questions.length === 0) {
      this.starred = false;
      return;
    }
    this.starred = FavoritesStore.isFavorited(this.currentQuestion.questionId);
  }

  // 取消收藏：立即从收藏列表与存储移除；若全部取消完则返回列表
  private async cancelCurrent(): Promise<void> {
    if (this.questions.length === 0) {
      return;
    }
    const q: RetrainQuestion = this.currentQuestion;
    await FavoritesStore.remove(q.questionId);
    this.toast('已取消收藏');

    this.loadQuestions();
    if (this.questions.length === 0) {
      this.goBack();
      return;
    }
    if (this.currentIndex >= this.questions.length) {
      this.currentIndex = this.questions.length - 1;
    }
  }

  // 点选自动跳下一题；末题触发结束流程
  private selectOption(index: number): void {
    if (this.advancing || this.submitting) {
      return;
    }
    this.selectedIndex = index;
    this.advancing = true;
    this.answers[this.currentIndex] = OPTION_LETTERS[index];

    this.advanceTimer = setTimeout((): void => {
      this.advanceTimer = -1;
      this.advancing = false;
      this.selectedIndex = -1;
      if (this.isLastQuestion) {
        this.finish();
      } else {
        this.currentIndex++;
        this.refreshStar();
      }
    }, ADVANCE_DELAY_MS);
  }

  // 结束：错题源调重练提交接口；收藏源无需提交。均提示重练完成并返回
  private async finish(): Promise<void> {
    if (this.source === SOURCE_WRONG) {
      this.submitting = true;
      this.submitFailed = false;
      try {
        const answers: WrongAnswer[] = [];
        for (let i = 0; i < this.questions.length; i++) {
          answers.push({ questionId: this.questions[i].questionId, userAnswer: this.answers[i] });
        }
        const res = await WrongApi.repractice(answers, this.token);
        if (res.code === 0 && res.data !== null) {
          this.toastWithBack('重练完成');
        } else {
          this.submitFailed = true;
          this.toast(res.message !== '' ? res.message : '提交失败，请重试');
        }
      } catch (e) {
        this.submitFailed = true;
        this.toast('网络异常，提交失败');
      } finally {
        this.submitting = false;
      }
    } else {
      this.toastWithBack('重练完成');
    }
  }

  // 提示后返回列表（列表 onPageShow 自动刷新）
  private toastWithBack(msg: string): void {
    this.toast(msg);
    setTimeout((): void => {
      this.goBack();
    }, 600);
  }

  private optionBorder(index: number): string {
    return index === this.selectedIndex ? '#2B57E5' : '#E5EAF2';
  }

  private optionBg(index: number): string {
    return index === this.selectedIndex ? '#EEF3FF' : '#FFFFFF';
  }

  @Builder
  OptionItem(index: number) {
    Row({ space: 10 }) {
      Text(OPTION_LETTERS[index])
        .fontSize(15.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B57E5')
        .width(26)
        .height(26)
        .textAlign(TextAlign.Center)
        .borderRadius(13)
        .backgroundColor('#EEF3FF')

      Text(this.currentQuestion.options[index])
        .fontSize(16.0)
        .fontColor('#1A202C')
        .layoutWeight(1)
        .lineHeight(22)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .borderRadius(12)
    .backgroundColor(this.optionBg(index))
    .border({ width: 1.5, color: this.optionBorder(index) })
    .onClick(() => {
      this.selectOption(index);
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 顶部返回栏：标题 = 分类名，收藏源附取消收藏按钮
        Row() {
          Text('‹')
            .fontSize(34.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A202C')
            .padding({ left: 16, right: 12, top: 4, bottom: 4 })
            .onClick(() => {
              this.goBack();
            })

          Text(this.category !== '' && this.category !== '不限' ? this.category : this.title)
            .fontSize(18.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A202C')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.source === SOURCE_FAVORITE && this.starred) {
            Text('取消收藏')
              .fontSize(14.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#EF4444')
              .padding({ left: 12, right: 18, top: 6, bottom: 6 })
              .onClick(() => {
                this.cancelCurrent();
              })
          }
        }
        .width('100%')
        .height(56)
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)
        .border({ width: { bottom: 1 }, color: '#F1F4F9' })

        if (this.questions.length === 0) {
          Column({ space: 10 }) {
            Text('暂无题目').fontSize(17.0).fontColor('#8A94A6')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
              Text(this.currentQuestion.stem)
                .fontSize(17.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A202C')
                .lineHeight(26)
                .width('100%')
                .padding(16)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .margin({ bottom: 16 })

              Column({ space: 10 }) {
                ForEach(this.currentQuestion.options, (opt: string, idx: number) => {
                  this.OptionItem(idx)
                }, (opt: string, idx: number) => `${this.currentIndex}_${idx}_${opt}`)
              }
              .width('100%')

              if (this.submitFailed) {
                Column({ space: 12 }) {
                  Text('提交失败，答案未记录').fontSize(15.0).fontColor('#EF4444')
                  Row() {
                    Text('重新提交')
                      .fontSize(16.0)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.White)
                  }
                  .padding({ left: 26, right: 26, top: 10, bottom: 10 })
                  .borderRadius(20)
                  .linearGradient({ angle: 90, colors: [['#4A8CF8', 0.0], ['#2B57E5', 1.0]] })
                  .onClick(() => {
                    this.finish();
                  })
                }
                .width('100%')
                .margin({ top: 20 })
                .alignItems(HorizontalAlign.Center)
              }

              Row().width('100%').height(60)
            }
            .padding({ left: 16, right: 16, top: 8 })
            .width('100%')
          }
          .layoutWeight(1)
          .enabled(!this.submitting)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA')

      // 提交中遮罩
      if (this.submitting) {
        Column() {
          Column({ space: 14 }) {
            LoadingProgress().width(40).height(40).color(Color.White)
            Text('提交中...').fontSize(16.0).fontWeight(FontWeight.Medium).fontColor(Color.White)
          }
          .width(140)
          .height(120)
          .borderRadius(16)
          .backgroundColor('#CC1A202C')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
