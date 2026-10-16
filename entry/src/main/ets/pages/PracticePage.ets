// 知识点练习页：首页「基础知识/专业知识」列表点击某个知识点跳入。
// 题目来自题库：PracticeApi 按 kpId 抽题、逐题判题并下发解析（mock 阶段读 common/QuestionBank 的本地题库）。
// 取数、判题、收藏、错题入库都在 viewmodel/PracticeViewModel.ets，页面只负责渲染与跳转。
// 该知识点暂无题库时显示占位页（路由与入口已接通，题库补齐后自动可用）。
import { PracticeViewModel } from '../viewmodel/PracticeViewModel';

interface PracticeParams {
  topicId?: number;
  topicName?: string;
}

// 选项字母：与 options 数组下标一一对应
const KEYS: string[] = ['A', 'B', 'C', 'D'];

@Entry
@ComponentV2
struct Practice {
  @Local vm: PracticeViewModel = new PracticeViewModel();
  @Local pageTitle: string = '知识点练习';
  @Local topicId: number = 0;

  private plans: string[] = [
    '按知识点分类刷题',
    '题目由后端题库按 kp_id 抽取',
    '作答后即时判题并展示解析',
    '练完自动生成练习报告'
  ];

  async aboutToAppear(): Promise<void> {
    const params = this.getUIContext().getRouter().getParams() as PracticeParams | undefined;
    if (params !== undefined) {
      if (params.topicId !== undefined) {
        this.topicId = params.topicId;
      }
      if (params.topicName !== undefined && params.topicName !== '') {
        this.pageTitle = params.topicName;
      }
    }
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    try {
      await this.vm.init(ctx, this.pageTitle);
    } catch (err) {
      this.toast((err as Error).message);
    }
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
  }

  // 选答：判题与解析走 ViewModel，失败提示
  private async onPick(key: string): Promise<void> {
    try {
      await this.vm.pick(key);
    } catch (err) {
      this.toast((err as Error).message);
    }
  }

  private async onNext(): Promise<void> {
    if (!this.vm.answered()) {
      this.toast('请先选择答案');
      return;
    }
    await this.vm.next();
  }

  private async onStar(): Promise<void> {
    const wasStarred: boolean = this.vm.starred;
    try {
      await this.vm.toggleStar();
      this.toast(wasStarred ? '已取消收藏' : '已加入收藏');
    } catch (err) {
      this.toast((err as Error).message);
    }
  }

