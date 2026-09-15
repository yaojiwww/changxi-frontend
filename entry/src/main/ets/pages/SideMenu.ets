import { router } from '@kit.ArkUI';

@Component
export struct SideMenu {
 onClose: () => void = () => {};

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

      // 菜单项占位
      Column({ space: 16 }) {
        Text('急救培训').fontSize(18).fontColor('#333').padding(12)
        Text('知识测试').fontSize(18).fontColor('#333').padding(12)
        Text('实战演练').fontSize(18).fontColor('#333').padding(12)
        Text('设置').fontSize(18).fontColor('#333').padding(12)
      }
      .width('100%')
      .padding({ left: 24 })
    }
    .width('75%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}