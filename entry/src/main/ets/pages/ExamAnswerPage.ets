// 模拟考试答题页：开始考试 / 继续考试共用
// 交互同每日一练：底部「上一题 / 下一题」按钮、右上角答题卡面板、点选持续高亮
// 差异：顶部 90 分钟倒计时、每题落库断点续答、答题卡面板支持提前交卷
// 交卷：清进行中缓存 → 写已考记录 → replaceUrl 跳成绩页
import { ExamQuestion, questionsOf, paperOf } from '../common/ExamData';
import { ExamStore, ExamProgress, ExamFinished, ExamAnswerCell, ExamParseItem } from '../common/ExamStore';
import { FavoritesStore, FavoriteItem } from '../common/FavoritesStore';
import { StudyRecordStore, StudyRecord } from '../common/StudyRecordStore';
import { WrongBookStore } from '../common/WrongBookStore';

// 路由参数
export interface ExamAnswerParams {
  paperId: string;
}

// 选项字母
const OPTION_LETTERS: string[] = ['A', 'B', 'C', 'D'];

// 默认考试时长（分钟）
const EXAM_MINUTES: number = 90;

@Entry
@ComponentV2
struct ExamAnswerPage {
  @Local paperId: string = '';
  @Local paperTitle: string = '';
  @Local questions: ExamQuestion[] = [];

  @Local currentIndex: number = 0;
  @Local selectedIndex: number = -1;    // 当前题选中下标，作答后保持高亮
  @Local submitting: boolean = false;   // 交卷中，全屏禁用防重复
  @Local remainSec: number = 0;         // 倒计时剩余秒
  @Local starred: boolean = false;      // 当前题收藏状态
  @Local sheetOpen: boolean = false;    // 答题卡底部面板开关
  @Local confirmSubmit: boolean = false;// 有未答题时二次确认交卷

