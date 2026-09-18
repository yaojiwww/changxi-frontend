import { AppConfig } from '../../network/AppConfig';

/** 首页主体（标题栏 + 三个入口按钮 + 输入框） */
@Component
export struct HomeContent {
  onOpenMenu: () => void = () => {};
  onStartTraining: () => void = () => {};
  onOpenChat: () => void = () => {};
  onOpenLogin: () => void = () => {};

  @State private inputValue: string = '';

  build() {
    Column() {
      Row() {
        Text('☰')
          .fontSize(26)
          .fontColor('#999')
          .margin({ left: 16, top: 10 })
          .onClick(() => {
            this.onOpenMenu();
          })
      }
      .width('100%')

      Blank()

      Column() {
        Row({ space: 10 }) {
          // 后端缺步骤/题库接口，由 AppConfig.FEATURE_TRAINING_ENABLED 控制
          Button('急救培训')
            .fontSize(15)
            .backgroundColor('#EAEAEA')
            .fontColor(AppConfig.FEATURE_TRAINING_ENABLED ? '#333' : '#BBB')
            .borderRadius(20)
            .enabled(AppConfig.FEATURE_TRAINING_ENABLED)
            .onClick(() => {
              this.onStartTraining();
            })

          Button('AI 助手')
            .fontSize(15)
            .backgroundColor('#EAEAEA')
            .fontColor('#333')
            .borderRadius(20)
            .onClick(() => {
              this.onOpenChat();
            })

          Button('登录')
            .fontSize(15)
            .backgroundColor('#EAEAEA')
            .fontColor('#333')
            .borderRadius(20)
            .onClick(() => {
              this.onOpenLogin();
            })
        }
        .width('100%')
        .margin({ bottom: 12 })
        .justifyContent(FlexAlign.SpaceEvenly)

        Row() {
          Image($r('app.media.xiangj'))
            .width(28).height(28).fillColor('#999')
          TextInput({ placeholder: '点击输入...', text: this.inputValue })
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .fontSize(16)
            .margin({ left: 8 })
            .onChange((value: string) => {
              this.inputValue = value;
            })
          Image($r('app.media.mm'))
            .width(28).height(28)
            .margin({ left: 8, right: 8 })
            .fillColor('#999999')
          Image($r('app.media.jiah'))
            .width(28).height(28).fillColor('#999')
        }
        .width('95%')
        .height(50)
        .backgroundColor('#F0F0F0')
        .borderRadius(20)
        .padding({ left: 12, right: 12 })
        .margin({ bottom: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
