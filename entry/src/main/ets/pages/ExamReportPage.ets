// 模拟考试成绩报告页：复用练习报告基础 UI（头部渐变卡/大圆圈分数/答题卡）
// 与练习报告差异：无知识点掌握、无数据对比；答题卡下新增「试卷解析」
// 新增：AI 评估结果（前端根据得分/正确率/用时生成分档评语）+「向 AI 提问」跳首页 AI 伴学页签
// 数据来源：交卷时生成的 ExamFinished 快照，或列表页「查看成绩」传入的已考记录
import { ExamFinished, ExamParseItem, ExamAnswerCell } from '../common/ExamStore';
import { ExamQuestion, questionsOf } from '../common/ExamData';
import { signalPendingTab } from '../common/NavSignal';
import { signalAskQuestion } from '../common/AIAsk';

// 路由参数
export interface ExamReportParams {
  finished: ExamFinished;
  history?: boolean;  // 学习数据回看模式：隐藏重新考试等操作
}

@Entry
@ComponentV2
struct ExamReportPage {
  @Local report: ExamFinished | null = null;
  @Local history: boolean = false;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as ExamReportParams | undefined;
    if (params !== undefined && params.finished !== undefined && params.finished !== null) {
      this.report = params.finished;
    }
    if (params !== undefined && params.history === true) {
      this.history = true;
    }
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  // 秒 → X分X秒
  private formatDuration(seconds: number): string {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return m > 0 ? `${m}分${s}秒` : `${s}秒`;
  }

  // 大圆圈内分数文字
  private scoreText(r: ExamFinished): string {
    return `${r.score}`;
  }

  // ===== AI 评估（本地生成，后端接入后替换为接口返回） =====

  // 得分分档
  private evalLevel(score: number): string {
    if (score >= 90) {
      return '优秀';
    }
    if (score >= 80) {
      return '良好';
    }
    if (score >= 60) {
      return '合格';
    }
    return '待提升';
  }

  // 分档评语 + 薄弱提示
  private evalText(r: ExamFinished): string {
    const wrong: number = r.total - r.correctCount;
    let s: string = '';
    if (r.score >= 90) {
      s = '整体掌握扎实，本次成绩已达到优秀水平，可以保持当前学习节奏，考前回顾一遍错题即可。';
    } else if (r.score >= 80) {
      s = '整体掌握较好，失分集中在少数题目。建议针对本次错题做巩固练习，并让 AI 讲解其中易混淆的知识点。';
    } else if (r.score >= 60) {
      s = '基本达到及格线，但仍有明显薄弱环节。建议优先复习错题涉及的知识点，再进入错题本重做加深记忆。';
    } else {
      s = '本次成绩未达预期，不要气馁：先从错题解析入手理解考点，再到「AI 知识库」系统学习对应章节，几天后重新模拟检验效果。';
    }
    if (wrong > 0) {
      s += `本次共 ${wrong} 道错题，已自动收入错题本，可以直接去重做。`;
    } else {
      s += '全部答对，非常棒！继续保持。';
    }
    return s;
  }

  // 跳转 AI 伴学：回首页并切到 AI 页签（首页 onPageShow 消费 pendingTab）
  private goAskAI(): void {
    signalPendingTab(1);
    this.getUIContext().getRouter().back({ url: 'pages/HomePage' });
  }

  // 按题号找回原题（题干/选项）；本地模拟卷直接查 ExamData，查不到时退回题号描述
  private questionOf(questionId: string): ExamQuestion | null {
    if (this.report === null) {
      return null;
    }
    const list: ExamQuestion[] = questionsOf(this.report.paperId);
    for (let i = 0; i < list.length; i++) {
      if (list[i].questionId === questionId) {
        return list[i];
      }
    }
    return null;
  }

  // 点答题卡/解析条目：把这道题带进 AI 伴学输入框
  private askAbout(questionId: string, index: number, userAnswer: string, correctOption: string): void {
    if (this.report === null) {
      return;
    }
    const q: ExamQuestion | null = this.questionOf(questionId);
    signalAskQuestion({
      stem: q !== null ? q.stem : `模拟试卷《${this.report.paperTitle}》第 ${index + 1} 题`,
      options: q !== null ? q.options : [],
      userAnswer: userAnswer,
      correctAnswer: correctOption,
      knowledgePoint: this.report.paperTitle
    });
    this.goAskAI();
  }

