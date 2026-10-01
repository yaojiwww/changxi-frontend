@Entry
@ComponentV2
struct Index {
  @Local isSheetOpen: boolean = false;   // 弹窗开没开

  build() {
    Column() {
      // ===== 1. 顶栏 =====
      Row() {
        // 菜单按钮：灰底圆形 + 两条横线（等号）
        Column({ space: 5 }) {
          Divider().width(18).strokeWidth(2).color('#3C4043')
          Divider().width(18).strokeWidth(2).color('#3C4043')
        }
        .width(40).height(40)
        .borderRadius(20)
        .backgroundColor('#F2F2F2')
        .justifyContent(FlexAlign.Center)

        Blank()

        Row() {
          Text('Gemini').fontSize(18).fontColor('#1F1F1F')
          Text('Flash').fontSize(18).fontColor('#9AA0A6').margin({ left: 4 })
          Text('⌄').fontSize(16).fontColor('#9AA0A6').margin({ left: 4 })
        }

        Blank()

        Image($r('app.media.toux'))
          .width(40).height(40).borderRadius(20)
      }
      .width('100%')
      .height(56)

      // ===== 2. 中间问候语 =====
      Column() {
        Text('yaojiw，需要我帮你做点什么？')
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // ===== 3. 底部输入条 =====
      Row() {
        Image($r('app.media.jiah'))
          .width(24).height(24)
          .onClick(() => {
            this.isSheetOpen = true;             // 只改状态，没有"打开弹窗"的代码
          })

        TextInput({ placeholder: '问问 Gemini' })
          .placeholderColor('#9AA0A6')
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .margin({ left: 12, right: 12 })

        Image($r('app.media.mm')).width(24).height(24)   // 麦克风
      }
      .width('100%')
      .height(56)
      .borderRadius(28)
      .backgroundColor(Color.White)
      .padding({ left: 20, right: 20 })
      .shadow({ radius: 12, color: '#14000000', offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, bottom: 10 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .linearGradient({
      angle: 180,
      colors: [['#FFFFFF', 0.0], ['#DCE9FB', 1.0]]
    })
    .bindSheet(this.isSheetOpen, this.sheetBuilder(), {
      height: SheetSize.MEDIUM,              // 半屏
      dragBar: true,                         // 顶部那根灰色小拖拽条
      showClose: false,
      backgroundColor: '#F2FFFFFF',          // 半透明白
      blurStyle: BlurStyle.Thin,             // 毛玻璃，透出后面的内容
      onDisappear: () => {
        this.isSheetOpen = false;            // 手动拖下去时，把状态改回来
      }
    })
  }

  // ===== 弹窗里的内容 =====
  @Builder
  sheetBuilder() {
    Column() {
      Row({ space: 12 }) {
        this.bigCard($r('app.media.xiangj'), '照片')
        this.bigCard($r('app.media.xiangj'), '相机')
        this.bigCard($r('app.media.cd'), '图片')
      }
      .width('100%')
      .margin({ top: 16 })

      Column() {
        this.listItem('图片', '生成图片与编辑')
        this.listItem('Canvas', '编写代码、撰写内容或制作幻灯片')
        this.listItem('学习辅导', '获取逐步帮助')
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  // 大圆角卡片
  @Builder
  bigCard(icon: Resource, label: string) {
    Column({ space: 12 }) {
      Image(icon).width(28).height(28)
      Text(label).fontSize(15).fontColor('#1F1F1F')
    }
    .layoutWeight(1)
    .height(120)
    .borderRadius(24)
    .backgroundColor('#14000000')
    .justifyContent(FlexAlign.Center)
  }

  // 列表项
  @Builder
  listItem(title: string, desc: string) {
    Column({ space: 2 }) {
      Text(title).fontSize(17).fontColor('#1F1F1F')
      Text(desc).fontSize(13).fontColor('#9AA0A6')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 16, bottom: 16 })
  }
}
