// Index.ets
import router from '@ohos.router';
import { SideMenu } from './SideMenu';

@Entry
@Component
struct Index {
  @State inputValue: string = '';
  // 控制侧边栏显示/隐藏的状态变量
  @State isMenuVisible: boolean = false;

  build() {
    // 使用 Stack 堆叠布局：底层是主页面，上层浮着菜单
    Stack({ alignContent: Alignment.TopStart }) {

      // ==========================================
      // 第一部分：主界面
      // ==========================================
      Column() {
        // 1. 左上角菜单按钮 (这是唯一新增的交互入口)
        Row() {
          Text('☰')
            .fontSize(26)
            .fontColor('#999')
            .margin({ left: 16, top: 10 })
            .onClick(() => {
              this.isMenuVisible = true; // 点击打开菜单
            })
        }
        .width('100%')

        // 2. 中间空白区域 (保持原样)
        Blank()

        // 3. 底部区域 (完全还原截图样式)
        Column() {
          // 第一排：三个胶囊按钮
          Row({ space: 10 }) {
            Button('急救培训').fontSize(15).backgroundColor('#EAEAEA').fontColor('#333').borderRadius(20)
            Button('知识测试').fontSize(15).backgroundColor('#EAEAEA').fontColor('#333').borderRadius(20)
            Button('实战演练').fontSize(15).backgroundColor('#EAEAEA').fontColor('#333').borderRadius(20)
          }
          .width('100%')
          .margin({ bottom: 12 })
          .justifyContent(FlexAlign.SpaceEvenly)

          // 第二排：输入框
          Row() {
            Image($r('app.media.xiangj'))
              .width(28).height(28).fillColor('#999')

            TextInput({ placeholder: '点击输入...', text: this.inputValue })
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .fontSize(16)
              .margin({ left: 8 })

            // 【麦克风图标】
            Image($r('app.media.mm'))
              .width(28)
              .height(28)
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

      // ==========================================
      // 第二部分：侧边栏菜单 (浮在上面)
      // ==========================================

      // 1. 半透明遮罩层 (点击关闭菜单)
      if (this.isMenuVisible) {
        Column() {} // 使用空 Column 作为遮罩容器
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.isMenuVisible = false;
        })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
        .zIndex(99) // 确保在主页面上方
      }

      // 2. 侧边栏本体
      if (this.isMenuVisible) {
        SideMenu({
          onClose: () => { this.isMenuVisible = false; }
        })
          .width('75%')
          .height('100%')
          .backgroundColor(Color.White)
          // 动画逻辑：显示时 translateX(0)，隐藏时移出屏幕
          .translate({ x: this.isMenuVisible ? 0 : '-100%' })
          .animation({ duration: 300, curve: Curve.EaseOut })
          .zIndex(100) // 确保在遮罩层上方
      }

    } // Stack 布局结束
    .width('100%')
    .height('100%')
  }
}