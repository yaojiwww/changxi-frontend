// 意见反馈页：5 道小题的问卷（4 道单选 + 1 道开放建议），提交后存本地
// 说明：后端暂无反馈接口，先走 FeedbackStore 落盘；接后端时只需改 store，不动本页
import { FeedbackStore } from '../common/FeedbackStore';

// 单选题定义：标题 + 选项（选中即以选项文案作为答案提交）
interface ChoiceQuestion {
  title: string;
  options: string[];
}

// 问卷内容（想调整题目/选项时只改这里）
const QUESTIONS: ChoiceQuestion[] = [
  {
    title: '整体使用感受',
    options: ['非常满意', '满意', '一般', '不太满意', '很不满意']
  },
  {
    title: '界面与操作是否顺手',
    options: ['很顺手', '比较顺手', '一般', '不太顺手', '很不顺手']
  },
  {
    title: '刷题对掌握知识点有没有帮助',
    options: ['帮助很大', '有一些帮助', '一般', '帮助较小', '完全没有帮助']
  },
  {
    title: '对通过考试有没有帮助',
    options: ['很有帮助', '有一定帮助', '说不好', '帮助不大', '完全没有帮助']
  }
];

// 第 5 题（开放建议，选填）的题干
const SUGGEST_TITLE: string = '还想对我们说什么？（选填）';

@Entry
@ComponentV2
struct FeedbackPage {
  // 前 4 题的选中项（按题序），空串表示未作答
  @Local picks: string[] = ['', '', '', ''];
  // 第 5 题开放建议文本
  @Local suggest: string = '';
  @Local submitting: boolean = false;
  // 提交成功后切换为感谢页
  @Local done: boolean = false;

  async aboutToAppear(): Promise<void> {
    // 不依赖「我的」页先初始化：从任何入口进来都先按当前账号把答卷读出来
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      await FeedbackStore.init(context);
    }
    // 回显上次答卷：允许修改后再提交一份，不用从零重填
    const last = FeedbackStore.latest();
    if (last !== undefined) {
      for (let i = 0; i < QUESTIONS.length && i < last.answers.length; i++) {
        const ans: string = last.answers[i];
        if (QUESTIONS[i].options.includes(ans)) {
          this.picks[i] = ans;
        }
      }
      if (last.answers.length > QUESTIONS.length) {
        this.suggest = last.answers[QUESTIONS.length];
      }
    }
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  // 提交：前 4 题必答，第 5 题选填；答案按题序拼一份列表落盘
  private async doSubmit(): Promise<void> {
    for (let i = 0; i < this.picks.length; i++) {
      if (this.picks[i] === '') {
        this.toast(`请先完成第 ${i + 1} 题`);
        return;
      }
    }
    const answers: string[] = this.picks.slice();
    answers.push(this.suggest.trim());
    this.submitting = true;
    await FeedbackStore.add(answers);
    this.submitting = false;
    this.done = true;
  }

  build() {
    Column() {
      // 顶部返回栏（与账号与设置页一致）
      Row() {
        Text('‹')
          .fontSize(34.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#55402F')
          .padding({ left: 16, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text('意见反馈')
          .fontSize(19.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F2ECD8' })

      if (this.done) {
        // 提交成功：致谢 + 返回
        this.DoneView()
      } else {
        Scroll() {
          Column({ space: 14 }) {
            // 说明卡片：讲清目的，降低乱填概率
            Column({ space: 6 }) {
              Text('花 1 分钟填个小问卷')
                .fontSize(17.0)
                .fontWeight(FontWeight.Bold)
                .fontColor('#55402F')
              Text('想了解你用得顺不顺手，以及刷题对备考有没有帮助，帮我们做得更好。')
                .fontSize(13.0)
                .fontColor('#9A8A6E')
                .lineHeight(20)
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 16, bottom: 16 })
            .borderRadius(16)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#F2ECD8' })

            // 前 4 题：单选（选项 chip），选中高亮
            ForEach(QUESTIONS, (q: ChoiceQuestion, i: number) => {
              this.ChoiceCard(q, i)
            }, (q: ChoiceQuestion, i: number) => `${i}_${q.title}`)

            // 第 5 题：开放建议（选填）
            Column({ space: 10 }) {
              Row({ space: 8 }) {
                Text('Q5')
                  .fontSize(12.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E4842A')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .borderRadius(8)
                  .backgroundColor('#FEF8E3')

                Text(SUGGEST_TITLE)
                  .fontSize(15.5)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#55402F')
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              TextArea({ placeholder: '最喜欢的功能、最想改进的地方…', text: this.suggest })
                .width('100%')
                .height(110)
                .fontSize(14.0)
                .fontColor('#55402F')
                .placeholderColor('#B5A98D')
                .backgroundColor('#FDFDED')
                .borderRadius(12)
                .border({ width: 1, color: '#F2ECD8' })
                .padding(12)
                .onChange((v: string) => {
                  this.suggest = v;
                })
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 16, bottom: 16 })
            .borderRadius(16)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#F2ECD8' })

            // 提交按钮（与登录页主按钮同款）
            Button(this.submitting ? '提交中…' : '提交反馈')
              .width('100%')
              .height(52)
              .borderRadius(26)
              .backgroundColor('#FBDE71')
              .fontColor('#8A7A50')
              .fontSize(18.0)
              .fontWeight(FontWeight.Medium)
              .margin({ top: 6, bottom: 24 })
              .enabled(!this.submitting)
              .shadow({ radius: 10, color: '#14000000', offsetY: 4 })
              .onClick(() => {
                this.doSubmit();
              })
          }
          .padding({ left: 16, right: 16, top: 14 })
          .width('100%')
        }
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }

  // 提交成功页
  @Builder
  DoneView() {
    Column({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(72)
          .height(72)
          .fill('#FBDE71')
        Text('✓')
          .fontSize(36.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .margin({ top: 90 })

      Text('提交成功')
        .fontSize(20.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#55402F')

      Text('感谢你的反馈，我们会持续改进')
        .fontSize(14.0)
        .fontColor('#9A8A6E')

      Button('返回')
        .width(200)
        .height(48)
        .borderRadius(24)
        .backgroundColor('#FBDE71')
        .fontColor('#8A7A50')
        .fontSize(16.0)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20 })
        .onClick(() => {
          this.getUIContext().getRouter().back();
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Start)
  }

  // 单选题卡片：题号 + 题干 + 选项 chip（选中高亮，点选即答）
  @Builder
  ChoiceCard(q: ChoiceQuestion, index: number) {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text(`Q${index + 1}`)
          .fontSize(12.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E4842A')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
          .backgroundColor('#FEF8E3')

        Text(q.title)
          .fontSize(15.5)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(q.options, (opt: string) => {
          Text(opt)
            .fontSize(14.0)
            .fontWeight(this.picks[index] === opt ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.picks[index] === opt ? '#8A7A50' : '#9A8A6E')
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .borderRadius(16)
            .backgroundColor(this.picks[index] === opt ? '#FBDE71' : '#FDFDED')
            .border({
              width: 1,
              color: this.picks[index] === opt ? '#FBDE71' : '#E8DCB8'
            })
            .margin({ right: 10, top: 8 })
            .onClick(() => {
              this.picks[index] = opt;
            })
        }, (opt: string) => `${index}_${opt}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 16, bottom: 16 })
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#F2ECD8' })
  }
}