  build() {
    Column() {
      // 顶部返回栏
      Row() {
        Text('‹')
          .fontSize(34.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A202C')
          .padding({ left: 16, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text(this.pageTitle)
          .fontSize(18.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.vm.hasBank) {
          // 收藏星标
          Text(this.vm.starred ? '★' : '☆')
            .fontSize(24.0)
            .fontColor(this.vm.starred ? '#F5A623' : '#B9C2D0')
            .padding({ left: 2, right: 2 })
            .onClick(() => {
              this.onStar();
            })

          Text((this.vm.cur + 1).toString() + '/' + this.vm.total.toString())
            .fontSize(14.0)
            .fontColor('#8A94A6')
            .padding({ right: 16 })
        } else {
          Blank().width(16)
        }
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F1F4F9' })

      if (this.vm.hasBank) {
        this.QuizView()
      } else {
        this.PlaceholderView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  // ==================== 答题视图 ====================
  // 注意：Scroll 内容默认垂直居中，必须显式 .align(Alignment.Top) 顶对齐
  @Builder
  QuizView() {
    Column() {
      // 进度条（按知识点真实题库总数计算）
      Stack({ alignContent: Alignment.Start }) {
        Row().width('100%').height(4).borderRadius(2).backgroundColor('#E8EDF5')
        Row()
          .width(this.vm.progressPct() + '%')
          .height(4)
          .borderRadius(2)
          .backgroundColor('#3B6BF6')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })

      Scroll() {
        Column() {
          if (this.vm.done) {
            this.DoneCard()
          } else {
            // 题干卡
            Column({ space: 10 }) {
              Text(this.vm.kpName)
                .fontSize(12.0)
                .fontColor('#3B6BF6')
                .backgroundColor('#EAF0FF')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .borderRadius(6)

              Text(this.vm.stemText())
                .fontSize(17.5)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A202C')
                .lineHeight(26)
            }
            .width('100%')
            .padding(16)
            .borderRadius(16)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#EEF2F6' })
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 12 })

            // 选项列表
            ForEach(this.vm.optionList(), (opt: string, i: number) => {
              this.OptionRow(opt, i)
            }, (opt: string, i: number) => this.vm.cur.toString() + '-' + i.toString() + '-' + opt)

            // 解析（作答后出现）
            if (this.vm.judged()) {
              this.AnalysisCard()
            }
          }
        }
        .padding({ left: 16, right: 16, bottom: 20 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)

      // 底部按钮：上一题 / 下一题 各占一半
      Row({ space: 12 }) {
        Button('上一题')
          .layoutWeight(1)
          .height(48)
          .fontSize(17.0)
          .type(ButtonType.Capsule)
          .backgroundColor(Color.White)
          .fontColor(this.vm.cur === 0 && !this.vm.done ? '#8A94A6' : '#3A4556')
          .border({ width: 1, color: '#D8DFEA' })
          .enabled(this.vm.cur > 0 || this.vm.done)
          .onClick(() => {
            this.vm.prev();
          })

        Button(this.vm.done ? '已完成' : (this.vm.isLast() ? '完成练习' : '下一题'))
          .layoutWeight(1)
          .height(48)
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .type(ButtonType.Capsule)
          .backgroundColor(this.vm.answered() ? '#3B6BF6' : '#E7ECF4')
          .fontColor(this.vm.answered() ? Color.White : '#8A94A6')
          .enabled(!this.vm.done)
          .onClick(() => {
            this.onNext();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#EEF2F6' })
    }
    .width('100%')
    .layoutWeight(1) // 占返回栏以外剩余高度；height('100%') 会把底栏挤出屏幕
  }

  @Builder
  OptionRow(opt: string, i: number) {
    Row({ space: 12 }) {
      // 判定后：正确选项显示绿色对勾圆标
      if (this.vm.judged() && KEYS[i] === this.vm.correctOption()) {
        Text('✓')
          .fontSize(16.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor('#0E9F6E')
      } else {
        Text(KEYS[i])
          .fontSize(15.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.vm.picked() === KEYS[i] ? '#3B6BF6' : '#5A6B85')
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor(this.vm.picked() === KEYS[i] ? '#EAF0FF' : '#F1F4F9')
      }

      Text(opt)
        .fontSize(15.5)
        .fontColor('#1A202C')
        .lineHeight(21)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(13)
    .borderRadius(14)
    .backgroundColor(this.vm.judged() && KEYS[i] === this.vm.correctOption() ? '#F0FAF5'
      : (this.vm.judged() && this.vm.picked() === KEYS[i] ? '#FFF6F6' : Color.White))
    .border({
      width: 1.5,
      color: this.vm.judged() && KEYS[i] === this.vm.correctOption() ? '#BFE8D2'
        : (this.vm.judged() && this.vm.picked() === KEYS[i] ? '#F2C1C1' : '#EEF2F6')
    })
    .margin({ bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onPick(KEYS[i]);
    })
  }

  // 单题解析卡：正确答案/我的作答 + 印章 + 解析文字
  @Builder
  AnalysisCard() {
    Column() {
      Row() {
        Column({ space: 5 }) {
          Text(this.vm.correctOption())
            .fontSize(21.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0E9F6E')
          Text('正确答案')
            .fontSize(13.0)
            .fontColor('#8A94A6')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(34)
          .color('#EEF2F6')

        Column({ space: 5 }) {
          Text(this.vm.picked())
            .fontSize(21.0)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.vm.isCorrect() ? '#0E9F6E' : '#E5484D')
          Text('我的作答')
            .fontSize(13.0)
            .fontColor('#8A94A6')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Text(this.vm.isCorrect() ? '答对' : '答错')
          .fontSize(14.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.vm.isCorrect() ? '#0E9F6E' : '#E5484D')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(8)
          .border({
            width: 1.2,
            color: this.vm.isCorrect() ? '#0E9F6E' : '#E5484D'
          })
          .margin({ left: 14 })
      }
      .width('100%')
      .padding({ top: 14, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Divider().color('#F1F4F9').strokeWidth(1)

      Text('解析：' + this.vm.explanation())
        .fontSize(14.5)
        .fontColor('#3A4552')
        .lineHeight(21)
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#EEF2F6' })
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 4 })
  }

  // 完成卡：本章节的题做完
  @Builder
  DoneCard() {
    Column({ space: 14 }) {
      Text('本轮练习完成')
        .fontSize(20.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')

      Text('答对 ' + this.vm.correctCount().toString() + ' / ' + this.vm.count().toString() + ' 题')
        .fontSize(17.0)
        .fontWeight(FontWeight.Medium)
        .fontColor('#3B6BF6')

      Text('完成本知识点全部 ' + this.vm.total.toString() + ' 题需继续练习，题目会按掌握度智能推送。')
        .fontSize(14.0)
        .fontColor('#8A94A6')
        .lineHeight(21)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 32, bottom: 32 })
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#EEF2F6' })
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== 占位视图（暂无题库的知识点） ====================
  @Builder
  PlaceholderView() {
    Column() {
      Column() {
        Text('🚧')
          .fontSize(41.0)
      }
      .width(84)
      .height(84)
      .borderRadius(42)
      .backgroundColor('#EAF0FF')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 16 })

      Text('功能开发中')
        .fontSize(18.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
        .margin({ bottom: 8 })

      Text('本页为占位页面，路由与入口都已接通，功能开发完成后替换此文件内容即可。')
        .fontSize(14.0)
        .fontColor('#8A94A6')
        .lineHeight(21)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      Column() {
        Text('本页规划内容')
          .fontSize(14.5)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .width('100%')
          .margin({ bottom: 12 })

        ForEach(this.plans, (item: string, i: number) => {
          Row() {
            Text('•')
              .fontSize(14.0)
              .fontColor('#3B6BF6')
              .margin({ right: 8 })
            Text(item)
              .fontSize(14.0)
              .fontColor('#3A4552')
              .lineHeight(20)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .margin({ bottom: 9 })
        }, (item: string, i: number) => item + '_' + i)
      }
      .width('100%')
      .padding(16)
      .borderRadius(14)
      .backgroundColor(Color.White)
      .border({ width: 1, color: '#EEF2F6' })
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 14 })

      if (this.topicId > 0) {
        Text('已收到知识点 ID：' + this.topicId)
          .fontSize(13.0)
          .fontColor('#8A94A6')
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 20, right: 20, top: 48 })
    .justifyContent(FlexAlign.Start)
  }
}