  // 作答记录，下标与题目一致，空串未答；同时持久化到 ExamStore
  private answers: string[] = [];
  private deadline: number = 0;         // 交卷截止时间戳
  private startTime: number = 0;        // 开考时间戳
  private tickTimer: number = -1;
  private token: string = '';

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      await ExamStore.init(context);
      await StudyRecordStore.init(context);
      await WrongBookStore.init(context);
    }
    const params = this.getUIContext().getRouter().getParams() as ExamAnswerParams | undefined;
    if (params !== undefined && params.paperId !== undefined && params.paperId !== '') {
      this.paperId = params.paperId;
    }
    const paper = paperOf(this.paperId);
    this.paperTitle = paper !== undefined ? paper.title : '';
    this.questions = questionsOf(this.paperId);
    this.answers = [];
    for (let i = 0; i < this.questions.length; i++) {
      this.answers.push('');
    }

    // 恢复进行中记录（断点续答），无则新建；换卷则覆盖旧记录
    const saved: ExamProgress | null = ExamStore.getProgress();
    if (saved !== null && saved.paperId === this.paperId) {
      this.currentIndex = saved.index < this.questions.length ? saved.index : 0;
      this.deadline = saved.deadline;
      this.startTime = saved.startTime;
      for (let i = 0; i < this.answers.length && i < saved.answers.length; i++) {
        this.answers[i] = saved.answers[i];
      }
    } else {
      this.currentIndex = 0;
      this.startTime = Date.now();
      this.deadline = this.startTime + EXAM_MINUTES * 60 * 1000;
    }
    await this.persist();
    this.syncSelected();
    this.refreshStar();
    this.startTick();
  }

  aboutToDisappear(): void {
    this.stopTick();
  }

  private goBack(): void {
    // 中途退出：记录已在每次作答时落库，列表悬浮栏可「继续考试」
    this.stopTick();
    this.getUIContext().getRouter().back();
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  private get isLastQuestion(): boolean {
    return this.currentIndex === this.questions.length - 1;
  }

  // 末题已作答后显示「交卷」按钮
  private get canSubmit(): boolean {
    return this.questions.length > 0 && this.isLastQuestion && this.answers[this.currentIndex] !== '';
  }

  // ===== 题目跳转与高亮回显 =====

  // 进入/切换题目时，回显当前题已选选项的高亮
  private syncSelected(): void {
    if (this.questions.length === 0) {
      this.selectedIndex = -1;
      return;
    }
    const a: string = this.answers[this.currentIndex];
    this.selectedIndex = (a !== undefined && a !== '') ? OPTION_LETTERS.indexOf(a) : -1;
  }

  // 跳到某题（答题卡 / 上一题 / 下一题共用）
  private gotoQuestion(i: number): void {
    if (i < 0 || i >= this.questions.length) {
      return;
    }
    this.currentIndex = i;
    this.persist();
    this.syncSelected();
    this.refreshStar();
    this.confirmSubmit = false;
  }

  // 未作答题数
  private unansweredCount(): number {
    let n: number = 0;
    for (let i = 0; i < this.answers.length; i++) {
      if (this.answers[i] === '') {
        n++;
      }
    }
    return n;
  }

  // ===== 收藏星标（同练习页，写入公共收藏 Store）=====

  private refreshStar(): void {
    if (this.questions.length === 0) {
      this.starred = false;
      return;
    }
    this.starred = FavoritesStore.isFavorited(this.questions[this.currentIndex].questionId);
  }

  private async toggleStar(): Promise<void> {
    if (this.questions.length === 0) {
      return;
    }
    const q: ExamQuestion = this.questions[this.currentIndex];
    if (this.starred) {
      await FavoritesStore.remove(q.questionId);
      this.starred = false;
      this.toast('已取消收藏');
    } else {
      const item: FavoriteItem = {
        questionId: q.questionId,
        stem: q.stem,
        options: q.options,
        answer: q.answer,
        knowledgePoint: this.paperTitle,
        source: 'exam',
        favoritedAt: Date.now()
      };
      await FavoritesStore.add(item);
      this.starred = true;
      this.toast('已加入收藏');
    }
  }

  // ===== 倒计时 =====

  private startTick(): void {
    this.stopTick();
    this.remainSec = Math.floor((this.deadline - Date.now()) / 1000);
    this.tickTimer = setInterval((): void => {
      const left: number = Math.floor((this.deadline - Date.now()) / 1000);
      this.remainSec = left > 0 ? left : 0;
      if (this.remainSec <= 0) {
        this.stopTick();
        // 时间到：自动交卷
        this.submitExam();
      }
    }, 1000);
  }

  private stopTick(): void {
    if (this.tickTimer !== -1) {
      clearInterval(this.tickTimer);
      this.tickTimer = -1;
    }
  }

  // 剩余秒 → HH:mm:ss
  private formatRemain(sec: number): string {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    const p = (n: number): string => (n < 10 ? '0' + n : '' + n);
    return `${p(h)}:${p(m)}:${p(s)}`;
  }

  // 持久化进行中记录（断点续答核心）
  private async persist(): Promise<void> {
    const p: ExamProgress = {
      paperId: this.paperId,
      paperTitle: this.paperTitle,
      answers: this.answers.slice(),
      index: this.currentIndex,
      deadline: this.deadline,
      startTime: this.startTime
    };
    await ExamStore.saveProgress(p);
  }

  // ===== 点选与跳题 =====

  // 点击选项：记录并保持高亮，由底部「下一题」或答题卡切换题目
  private selectOption(index: number): void {
    if (this.submitting) {
      return;
    }
    this.selectedIndex = index;
    this.answers[this.currentIndex] = OPTION_LETTERS[index];
    this.persist();
  }

  // ===== 交卷 =====

  private pad2(n: number): string {
    return n < 10 ? '0' + n : '' + n;
  }

  private formatDateTime(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getFullYear()}-${this.pad2(d.getMonth() + 1)}-${this.pad2(d.getDate())}` +
      ` ${this.pad2(d.getHours())}:${this.pad2(d.getMinutes())}:${this.pad2(d.getSeconds())}`;
  }

  // 交卷：比对预设答案算分 → 清进行中 → 写已考记录 → replaceUrl 跳成绩页
  private async submitExam(): Promise<void> {
    if (this.submitting) {
      return;
    }
    this.stopTick();
    this.submitting = true;

    const card: ExamAnswerCell[] = [];
    const parses: ExamParseItem[] = [];
    let correctCount: number = 0;
    for (let i = 0; i < this.questions.length; i++) {
      const q: ExamQuestion = this.questions[i];
      const user: string = this.answers[i];
      const correctOpt: string = OPTION_LETTERS[q.answer];
      const isCorrect: boolean = user === correctOpt;
      if (isCorrect) {
        correctCount++;
      }
      card.push({
        questionId: q.questionId,
        correct: isCorrect,
        userAnswer: user,
        correctOption: correctOpt
      });
      if (!isCorrect) {
        parses.push({
          questionId: q.questionId,
          stem: q.stem,
          userAnswer: user !== '' ? user : '未作答',
          correctOption: correctOpt,
          explanation: q.explanation
        });
        // 答错的题写入错题本（知识点归到「模拟考试」分组）
        await WrongBookStore.markWrong(q.questionId, q.stem, q.options, q.answer,
          '模拟考试', 'exam');
      }
    }

    const total: number = this.questions.length;
    const score: number = total > 0 ? Math.round(correctCount * 100 / total) : 0;
    const duration: number = Math.max(1, Math.floor((Date.now() - this.startTime) / 1000));

    const report: ExamFinished = {
      paperId: this.paperId,
      paperTitle: this.paperTitle,
      score: score,
      total: total,
      correctCount: correctCount,
      duration: duration,
      submitTime: this.formatDateTime(Date.now()),
      answerCard: card,
      parses: parses
    };

    // 已考状态落库 + 清除进行中记录（列表悬浮栏随之消失）
    await ExamStore.saveFinished(report);
    await ExamStore.clearProgress();

    // 归档到学习数据
    await StudyRecordStore.add({
      id: StudyRecordStore.newId(),
      type: 'exam',
      title: this.paperTitle !== '' ? this.paperTitle : '模拟考试',
      score: `${score}分`,
      date: report.submitTime,
      timestamp: Date.now(),
      detailData: JSON.stringify(report)
    } as StudyRecord);

    // replaceUrl：回退直接到列表，不残留答题页
    this.getUIContext().getRouter().replaceUrl({
      url: 'pages/ExamReportPage',
      params: { finished: report }
    });
  }

  // 选项样式：仅点击瞬时高亮，不显示对错
  private optionBorder(index: number): string {
    return index === this.selectedIndex ? '#2B57E5' : '#E5EAF2';
  }

  private optionBg(index: number): string {
    return index === this.selectedIndex ? '#EEF3FF' : '#FFFFFF';
  }

  private get currentQuestion(): ExamQuestion {
    return this.questions[this.currentIndex];
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
        .margin({top:12})
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
        // 顶部返回栏：标题 + 倒计时
        Row() {
          Text('‹')
            .fontSize(34.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A202C')
            .padding({ left: 16, right: 12, top: 4, bottom: 4 })
            .onClick(() => {
              this.goBack();
            })

          Text(this.paperTitle)
            .fontSize(18.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A202C')
            .margin({top:12})
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 收藏星标
          if (this.questions.length > 0) {
            Text(this.starred ? '★' : '☆')
              .fontSize(26.0)
              .fontColor(this.starred ? '#F5A623' : '#8A94A6')
              .padding({ left: 8, right: 6, top: 4, bottom: 4 })
              .onClick(() => {
                this.toggleStar();
              })

            // 答题卡入口：右上角胶囊按钮
            Text('答题卡')
              .fontSize(13.5)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2B57E5')
              .backgroundColor('#EEF3FF')
              .padding({ left: 11, right: 11, top: 6, bottom: 6 })
              .borderRadius(14)
              .margin({ right: 8 })
              .onClick(() => {
                this.confirmSubmit = false;
                this.sheetOpen = true;
              })
          }

          // 倒计时
          Text(this.formatRemain(this.remainSec))
            .fontSize(15.0)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.remainSec < 300 ? '#EF4444' : '#2B57E5')
            .padding({ left: 8, right: 16, top: 4, bottom: 4 })
        }
        .width('100%')
        .height(56)
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)
        .border({ width: { bottom: 1 }, color: '#F1F4F9' })

        // 空题库兜底
        if (this.questions.length === 0) {
          Column({ space: 10 }) {
            Text('暂无题目')
              .fontSize(17.0)
              .fontColor('#8A94A6')
          }
          .width('100%')
          .margin({top:12})
          .justifyContent(FlexAlign.Center)
        } else {
          // 主体：只展示题干与选项，不显示进度
          Scroll() {
            Column() {
              // 题干卡片
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

              // 选项列表
              Column({ space: 10 }) {
                ForEach(this.currentQuestion.options, (opt: string, idx: number) => {
                  this.OptionItem(idx)
                }, (opt: string, idx: number) => `${this.currentIndex}_${idx}_${opt}`)
              }
              .width('100%')

              Row()
                .width('100%')
                .height(40)
            }
            .padding({ left: 16, right: 16, top: 8 })
            .width('100%')
          }
          .layoutWeight(1)
          .enabled(!this.submitting)
        }

          // 底部按钮：上一题 / 下一题（末题=交卷），两个按钮同尺寸同圆角；
          // 不可用态用「浅灰底 + 中灰字」的平面样式，不再用发蓝的灰
          Row({ space: 12 }) {
            Button('上一题')
              .layoutWeight(1)
              .height(48)
              .fontSize(17.0)
              .fontWeight(FontWeight.Medium)
              .type(ButtonType.Capsule)
              .backgroundColor(this.currentIndex > 0 && !this.submitting ? Color.White : '#EFF2F7')
              .fontColor(this.currentIndex > 0 && !this.submitting ? '#3A4556' : '#8A94A6')
              .border({
                width: 1.2,
                color: this.currentIndex > 0 && !this.submitting ? '#DCE3EE' : '#DFE5EE'
              })
              .enabled(this.currentIndex > 0 && !this.submitting)
              .onClick(() => {
                this.gotoQuestion(this.currentIndex - 1);
              })

            Button(this.isLastQuestion ? '交卷' : '下一题')
              .layoutWeight(1)
              .height(48)
              .fontSize(17.0)
              .fontWeight(FontWeight.Bold)
              .type(ButtonType.Capsule)
              .backgroundColor(this.canSubmit ? '#2B57E5' : '#E7ECF4')
              .fontColor(this.canSubmit ? Color.White : '#8A94A6')
              .shadow(this.canSubmit ?
                { radius: 8, color: '#2E2B57E5', offsetY: 3 } :
                { radius: 0, color: Color.Transparent, offsetY: 0 })
              .enabled(!this.submitting)
              .onClick(() => {
                if (this.isLastQuestion) {
                  if (this.canSubmit) {
                    this.submitExam();
                  } else {
                    this.toast('本题还未作答，选择答案后即可交卷');
                  }
                } else {
                  this.gotoQuestion(this.currentIndex + 1);
                }
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 16 })
          .backgroundColor(Color.White)
          .border({ width: { top: 1 }, color: '#F1F4F9' })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA')

      // 交卷中遮罩
      if (this.submitting) {
        Column() {
          Column({ space: 14 }) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color(Color.White)
            Text('交卷中...')
              .fontSize(16.0)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
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

      // 答题卡底部面板（含遮罩）
      if (this.sheetOpen) {
        this.AnswerSheet()
      }
    }
    .width('100%')
    .height('100%')
  }

  // 答题卡格子配色：当前题=蓝底白字，已作答=浅蓝底蓝字，未作答=灰底灰字
  private sheetCellBg(i: number): string {
    if (i === this.currentIndex) {
      return '#2B57E5';
    }
    return this.answers[i] !== '' ? '#EEF3FF' : '#F1F4F9';
  }

  private sheetCellFg(i: number): string {
    if (i === this.currentIndex) {
      return '#FFFFFF';
    }
    return this.answers[i] !== '' ? '#2B57E5' : '#5A6B85';
  }

  // 答题卡底部面板：点题号直接跳到该题，支持提前交卷（有未答题需二次确认）
  @Builder
  AnswerSheet() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#29000000')
        .onClick(() => {
          this.sheetOpen = false;
          this.confirmSubmit = false;
        })

      // 面板
      Column() {
        Row() {
          Text('答题卡')
            .fontSize(17.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A202C')

          Blank()

          Text(`已答 ${this.questions.length - this.unansweredCount()}/${this.questions.length}`)
            .fontSize(14.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2B57E5')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.questions, (q: ExamQuestion, i: number) => {
            Text(`${i + 1}`)
              .fontSize(16.0)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.sheetCellFg(i))
              .width(42)
              .height(42)
              .textAlign(TextAlign.Center)
              .borderRadius(21)
              .backgroundColor(this.sheetCellBg(i))
              .margin({ right: 10, top: 12 })
              .onClick(() => {
                this.gotoQuestion(i);
                this.sheetOpen = false;
                this.confirmSubmit = false;
              })
          }, (q: ExamQuestion, i: number) => 'sheet' + i.toString())
        }
        .width('100%')

        // 图例
        Row({ space: 6 }) {
          Circle().width(8).height(8).fill('#2B57E5')
          Text('当前题').fontSize(12.0).fontColor('#8A94A6')
          Circle().width(8).height(8).fill('#A9C2FB').margin({ left: 12 })
          Text('已作答').fontSize(12.0).fontColor('#8A94A6')
          Circle().width(8).height(8).fill('#DDE3EE').margin({ left: 12 })
          Text('未作答').fontSize(12.0).fontColor('#8A94A6')
        }
        .width('100%')
        .margin({ top: 16 })
        .alignItems(VerticalAlign.Center)

        // 提前交卷：有未答题时首次点击仅提示，二次点击确认
        Row() {
          Text(this.unansweredCount() > 0 && !this.confirmSubmit
            ? `还有 ${this.unansweredCount()} 题未作答，点击确认交卷`
            : (this.confirmSubmit ? '再次点击，确认交卷' : '交卷'))
            .fontSize(17.0)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .height(48)
        .borderRadius(24)
        .linearGradient({
          angle: 90,
          colors: [['#4A8CF8', 0.0], ['#2B57E5', 1.0]]
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 16 })
        .onClick(() => {
          if (this.unansweredCount() > 0 && !this.confirmSubmit) {
            this.confirmSubmit = true;
            this.toast(`还有 ${this.unansweredCount()} 题未作答，再次点击确认交卷`);
            return;
          }
          this.sheetOpen = false;
          this.submitExam();
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 26 })
      .borderRadius({ topLeft: 20, topRight: 20 })
      .backgroundColor(Color.White)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}