  @Builder
  AnswerCell(cell: ExamAnswerCell, index: number) {
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
    .backgroundColor(cell.correct ? '#2E9E63' : '#D9534F')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.askAbout(cell.questionId, index, cell.userAnswer, cell.correctOption);
    })
  }

  // 试卷解析条目：答错题的题干 + 你的答案 + 正确答案 + 解析
  @Builder
  ParseItem(item: ExamParseItem, index: number) {
    Column({ space: 8 }) {
      Text(item.stem)
        .fontSize(16.0)
        .fontWeight(FontWeight.Medium)
        .fontColor('#55402F')
        .lineHeight(24)
        .width('100%')

      Row({ space: 16 }) {
        Text() {
          Span('你的答案 ').fontSize(14.0).fontColor('#9A8A6E')
          Span(item.userAnswer).fontSize(14.0).fontWeight(FontWeight.Bold).fontColor('#D9534F')
        }

        Text() {
          Span('正确答案 ').fontSize(14.0).fontColor('#9A8A6E')
          Span(item.correctOption).fontSize(14.0).fontWeight(FontWeight.Bold).fontColor('#2E9E63')
        }
      }
      .width('100%')

      Text(item.explanation)
        .fontSize(14.0)
        .fontColor('#9A8A6E')
        .lineHeight(20)
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#FFFFFF')
        .borderRadius(10)

      // 整条可点：带着这道题去 AI 伴学
      Row({ space: 5 }) {
        Text('问 AI 讲解这道题')
          .fontSize(13.5)
          .fontWeight(FontWeight.Medium)
          .fontColor('#E4842A')
        Text('›')
          .fontSize(17.0)
          .fontColor('#E4842A')
      }
      .width('100%')
      .margin({ top: 2 })
      .onClick(() => {
        this.askAbout(item.questionId, index, item.userAnswer, item.correctOption);
      })
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      // 顶部返回栏
      Row() {
        Text('‹')
          .fontSize(34.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#55402F')
          .padding({ left: 16, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.goBack();
          })

        Text('模拟考试成绩')
          .fontSize(18.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F2ECD8' })

      if (this.report === null) {
        // 无报告数据：提示并返回，不做二次请求
        Column({ space: 14 }) {
          Text('报告数据缺失')
            .fontSize(17.0)
            .fontColor('#9A8A6E')
          Text('返回')
            .fontSize(16.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8A7A50')
            .padding({ left: 30, right: 30, top: 10, bottom: 10 })
            .borderRadius(20)
            .backgroundColor('#FBDE71')
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
    .backgroundColor('#FDFDED')
  }

  @Builder
  ReportBody() {
    Scroll() {
      Column() {
        // 头部渐变卡：试卷名 + 大圆圈分数 + 交卷时间
        Column({ space: 10 }) {
          Text(this.report!.paperTitle)
            .fontSize(21.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8A7A50')
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 大圆圈分数：Progress(Ring) + 中心分数文字
          Stack({ alignContent: Alignment.Center }) {
            Progress({ value: this.report!.score, total: 100, type: ProgressType.Ring })
              .width(130)
              .height(130)
              .color('#8A7A50')
              .style({ strokeWidth: 10 })
              .backgroundColor('#33FFFFFF')

            Column({ space: 2 }) {
              Text(this.scoreText(this.report!))
                .fontSize(39.0)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8A7A50')
              Text('总分值')
                .fontSize(13.0)
                .fontColor('#55402F')
            }
          }
          .width(130)
          .height(130)
          .margin({ top: 4, bottom: 4 })

          Text(`交卷时间 ${this.report!.submitTime}`)
            .fontSize(14.0)
            .fontColor('#55402F')
        }
        .width('100%')
        .padding(18)
        .borderRadius(16)
        .backgroundColor('#FEF8E3')
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 14 })

        // 练习时长 + 答对/总分统计
        Row() {
          Column({ space: 6 }) {
            Text(this.formatDuration(this.report!.duration))
              .fontSize(21.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#55402F')
            Text('练习时长')
              .fontSize(13.0)
              .fontColor('#9A8A6E')
          }
          .layoutWeight(1)
          .padding({ top: 14, bottom: 14 })
          .alignItems(HorizontalAlign.Center)

          Divider().vertical(true).height(36).color('#FEF8E3')

          Column({ space: 6 }) {
            Text(`${this.report!.correctCount}/${this.report!.total}`)
              .fontSize(21.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E4842A')
            Text('答对题数')
              .fontSize(13.0)
              .fontColor('#9A8A6E')
          }
          .layoutWeight(1)
          .padding({ top: 14, bottom: 14 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(16)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 14 })

        // AI 评估结果：分档徽章 + 评语 + 向 AI 提问入口
        Column({ space: 12 }) {
          Row({ space: 8 }) {
            Text('AI 评估结果')
              .fontSize(17.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#55402F')

            Text(this.evalLevel(this.report!.score))
              .fontSize(12.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#8A7A50')
              .backgroundColor(this.report!.score >= 60 ? '#E4842A' : '#FBDE71')
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .borderRadius(8)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.evalText(this.report!))
            .fontSize(14.5)
            .fontColor('#9A8A6E')
            .lineHeight(22)
            .width('100%')

          // 向 AI 提问：返回首页并切到 AI 伴学页签
          Row({ space: 6 }) {
            Text('向 AI 提问，解答本次考试的薄弱点')
              .fontSize(14.5)
              .fontWeight(FontWeight.Medium)
              .fontColor('#E4842A')
              .layoutWeight(1)

            Text('›')
              .fontSize(19.0)
              .fontColor('#E4842A')
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .borderRadius(12)
          .backgroundColor('#FEF8E3')
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.goAskAI();
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 14 })

        // 答题卡
        Text('答题卡')
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .width('100%')
          .margin({ bottom: 10 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.report!.answerCard, (cell: ExamAnswerCell, idx: number) => {
            this.AnswerCell(cell, idx)
          }, (cell: ExamAnswerCell, idx: number) => `${idx}_${cell.questionId}`)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .margin({ bottom: 14 })

        // 试卷解析：答错题逐条展示（无错题时提示）
        Text('试卷解析')
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .width('100%')
          .margin({ bottom: 10 })

        if (this.report!.parses.length === 0) {
          Column({ space: 8 }) {
            Text('全部答对，没有需要解析的错题')
              .fontSize(15.0)
              .fontColor('#9A8A6E')
          }
          .width('100%')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 14 })
        } else {
          Column() {
            ForEach(this.report!.parses, (item: ExamParseItem, idx: number) => {
              this.ParseItem(item, idx)
              if (idx < this.report!.parses.length - 1) {
                Divider().width('100%').height(1).color('#F8F4E8')
              }
            }, (item: ExamParseItem, idx: number) => `${idx}_${item.questionId}`)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderRadius(16)
          .margin({ bottom: 14 })
        }

        // 返回列表
        Row() {
          Text('返回列表')
            .fontSize(17.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8A7A50')
        }
        .width('100%')
        .height(48)
        .borderRadius(24)
        .backgroundColor('#FBDE71')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.goBack();
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
