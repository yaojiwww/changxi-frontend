import { TrainingViewModel, TrainingStage } from '../../viewmodel/TrainingViewModel';

/** 摸底 / 结业测试弹窗（含遮罩） */
@Component
export struct QuizDialog {
  @ObjectLink vm: TrainingViewModel;

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.6)')

      Column() {
        Row() {
          Text(this.vm.stage === TrainingStage.PRE_TEST ? '培训摸底测试' : '培训结业测试')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
          Blank()
          Text('跳过')
            .fontSize(16)
            .fontColor('#666')
            .onClick(() => {
              this.vm.skipTest();
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 24, bottom: 12 })

        // 题号进度，题数取实际返回条数
        Text(`第 ${this.vm.questionIndex + 1} / ${this.vm.totalQuestions} 题`)
          .fontSize(13)
          .fontColor('#999')
          .width('100%')
          .padding({ left: 24, bottom: 8 })

        Scroll() {
          Column({ space: 15 }) {
            Text(this.vm.currentQuestionContent)
              .fontSize(16)
              .fontColor('#333')
              .width('100%')
              .textAlign(TextAlign.Start)

            ForEach(this.vm.currentQuestionOptions, (option: string, index: number) => {
              Row() {
                Text(option)
                  .fontSize(16)
                  .fontColor(this.vm.selectedOption === index ? '#FFFFFF' : '#333333')
              }
              .width('100%')
              .height(50)
              .padding({ left: 20 })
              .alignItems(VerticalAlign.Center)
              .backgroundColor(this.vm.selectedOption === index ? '#0D8AFF' : '#F5F5F5')
              .borderRadius(12)
              .onClick(() => {
                this.vm.selectOption(index);
              })
            }, (option: string, index: number) => `${this.vm.questionIndex}-${index}`)
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 20 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)

        Button(this.vm.isLastQuestion ? '完成' : '下一题')
          .width('90%')
          .height(48)
          .backgroundColor('#0D8AFF')
          .borderRadius(24)
          .fontSize(18)
          .fontColor(Color.White)
          .margin({ bottom: 30 })
          .onClick(() => {
            this.vm.nextQuestion();
          })
      }
      .width('90%')
      .height('60%')
      .backgroundColor(Color.White)
      .borderRadius(24)
    }
    .width('100%')
    .height('100%')
  }
}
