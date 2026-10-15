// 练习报告页：数据全部来自 POST /practice/batch-submit 的返回，前端不自算
// 答题页交卷成功后通过路由 params 传入报告；无数据时提示缺失，不做二次请求
import { PracticeReport, AnswerCardCell, KnowledgeMastery } from '../api/PracticeApi';

// 路由参数
export interface PracticeReportParams {
  itemId: string;
  itemName: string;
  report: PracticeReport;
  history?: boolean;  // 学习数据回看模式：隐藏再练一次等操作
}

@Entry
@ComponentV2
struct PracticeReportPage {
  @Local itemId: string = '';
  @Local itemName: string = '';
  @Local report: PracticeReport | null = null;
  @Local history: boolean = false;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as PracticeReportParams | undefined;
    if (params !== undefined) {
      this.itemId = params.itemId;
      this.itemName = params.itemName;
      if (params.report !== undefined && params.report !== null) {
        this.report = params.report;
      }
      if (params.history === true) {
        this.history = true;
      }
    }
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  // 耗时显示：秒 → X分X秒
  private formatDuration(seconds: number): string {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return m > 0 ? `${m}分${s}秒` : `${s}秒`;
  }

  // 正确率百分比数值 → 带 % 字符串，null 显示 --
  private formatAccValue(v: number | null): string {
    if (v === null || v === undefined) {
      return '--';
    }
    return `${v}%`;
  }

  // 正确率。接口未给（null）时显示 --
  private formatAccuracy(r: PracticeReport): string {
    return this.formatAccValue(r.accuracy);
  }

  // 变化量：正数带 +，null 显示 --
  private formatDelta(delta: number | null): string {
    if (delta === null || delta === undefined) {
      return '--';
    }
    return delta > 0 ? `+${delta}%` : `${delta}%`;
  }

  private deltaColor(delta: number | null): string {
    if (delta === null || delta === undefined) {
      return '#8A94A6';
    }
    if (delta > 0) {
      return '#22C55E';
    }
    if (delta < 0) {
      return '#EF4444';
    }
    return '#8A94A6';
  }

  // compare 可能为 null（每日一练演示报告/首次练习无历史数据），
  // 直接链式取 compare.lastAccuracy 会崩页，必须先判空
  private hasCompare(): boolean {
    const r = this.report;
    return r !== null && r.compare !== null && r.compare !== undefined;
  }

  // mastery 可能缺失（个别历史记录字段不全），缺失时隐藏知识点区块
  private hasMastery(): boolean {
    const r = this.report;
    return r !== null && r.mastery !== undefined && r.mastery !== null && r.mastery.length > 0;
  }

