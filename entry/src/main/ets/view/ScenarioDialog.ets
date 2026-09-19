import { TrainingViewModel } from '../../viewmodel/TrainingViewModel';
import { ScenarioItem, AgeOptionItem } from '../../model/Scenario';

/** 场景选择弹窗（含遮罩） */
@Component
export struct ScenarioDialog {
  @ObjectLink vm: TrainingViewModel;

  build() {
    Stack() {
      // 遮罩：点击关闭（原来点这里设的是没人读的 showOverlay，所以关不掉）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.vm.closeAll();
        })

      Column() {
        Text('请选择急救场景')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 24, top: 24, bottom: 16 })

        if (this.vm.errorMessage.length > 0) {
          Text(this.vm.errorMessage)
            .fontSize(14)
            .fontColor('#D32F2F')
            .padding({ left: 24, right: 24, bottom: 8 })
        }

        if (this.vm.isLoading) {
          Column({ space: 12 }) {
            LoadingProgress().width(48).height(48).color('#0D8AFF')
            Text('正在加载…').fontSize(14).fontColor('#888')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.showAgeSelector) {
          this.AgeSelector()
        } else {
          this.ScenarioList()
        }
      }
      .width('90%')
      .height('80%')
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 8 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  AgeSelector() {
    Column({ space: 20 }) {
      Text(`请选择年龄段：${this.vm.pendingCategoryTitle}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      ForEach(this.vm.pendingAgeOptions, (opt: AgeOptionItem) => {
        Button(opt.label)
          .width('80%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#E6F7FF')
          .fontColor('#007AFF')
          .onClick(() => {
            this.vm.chooseAge(opt.key);
          })
      }, (opt: AgeOptionItem) => opt.key)

      Button('返回上一步')
        .type(ButtonType.Capsule)
        .width('60%')
        .height(44)
        .backgroundColor('#BDBDBD')
        .fontColor(Color.White)
        .onClick(() => {
          this.vm.backToScenarioList();
        })
    }
    .width('100%')
    .layoutWeight(1)
    .padding(20)
  }

  @Builder
  ScenarioList() {
    Scroll() {
      Column({ space: 12 }) {
        ForEach(this.vm.scenarioList, (item: ScenarioItem, index: number) => {
          Row() {
            Text(item.title)
              .fontSize(16)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(16)
          .backgroundColor(this.vm.selectedIndex === index ? '#E6F7FF' : '#F5F5F5')
          .borderRadius(12)
          .onClick(() => {
            this.vm.highlightScenario(index);
          })
        }, (item: ScenarioItem, index: number) => `${index}-${item.title}`)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.On)
    .align(Alignment.Top)

    Button('下一步')
      .fontSize(16)
      .width('80%')
      .height(44)
      .backgroundColor(this.vm.selectedIndex === -1 ? '#A0A0A0' : '#4CAF50')
      .fontColor('#FFFFFF')
      .borderRadius(22)
      .margin({ top: 12, bottom: 24 })
      .enabled(this.vm.selectedIndex !== -1)
      .onClick(() => {
        this.vm.confirmScenario();
      })
  }
}
