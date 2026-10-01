@Entry
@ComponentV2
struct Index {
  @Local isSheetOpen: boolean = false;   // 弹窗开没开
  @Local isMenuOpen: boolean = false;    // 左上角菜单开没开

  build() {
    Stack() {
      // ===== 主页面 =====
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
          .onClick(() => {
            this.isMenuOpen = true;
          })

          Blank()

          Image($r('app.media.toux'))
            .width(40).height(40).borderRadius(20)
        }
        .width('100%')
        .height(56)

        // ===== 2. 中间问候语 =====
        Column() {
          Text(' 需要我帮你做点什么？')
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

          TextInput({ placeholder: '问问小助手' })
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

      // ===== 菜单层：盖在主页面上面 =====
      if (this.isMenuOpen) {
        this.menuBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.isSheetOpen, this.sheetBuilder(), {
      height: 380,                           // 按内容实际高度写死
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
        this.listItem('急救培训', '学习婴幼儿急救操作')
        this.listItem('知识测试', '检验你的急救知识')
        this.listItem('实战演练', '模拟真实急救场景')
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

  // ===== 左上角菜单 =====
  @Builder
  menuBuilder() {
    Column() {
      // 标题 + 关闭按钮
      Row() {
        Text('畅息').fontSize(28).fontWeight(FontWeight.Medium).fontColor('#1F1F1F')
        Blank()
        Stack() {
          Text('✕').fontSize(20).fontColor('#3C4043')
        }
        .width(44).height(44).borderRadius(22)
        .backgroundColor('#F2F2F2')
        .onClick(() => {
          this.isMenuOpen = false;
        })
      }
      .width('100%').height(64)
      .margin({ top: 56, bottom: 16 })            // ★ 56 是让开状态栏，需要你调

      // 两项菜单
      this.menuItem($r('app.media.jiah'), '发起新对话', true)
      this.menuItem($r('app.media.fangdj'), '搜索对话内容', false)

      Blank()                                      // 其余留空
    }
    .width('100%').height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .transition(TransitionEffect.translate({ x: '-100%' }))   // ★ 从左边滑进来
  }

  // 菜单里的一行
  @Builder
  menuItem(icon: Resource, label: string, highlighted: boolean) {
    Row({ space: 16 }) {
      Image(icon).width(24).height(24)
      Text(label).fontSize(17).fontColor('#1F1F1F')
    }
    .width('100%').height(56)
    .padding({ left: 16, right: 16 })
    .borderRadius(28)
    .backgroundColor(highlighted ? '#F0F0F0' : Color.Transparent)   // "发起新对话"灰底高亮
  }
}