  // 统计卡片
  @Builder
  StatCell(label: string, value: string, valueColor: string) {
    Column({ space: 6 }) {
      Text(value)
        .fontSize(21.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(valueColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(label)
        .fontSize(13.0)
        .fontColor('#8A94A6')
    }
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
    .alignItems(HorizontalAlign.Center)
  }

  // 数据对比行
  @Builder
  CompareRow(label: string, value: string, valueColor: string) {
    Row() {
      Text(label)
        .fontSize(15.0)
        .fontColor('#4A5568')
        .layoutWeight(1)
      Text(value)
        .fontSize(16.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(valueColor)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  // 答题卡格子（自动换行：每行 5 个，题多时向下排列）
  @Builder
  AnswerCell(cell: AnswerCardCell, index: number) {
    Column({ space: 4 }) {
      Text(`${index + 1}`)
        .fontSize(16.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
      Text(cell.correct ? '对' : '错')
        .fontSize(11.0)
        .fontColor(Color.White)
    }
    .width('18%')
    .height(52)
    .margin({ bottom: 8 })
    .borderRadius(10)
    .backgroundColor(cell.correct ? '#22C55E' : '#EF4444')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // 知识点掌握行
  @Builder
  MasteryRow(m: KnowledgeMastery) {
    Row() {
      Text(m.knowledgePoint)
        .fontSize(15.0)
        .fontColor('#1A202C')
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`${m.correct}/${m.total}`)
        .fontSize(14.0)
        .fontColor('#8A94A6')
        .margin({ left: 10 })

      Text(`${m.accuracy}%`)
        .fontSize(15.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(m.accuracy >= 60 ? '#22C55E' : '#EF4444')
        .width(56)
        .textAlign(TextAlign.End)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
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
            this.goBack();
          })

        Text('练习报告')
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

      if (this.report === null) {
        // 无报告数据：不发二次请求，直接提示并返回
        Column({ space: 14 }) {
          Text('报告数据缺失')
            .fontSize(17.0)
            .fontColor('#8A94A6')
          Text('返回')
            .fontSize(16.0)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ left: 30, right: 30, top: 10, bottom: 10 })
            .borderRadius(20)
            .linearGradient({
              angle: 90,
              colors: [['#4A8CF8', 0.0], ['#2B57E5', 1.0]]
            })
            .onClick(() => {
              this.goBack();
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        this.ReportBody();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  // 报告正文。所有取值直接读 report，不做任何计算
  @Builder
  ReportBody() {
    Scroll() {
      Column() {
        // 头部：练习类型 + 知识条目 + 交卷时间
        Column({ space: 8 }) {
          Text(this.report!.practiceType)
            .fontSize(14.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#DCE7FF')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(10)
            .backgroundColor('#33FFFFFF')

          Text(this.report!.itemName !== '' ? this.report!.itemName : this.itemName)
            .fontSize(21.0)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`交卷时间 ${this.report!.submitTime}`)
            .fontSize(14.0)
            .fontColor('#DCE7FF')
        }
        .width('100%')
        .padding(18)
        .borderRadius(16)
        .linearGradient({
          angle: 135,
          colors: [['#4A8CF8', 0.0], ['#2B57E5', 1.0]]
        })
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 14 })

        // 核心指标
        Row() {
          this.StatCell('答对题数', `${this.report!.correctCount}/${this.report!.total}`, '#1A202C')
          Divider().vertical(true).height(36).color('#E5EAF2')
          this.StatCell('正确率', this.formatAccuracy(this.report!), '#2B57E5')
          Divider().vertical(true).height(36).color('#E5EAF2')
          this.StatCell('练习时长', this.formatDuration(this.report!.duration), '#1A202C')
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(16)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 14 })

        // 数据对比（无历史数据时显示占位提示）
        if (this.hasCompare()) {
          Text('数据对比')
            .fontSize(17.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A202C')
            .width('100%')
            .margin({ bottom: 10 })

          Column() {
            this.CompareRow('上次练习正确率', this.formatAccValue(this.report!.compare.lastAccuracy), '#1A202C')
            Divider().width('100%').height(1).color('#F1F4F9')
            this.CompareRow('较上次', this.formatDelta(this.report!.compare.deltaVsLast),
              this.deltaColor(this.report!.compare.deltaVsLast))
            Divider().width('100%').height(1).color('#F1F4F9')
            this.CompareRow('较合格线(60%)', this.formatDelta(this.report!.compare.deltaVsPassLine),
              this.deltaColor(this.report!.compare.deltaVsPassLine))
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderRadius(16)
          .margin({ bottom: 14 })
        } else {
          Text('本次记录暂无历史对比，完成下一次练习后自动生成')
            .fontSize(13.0)
            .fontColor('#9AA7BC')
            .width('100%')
            .padding(14)
            .borderRadius(14)
            .backgroundColor(Color.White)
            .margin({ bottom: 14 })
        }

        // 答题卡
        Text('答题卡')
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .width('100%')
          .margin({ bottom: 10 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.report!.answerCard, (cell: AnswerCardCell, idx: number) => {
            this.AnswerCell(cell, idx)
          }, (cell: AnswerCardCell, idx: number) => `${idx}_${cell.questionId}`)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .margin({ bottom: 14 })

        // 知识点掌握（字段缺失时整块隐藏）
        if (this.hasMastery()) {
          Text('知识点掌握')
            .fontSize(17.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A202C')
            .width('100%')
            .margin({ bottom: 10 })

          Column() {
            ForEach(this.report!.mastery, (m: KnowledgeMastery, idx: number) => {
              this.MasteryRow(m)
              if (idx < this.report!.mastery.length - 1) {
                Divider().width('100%').height(1).color('#F1F4F9')
              }
            }, (m: KnowledgeMastery, idx: number) => `${idx}_${m.knowledgePoint}`)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderRadius(16)
          .margin({ bottom: 14 })
        }

        // 查看错题解析：暂未开放，置灰
        Row() {
          Text('查看错题解析')
            .fontSize(16.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#A0AEC0')
        }
        .width('100%')
        .height(46)
        .borderRadius(23)
        .backgroundColor('#E2E8F0')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.toast('该功能暂未开放');
        })

        Row()
          .width('100%')
          .height(40)
      }
      .padding(16)
      .width('100%')
    }
    .layoutWeight(1)
  }
}
