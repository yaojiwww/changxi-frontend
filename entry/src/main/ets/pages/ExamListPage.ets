// 模拟试卷列表页：Tab 筛选 + 试卷卡片 + 进行中考试悬浮栏
// 已考判定与进行中记录均来自 ExamStore（本地缓存）
import { ExamPaper, allPapers } from '../common/ExamData';
import { ExamStore, ExamProgress } from '../common/ExamStore';

// Tab 定义
const TABS: string[] = ['全部', '免费', '未考', '已考'];

@Entry
@ComponentV2
struct ExamListPage {
  @Local activeTab: number = 0;
  @Local papers: ExamPaper[] = [];
  @Local progress: ExamProgress | null = null;
  @Local barHidden: boolean = false;   // × 关闭悬浮栏：仅本次访问隐藏
  @Local remainSec: number = 0;        // 悬浮栏倒计时剩余秒

  private tickTimer: number = -1;

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      await ExamStore.init(context);
    }
    this.papers = allPapers();
    this.refresh();
    this.startTick();
  }

  // 返回列表页时刷新（交卷/续答后回来读最新状态）
  onPageShow(): void {
    this.refresh();
  }

  aboutToDisappear(): void {
    this.stopTick();
  }

  private refresh(): void {
    this.progress = ExamStore.getProgress();
    if (this.progress !== null) {
      const left: number = Math.floor((this.progress.deadline - Date.now()) / 1000);
      this.remainSec = left > 0 ? left : 0;
    } else {
      this.remainSec = 0;
      this.barHidden = false;
    }
  }

  // 悬浮栏每秒刷新倒计时
  private startTick(): void {
    this.stopTick();
    this.tickTimer = setInterval((): void => {
      if (this.progress !== null) {
        const left: number = Math.floor((this.progress.deadline - Date.now()) / 1000);
        this.remainSec = left > 0 ? left : 0;
      }
    }, 1000);
  }

  private stopTick(): void {
    if (this.tickTimer !== -1) {
      clearInterval(this.tickTimer);
      this.tickTimer = -1;
    }
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  // Tab 过滤后的试卷列表
  private get filteredPapers(): ExamPaper[] {
    const out: ExamPaper[] = [];
    for (let i = 0; i < this.papers.length; i++) {
      const p: ExamPaper = this.papers[i];
      if (this.activeTab === 1 && !p.isFree) {
        continue;
      }
      if (this.activeTab === 2 && ExamStore.isFinished(p.id)) {
        continue;
      }
      if (this.activeTab === 3 && !ExamStore.isFinished(p.id)) {
        continue;
      }
      out.push(p);
    }
    return out;
  }

  private switchTab(index: number): void {
    if (this.activeTab === index) {
      return;
    }
    this.activeTab = index;
  }

  // 进入答题页：已考跳成绩页，其余进答题页（进行中的自动续答）
  private enterPaper(paper: ExamPaper): void {
    if (ExamStore.isFinished(paper.id)) {
      const r = ExamStore.getFinished(paper.id);
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/ExamReportPage',
        params: { from: 'store', finished: r }
      });
      return;
    }
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/ExamAnswerPage',
      params: { paperId: paper.id }
    });
  }

  // 悬浮栏「继续考试」
  private continueExam(): void {
    if (this.progress === null) {
      return;
    }
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/ExamAnswerPage',
      params: { paperId: this.progress.paperId }
    });
  }

  // 剩余秒 → HH:mm:ss
  private formatRemain(sec: number): string {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    const p = (n: number): string => (n < 10 ? '0' + n : '' + n);
    return `${p(h)}:${p(m)}:${p(s)}`;
  }

  // 已答题数
  private answeredCount(p: ExamProgress): number {
    let n = 0;
    for (let i = 0; i < p.answers.length; i++) {
      if (p.answers[i] !== '') {
        n++;
      }
    }
    return n;
  }

  @Builder
  TabBar() {
    Row({ space: 10 }) {
      ForEach(TABS, (t: string, i: number) => {
        Row() {
          Text(t)
            .fontSize(15.0)
            .fontWeight(this.activeTab === i ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.activeTab === i ? '#2B57E5' : '#4A5568')
        }
        .padding({ left: 18, right: 18, top: 8, bottom: 8 })
        .borderRadius(18)
        .backgroundColor(this.activeTab === i ? '#DCEBFF' : '#EDF0F5')
        .onClick(() => {
          this.switchTab(i);
        })
      }, (t: string, i: number) => `${i}_${t}`)

    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  // 试卷卡片
  @Builder
  PaperCard(paper: ExamPaper) {
    Row({ space: 12 }) {
      Column({ space: 10 }) {
        Text(paper.title)
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          Text(`${paper.doneCount}人做过`)
            .fontSize(14.0)
            .fontColor('#8A94A6')

          if (paper.isFree) {
            Text('免费')
              .fontSize(12.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#22C55E')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(4)
              .border({ width: 1, color: '#22C55E' })
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 按钮：已考显示查看成绩，其余显示开始考试
      Row() {
        Text(ExamStore.isFinished(paper.id) ? '查看成绩' : '开始考试')
          .fontSize(15.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B57E5')
      }
      .padding({ left: 16, right: 16, top: 9, bottom: 9 })
      .borderRadius(18)
      .backgroundColor('#DCEBFF')
      .onClick(() => {
        this.enterPaper(paper);
      })
    }
    .width('100%')
    .padding(18)
    .borderRadius(16)
    .backgroundColor(Color.White)
    .margin({ left: 14, right: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部返回栏
        Row() {
          Text('‹')
            .fontSize(34.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A202C')
            .padding({ left: 16, right: 12, top: 4, bottom: 4 })
            .onClick(() => {
              this.goBack();
            })

          Text('模拟试卷')
            .fontSize(18.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A202C')
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)
        .border({ width: { bottom: 1 }, color: '#F1F4F9' })

        this.TabBar()

        if (this.filteredPapers.length === 0) {
          Column({ space: 10 }) {
            Text('暂无试卷')
              .fontSize(17.0)
              .fontColor('#8A94A6')
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
              ForEach(this.filteredPapers, (p: ExamPaper) => {
                this.PaperCard(p)
              }, (p: ExamPaper) => `${p.id}_${ExamStore.isFinished(p.id)}`)

              // 底部留白，避免悬浮栏遮挡
              Row()
                .width('100%')
                .height(this.progress !== null && !this.barHidden ? 90 : 20)
            }
            .width('100%')
            .padding({ top: 12 })
          }
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA')

      // 底部悬浮栏：存在进行中考试且未被 × 关闭时显示
      if (this.progress !== null && !this.barHidden) {
        Row({ space: 10 }) {
          Text('×')
            .fontSize(25.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A202C')
            .padding({ left: 4, right: 4, top: 4, bottom: 4 })
            .onClick(() => {
              this.barHidden = true;
            })

          Column({ space: 4 }) {
            Text(this.progress!.paperTitle)
              .fontSize(15.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A202C')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')

            Row({ space: 14 }) {
              Text() {
                Span('答题进度 ').fontColor('#FFFFFF').fontSize(15.0)
                  .fontWeight(FontWeight.Bold)
                  .padding({  bottom: 15 ,left:15})
                Span(`${this.answeredCount(this.progress!)}/${this.progress!.answers.length}`)
                  .fontColor('#2B57E5').fontSize(14.0).fontWeight(FontWeight.Bold)
              }

              Text(this.formatRemain(this.remainSec))
                .fontSize(15.0)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
            }
            .padding({  bottom: 15 })
            .width('100%')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Row() {
            Text('继续考试')
              .fontSize(15.0)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .borderRadius(20)
          .linearGradient({
            angle: 90,
            colors: [['#4A8CF8', 0.0], ['#2B57E5', 1.0]]
          })
          .onClick(() => {
            this.continueExam();
          })
        }
        .width('92%')
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        .borderRadius(16)
        .backgroundColor('#E6999999')
        .margin({ bottom: 16 })
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
