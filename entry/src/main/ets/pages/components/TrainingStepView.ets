import { TrainingViewModel } from '../../viewmodel/TrainingViewModel';
import { UniversalAction } from './UniversalAction';

/** 分步培训内容页 */
@Component
export struct TrainingStepView {
  @ObjectLink vm: TrainingViewModel;

  build() {
    Column() {
      if (this.vm.isLoading) {
        this.Loading()
      } else if (this.vm.hasCurrentStep) {
        this.StepContent()
      } else if (this.vm.isAllStepsDone) {
        this.FinishedContent()
      } else {
        Text('暂无培训内容')
          .fontSize(16)
          .fontColor('#888')
          .margin({ top: 60 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  Loading() {
    Column({ space: 12 }) {
      LoadingProgress().width(48).height(48).color('#0D8AFF')
      Text('正在加载…').fontSize(14).fontColor('#888')
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  StepContent() {
    Column() {
      Text(`第${this.vm.stepIndex + 1}步：${this.vm.currentStepTitle}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .width('90%')
        .margin({ top: 20, bottom: 10 })

      Text(this.vm.currentStepDescription)
        .fontSize(16)
        .fontColor('#555')
        .padding(15)
        .backgroundColor('#F0F8FF')
        .width('90%')
        .borderRadius(15)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 20 })

    // 动画 / 3D 演示占位
    Column() {
      Text(`🎬 正在演示：${this.vm.currentStepTitle}`)
        .fontSize(18)
        .fontColor('#007AFF')
      Text('（此处替换为你的3D动画或视频组件）')
        .fontSize(14)
        .fontColor('#999')
        .margin({ top: 10, bottom: 10 })
    }
    .width('90%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F9F9F9')
    .borderRadius(15)
    .margin({ top: 20, bottom: 20 })

    if (this.vm.showDetailInfo) {
      Column({ space: 15 }) {
        Text(`💡 详细解释：${this.vm.currentStepDescription}（请仔细观察动画细节，确保动作规范。）`)
          .fontSize(15)
          .fontColor('#D32F2F')
          .padding(15)
          .backgroundColor('#FFF0F0')
          .borderRadius(15)
          .width('90%')

        Button('我明白了，返回操作')
          .width('80%')
          .height(45)
          .borderRadius(25)
          .backgroundColor('#FF9800')
          .onClick(() => {
            this.vm.hideDetail();
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    } else {
      Column({ space: 15 }) {
        UniversalAction({
          currentStep: this.vm.currentStep,
          onStepComplete: () => {
            this.vm.completeStep();
          }
        })
          .margin({ top: 10 })

        if (this.vm.isStepCompleted) {
          Row({ space: 15 }) {
            Button('没看懂 / 慢动作')
              .type(ButtonType.Normal)
              .borderRadius(22)
              .backgroundColor(Color.White)
              .fontColor('#FF9800')
              .border({ width: 1, color: '#FF9800' })
              .layoutWeight(1)
              .onClick(() => {
                this.vm.showDetail();
              })

            Button('已掌握，下一步')
              .type(ButtonType.Capsule)
              .backgroundColor('#007AFF')
              .layoutWeight(1)
              .onClick(() => {
                this.vm.nextStep();
              })
          }
          .width('90%')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
  }

  @Builder
  FinishedContent() {
    Column() {
      Text('🎉 恭喜！您已顺利完成所有培训步骤。')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ bottom: 20 })
      Text('建议前往实战演练模块进行巩固')
        .fontSize(14)
        .fontColor('#888')
        .margin({ bottom: 30 })

      if (this.vm.errorMessage.length > 0) {
        Text(this.vm.errorMessage)
          .fontSize(14)
          .fontColor('#D32F2F')
          .margin({ bottom: 16 })
      }

      Button('前往结业测试')
        .width('80%')
        .height(50)
        .borderRadius(25)
        .backgroundColor('#4CAF50')
        .onClick(() => {
          this.vm.gotoPostTest();
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
