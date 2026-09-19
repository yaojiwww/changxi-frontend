import { AppConfig } from '../../network/AppConfig';

@Component
export struct SideMenu {
  onClose: () => void = () => {};
  onOpenTraining: () => void = () => {};
  onOpenChat: () => void = () => {};
  onOpenLogin: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('菜单')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Blank()
        Text('关闭')
          .fontSize(16)
          .fontColor('#666')
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24, bottom: 20 })

      Column({ space: 16 }) {
        Text('AI 助手')
          .fontSize(18).fontColor('#333').padding(12)
          .onClick(() => {
            this.onClose();
            this.onOpenChat();
          })

        Text('登录 / 注册')
          .fontSize(18).fontColor('#333').padding(12)
          .onClick(() => {
            this.onClose();
            this.onOpenLogin();
          })

        // 后端接口缺失，暂时置灰
        Text(AppConfig.FEATURE_TRAINING_ENABLED ? '急救培训' : '急救培训（待后端接口）')
          .fontSize(18)
          .fontColor(AppConfig.FEATURE_TRAINING_ENABLED ? '#333' : '#BBB')
          .padding(12)
          .onClick(() => {
            if (!AppConfig.FEATURE_TRAINING_ENABLED) {
              return;
            }
            this.onClose();
            this.onOpenTraining();
          })

        Text('知识测试').fontSize(18).fontColor('#BBB').padding(12)
        Text('实战演练').fontSize(18).fontColor('#BBB').padding(12)
        Text('设置').fontSize(18).fontColor('#BBB').padding(12)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
