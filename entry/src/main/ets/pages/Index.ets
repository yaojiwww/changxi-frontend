import { AIView } from './AI';
import { MineView } from './Mine';

@Entry
@ComponentV2
struct Index {
  @Local currentIndex: number = 0;

  // 底部导航栏自定义 Builder
  @Builder
  TabBuilder(title: string, targetIndex: number, iconNormal: string, iconSelected: string) {
    Column() {
      Text(this.currentIndex === targetIndex ? iconSelected : iconNormal)
        .fontSize(24)
        .fontColor(this.currentIndex === targetIndex ? '#00B578' : '#9AA0A6')
        .margin({ bottom: 4 })
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === targetIndex ? '#00B578' : '#9AA0A6')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      // 1. 练习 (首页)
      TabContent() {
        HomeView()
      }
      .tabBar(this.TabBuilder('练习', 0, '🏠', '🏠'))

      // 2. AI助教
      TabContent() {
        AIView()
      }
      .tabBar(this.TabBuilder('AI助教', 1, '🤖', '🤖'))

      // 3. 我的
      TabContent() {
        MineView()
      }
      .tabBar(this.TabBuilder('我的', 2, '👤', '👤'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}

// ==================== 1. 首页 (练习) ====================
@ComponentV2
struct HomeView {
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('医学三基考试').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333')
        Image($r('app.media.fangdj')).width(12).height(12).margin({ left: 4 }) // 下拉箭头占位
        Blank()
        Text('🎧').fontSize(20).margin({ right: 16 })
        Text('⊞').fontSize(24).fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)

      // 顶部分类Tab
      Row() {
        Text('临床基础知识').fontSize(15).fontColor('#666').layoutWeight(1).textAlign(TextAlign.Center)
        Column() {
          Text('医学临床基础技能').fontSize(15).fontColor('#00B578').fontWeight(FontWeight.Medium)
          Divider().width(24).strokeWidth(3).color('#00B578').lineCap(LineCapStyle.Round).margin({ top: 4 })
        }.layoutWeight(1.2).alignItems(HorizontalAlign.Center)
        Text('临床各科基...').fontSize(15).fontColor('#666').layoutWeight(1).textAlign(TextAlign.Center)
        Text('≡').fontSize(20).fontColor('#333').margin({ left: 8, right: 8 })
      }
      .width('100%')
      .padding({ top: 10, bottom: 0 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          // Banner
          Stack({ alignContent: Alignment.Center }) {
            // 背景蓝紫色
            Row().width('100%').height(140).backgroundColor('#5D6BFA').borderRadius(8)
            // 文字
            Column({ space: 8 }) {
              Text('模拟试卷').fontSize(28).fontWeight(FontWeight.Bold).fontColor(Color.White).letterSpacing(2)
              Text('好事多“模”').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFD700')
              Row() {
                Text('戳我练习 →').fontSize(12).fontColor(Color.White)
              }
              .backgroundColor('#424ED6')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(14)
              .margin({ top: 8 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({ left: 24 })
          }
          .width('100%')
          .padding(16)

          // 金刚区功能网格 (10个)
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            this.GridItem('📖', '章节练习')
            this.GridItem('📄', '试卷中心')
            this.GridItem('💎', '加油包')
            this.GridItem('🎯', '真题精炼')
            this.GridItem('🏆', '抗遗忘', '每天')
            this.GridItem('❌', '错题巩固')
            this.GridItem('⭐', '我的收藏')
            this.GridItem('📝', '我的笔记')
            this.GridItem('✅', '每日打卡')
            this.GridItem('📋', '我的试卷')
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .padding({ top: 16, bottom: 8, left: 8, right: 8 })
          .margin({ left: 16, right: 16, bottom: 16 })
          .width('calc(100% - 32px)')

          // 中间两个Banner
          Row({ space: 12 }) {
            // 智能组卷
            Column() {
              Text('智能组卷').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
              Text('实时测验，即刻检验').fontSize(12).fontColor(Color.White).backgroundColor('#219653').padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(4).margin({ top: 20 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .height(80)
            .backgroundColor('#E8F5E9')
            .borderRadius(8)
            .padding(12)

            // 在线模考
            Column() {
              Text('在线模考').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
              Text('实战演练 查漏补缺').fontSize(12).fontColor(Color.White).backgroundColor('#2D9CDB').padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(4).margin({ top: 20 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .height(80)
            .backgroundColor('#E3F2FD')
            .borderRadius(8)
            .padding(12)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })

          // 章节练习列表区域
          Column() {
            // 标题行
            Row() {
              Divider().vertical(true).height(16).strokeWidth(4).color('#00B578').lineCap(LineCapStyle.Round)
              Text('章节练习').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333').margin({ left: 8 })
              Blank()
              Text('AI刷题设置').fontSize(12).fontColor(Color.White).backgroundColor('#EB5757').padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(4)
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })

            // 三个小按钮
            Row({ space: 12 }) {
              Text('点亮知识树 🔥').fontSize(13).fontColor('#333').backgroundColor(Color.White).border({ width: 1, color: '#EEEEEE' }).borderRadius(20).padding({ left: 12, right: 12, top: 8, bottom: 8 }).layoutWeight(1).textAlign(TextAlign.Center)
              Text('薄弱提升').fontSize(13).fontColor('#333').backgroundColor(Color.White).border({ width: 1, color: '#EEEEEE' }).borderRadius(20).padding({ left: 12, right: 12, top: 8, bottom: 8 }).layoutWeight(1).textAlign(TextAlign.Center)
              Text('错题巩固').fontSize(13).fontColor('#333').backgroundColor(Color.White).border({ width: 1, color: '#EEEEEE' }).borderRadius(20).padding({ left: 12, right: 12, top: 8, bottom: 8 }).layoutWeight(1).textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })

            // 列表项：专业实践
            Column() {
              Row() {
                Text('⌄').fontSize(20).fontColor('#00B578').fontWeight(FontWeight.Bold).margin({ right: 8 }).backgroundColor('#E8F5E9').borderRadius(12).width(24).height(24).textAlign(TextAlign.Center)
                Text('专业实践').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#333')
                Blank()
                Text('✎').fontSize(18).fontColor('#999')
              }.width('100%')
              
              Row() {
                Row().layoutWeight(1).height(6).backgroundColor('#F5F5F5').borderRadius(3).margin({ right: 4 })
                Row().layoutWeight(1).height(6).backgroundColor('#F5F5F5').borderRadius(3).margin({ right: 4 })
                Row().layoutWeight(1).height(6).backgroundColor('#F5F5F5').borderRadius(3).margin({ right: 4 })
                Row().layoutWeight(1).height(6).backgroundColor('#F5F5F5').borderRadius(3).margin({ right: 4 })
                Row().layoutWeight(1).height(6).backgroundColor('#F5F5F5').borderRadius(3).margin({ right: 8 })
                Text('0 / 2130').fontSize(12).fontColor('#999')
              }.width('100%').margin({ top: 16, left: 32 })
            }
            .width('calc(100% - 32px)')
            .backgroundColor(Color.White)
            .borderRadius(12)
            .padding(16)
            .margin({ left: 16, right: 16, bottom: 20 })

          }
          .width('100%')
        }
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  GridItem(icon: string, label: string, badge?: string) {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Text(icon).fontSize(28).margin({ bottom: 8, top: 8 })
        if (badge) {
          Text(badge).fontSize(8).fontColor(Color.White).backgroundColor('#EB5757').padding({ left: 4, right: 4, top: 2, bottom: 2 }).borderRadius(8).offset({ x: 10, y: 0 })
        }
      }
      Text(label).fontSize(12).fontColor('#333')
    }
    .width('20%')
    .margin({ bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }
}
