// SideMenu.ets
@Component
export struct SideMenu {
  onClose?: () => void;

  build() {
    Column() {
      // --- 1. 顶部搜索栏 ---
      Row() {
        Image($r('app.media.fangdj')) // 放大镜
          .width(28).height(28).fillColor('#999')
          .margin({ right: 8 })

        Text('点击搜索...')
          .fontSize(16)
          .fontColor('#999') // <--- 加上这一行！设置成灰色，就能看见了
          .layoutWeight(1)

        Image($r('app.media.jiah')) // 加号
          .width(28).height(28).fillColor('#333')
      }
      .width('95%')
      .height(40)
      .backgroundColor('#F0F0F0')
      .borderRadius(20)
      .padding({ left: 12, right: 12 ,top:18,bottom:12})
      .margin({ bottom: 30 })

      // --- 2. 中间列表区域 (错题集 & 聊天记录) ---
      Column() {
        this.MenuItem('错题集')
        this.MenuItem('聊天记录')
      }
      .width('100%')
      .padding({ top: 20, left: 16, right: 16 })
      .layoutWeight(1) // 占据中间空间
      .alignItems(HorizontalAlign.Start) // 左对齐

      // --- 3. 底部功能区 (头像 & 设置) ---
      Row() {
        // 左下角：用户头像
        Image($r('app.media.toux')) // TODO: 记得换成头像图片
          .width(35).height(35)
          .borderRadius(20)
          .backgroundColor('#DDD') // 占位背景色
          .onClick(() => { console.info('User clicked'); })

        Blank() // 撑开中间距离

        // 右下角：通用设置
        Image($r('app.media.shez')) // TODO: 记得换成设置齿轮图标
          .width(35).height(35)
          .fillColor('#999')
          .onClick(() => { console.info('Settings clicked'); })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5') // 整体浅灰背景
  }

  // 封装菜单项组件 (文字+边框)
  @Builder
  MenuItem(text: string) {
    Text(text)
      .fontSize(16)
      .fontColor('#333333')
      .width('90%') // 宽度稍微留点空隙
      .padding({ top: 12, bottom: 12, left: 16 })
      .backgroundColor(Color.White)
      .borderRadius(8)
      .border({ width: 1, color: '#E0E0E0' }) // 浅灰色边框
      .margin({ bottom: 12 })
      .onClick(() => {
        console.info(text + ' clicked');
        if (this.onClose) this.onClose(); // 点击后关闭菜单
      })
  }
}