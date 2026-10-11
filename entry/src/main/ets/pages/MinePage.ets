@ComponentV2
export struct MineView {
  build() {
    Scroll() {
      Column() {
        // 顶部绿底与个人信息
        Stack({ alignContent: Alignment.Top }) {
          // 绿底
          Column()
            .width('100%')
            .height(200)
            .backgroundColor('#00B578')
          
          Column() {
            // 右上角信封
            Row() {
              Blank()
              Text('✉').fontSize(24).fontColor(Color.White).margin({ top: 16, right: 16 })
            }.width('100%')

            // 头像与信息
            Row() {
              // 头像
              Stack() {
                Circle().width(64).height(64).fill('#E2E8F0').stroke('#80FFFFFF').strokeWidth(2)
                Text('👤').fontSize(40)
              }.margin({ right: 16 })

              Column() {
                Text('游客46911').fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ bottom: 4 })
                Text('15007514874').fontSize(14).fontColor('#CCECE3')
              }.alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 24, top: 16 })

            // 数据卡片
            Row() {
              this.StatItem('4', '天', '坚持学习')
              Divider().vertical(true).height(30).color('#EEEEEE')
              this.StatItem('33', '道', '累计练习')
              Divider().vertical(true).height(30).color('#EEEEEE')
              this.StatItem('0', '分钟', '课程学习')
            }
            .width('calc(100% - 32px)')
            .height(80)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ top: 24 })
            .shadow({ radius: 8, color: '#0A000000', offsetY: 2 })
          }
          .width('100%')
        }
        .width('100%')
        .height(250)

        // VIP 会员中心
        Column() {
          Row() {
            Text('VIP会员中心').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#8C6B3F').fontStyle(FontStyle.Italic)
            Blank()
            Text('解锁章节练习文字解析权限 >').fontSize(12).fontColor('#8C6B3F')
          }.width('100%').padding({ left: 16, right: 16, top: 16 })

          Row({ space: 24 }) {
            this.VipIconItem('📚', '历年试卷')
            this.VipIconItem('📝', '模拟试卷')
            this.VipIconItem('💬', '文字解析')
            this.VipIconItem('🤖', 'AI智能推题')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .padding({ top: 16, bottom: 16 })
        }
        .width('calc(100% - 32px)')
        .margin({ top: -10, bottom: 16 })
        .backgroundColor('#FDF5E6') // 浅金背景色
        .borderRadius(12)
        .linearGradient({
          angle: 90,
          colors: [['#FCEABB', 0], ['#F8B500', 1.0]]
        })

        // 金刚区网格 (2行4列)
        Column() {
          Row() {
            this.MineGridItem('📋', '我的订单')
            this.MineGridItem('🎫', '优惠券')
            this.MineGridItem('💰', '我的钱包')
            this.MineGridItem('📝', '我的笔记')
          }.width('100%').margin({ bottom: 20 })

          Row() {
            this.MineGridItem('📘', '我的课程')
            this.MineGridItem('📂', '我的题集')
            this.MineGridItem('⭐', '我的收藏')
            this.MineGridItem('✏️', '练习进度')
          }.width('100%')
        }
        .width('calc(100% - 32px)')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .padding({ top: 20, bottom: 20 })
        .margin({ bottom: 16 })

        // 列表区
        Column() {
          Row() {
            Text('📍').fontSize(18).margin({ right: 12 })
            Text('地址管理').fontSize(15).fontColor('#333')
            Blank()
            Text('>').fontSize(16).fontColor('#CCC')
          }.width('100%').padding({ top: 16, bottom: 16, left: 16, right: 16 })
          
          Divider().width('calc(100% - 32px)').color('#F5F5F5')

          Row() {
            Text('⚙️').fontSize(18).margin({ right: 12 })
            Text('设置').fontSize(15).fontColor('#333')
            Blank()
            Text('>').fontSize(16).fontColor('#CCC')
          }.width('100%').padding({ top: 16, bottom: 16, left: 16, right: 16 })
        }
        .width('calc(100% - 32px)')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ bottom: 32 })

      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  StatItem(num: string, unit: string, label: string) {
    Column() {
      Row() {
        Text(num).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
        Text(unit).fontSize(12).fontColor('#333').margin({ left: 2, top: 4 })
      }.margin({ bottom: 4 })
      Text(label).fontSize(12).fontColor('#999')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  VipIconItem(icon: string, label: string) {
    Column() {
      Text(icon).fontSize(24).backgroundColor('#333').padding(8).borderRadius(20).margin({ bottom: 8 })
      Text(label).fontSize(12).fontColor('#5C4033')
    }
  }

  @Builder
  MineGridItem(icon: string, label: string) {
    Column() {
      Text(icon).fontSize(24).margin({ bottom: 8 })
      Text(label).fontSize(12).fontColor('#333')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}
