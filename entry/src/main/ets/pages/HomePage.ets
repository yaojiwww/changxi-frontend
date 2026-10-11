import { AIView } from './AIChatPage';
import { MineView } from './MinePage';

@Entry
@ComponentV2
struct Index {
  @Local currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  // 自定义底部导航项
  @Builder
  NavItem(title: string, targetIndex: number) {
    Column() {
      if (this.currentIndex === targetIndex) {
        // 选中状态：淡蓝胶囊药丸背景
        Column({ space: 3 }) {
          if (targetIndex === 0) {
            Path()
              .width(20)
              .height(20)
              .commands('M10 2.5L2 9.5V18H7V12.5H13V18H18V9.5L10 2.5Z')
              .stroke('#2F65F6')
              .strokeWidth(1.8)
              .fill(Color.Transparent)
          } else if (targetIndex === 1) {
            Text('✦')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2F65F6')
          } else {
            Path()
              .width(20)
              .height(20)
              .commands('M10 2.5A3.5 3.5 0 1 0 10 9.5A3.5 3.5 0 1 0 10 2.5M3.5 17.5A6.5 6.5 0 0 1 16.5 17.5')
              .stroke('#2F65F6')
              .strokeWidth(1.8)
              .fill(Color.Transparent)
          }

          Text(title)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2F65F6')
        }
        .width(86)
        .height(48)
        .borderRadius(20)
        .backgroundColor('#EBF2FF')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 未选中状态：透明背景，灰色图标与文字
        Column({ space: 3 }) {
          if (targetIndex === 0) {
            Path()
              .width(20)
              .height(20)
              .commands('M10 2.5L2 9.5V18H7V12.5H13V18H18V9.5L10 2.5Z')
              .stroke('#8A94A6')
              .strokeWidth(1.8)
              .fill(Color.Transparent)
          } else if (targetIndex === 1) {
            Text('✦')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#8A94A6')
          } else {
            Path()
              .width(20)
              .height(20)
              .commands('M10 2.5A3.5 3.5 0 1 0 10 9.5A3.5 3.5 0 1 0 10 2.5M3.5 17.5A6.5 6.5 0 0 1 16.5 17.5')
              .stroke('#8A94A6')
              .strokeWidth(1.8)
              .fill(Color.Transparent)
          }

          Text(title)
            .fontSize(11)
            .fontColor('#8A94A6')
        }
        .width(86)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.tabsController.changeIndex(targetIndex);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 页面主体 Tabs
      Tabs({ index: this.currentIndex, controller: this.tabsController }) {
        // 1. 首页
        TabContent() {
          HomeView()
        }

        // 2. AI 伴学
        TabContent() {
          AIView()
        }

        // 3. 我的
        TabContent() {
          MineView()
        }
      }
      .width('100%')
      .height('100%')
      .barHeight(0)
      .scrollable(true)
      .onChange((index: number) => {
        this.currentIndex = index;
      })

      // 底部悬浮/停靠导航栏
      Row() {
        this.NavItem('首页', 0)
        this.NavItem('ai伴学', 1)
        this.NavItem('我的', 2)
      }
      .width('100%')
      .height(66)
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .shadow({ radius: 16, color: '#14000000', offsetY: -4 })
      .border({ width: { top: 1 }, color: { top: '#F0F3F8' } })
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16, bottom: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F9FD')
  }
}

// ==================== 首页 (HomeView) ====================
@ComponentV2
struct HomeView {
  build() {
    Column() {
      Scroll() {
        Column() {
          // 1. 顶部 Header (Logo + 考证助手 + 通知铃铛)
          Row() {
            // 左侧 Logo 和标题
            Row({ space: 12 }) {
              // 蓝色圆角方形 Logo
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(42)
                  .height(42)
                  .borderRadius(13)
                  .backgroundColor('#2F65F6')
                  .shadow({ radius: 8, color: '#332F65F6', offsetY: 3 })

                // 两页白色书本
                Row({ space: 3 }) {
                  Row()
                    .width(7)
                    .height(18)
                    .borderRadius({ topLeft: 4, bottomLeft: 4 })
                    .border({ width: 2, color: Color.White })
                  Row()
                    .width(7)
                    .height(18)
                    .borderRadius({ topRight: 4, bottomRight: 4 })
                    .border({ width: 2, color: Color.White })
                }
              }

              Column({ space: 3 }) {
                Text('育见未来')
                  .fontSize(19)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A202C')
                Text('保育师考证助手')
                  .fontSize(12)
                  .fontColor('#8A94A6')
              }
              .alignItems(HorizontalAlign.Start)
            }

            Blank()

            // 右侧通知状态铃铛
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(42)
                .height(42)
                .borderRadius(21)
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#EEF2F6' })
                .shadow({ radius: 6, color: '#0A000000', offsetY: 2 })

              // 极简纯净铃铛造型
              Column({ space: 1.5 }) {
                Row().width(12).height(11).borderRadius({ topLeft: 6, topRight: 6 }).backgroundColor('#4A5568')
                Row().width(17).height(2.5).borderRadius(1.5).backgroundColor('#4A5568')
                Row().width(4).height(3).borderRadius({ bottomLeft: 2, bottomRight: 2 }).backgroundColor('#4A5568')
              }

              // 红色小圆点通知状态
              Circle()
                .width(8)
                .height(8)
                .fill('#FF4D4F')
                .stroke(Color.White)
                .strokeWidth(1.5)
                .position({ x: 27, y: 5 })
            }
          }
          .width('100%')
          .padding({ top: 4, bottom: 14 })
          .alignItems(VerticalAlign.Center)

          // 2. 状态卡片 ("继续今日学习" + 68%进度环) - 尺寸适中、自适应内容高度
          Column() {
            // 标签：AI 学习方案已更新
            Row({ space: 5 }) {
              Text('✨').fontSize(12).fontColor('#DCE7FF')
              Text('AI 学习方案已更新')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#E0EAFF')
            }
            .margin({ bottom: 8 })

            // 问候语：早上好，林小满
            Text('早上好，林小满')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ bottom: 6 })

            // 考试倒计时文字
            Text() {
              Span('距离考试还有 ')
                .fontColor('#D4E2FF')
                .fontSize(13)
              Span('42')
                .fontColor(Color.White)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
              Span(' 天，稳稳向前，每一次练习都算数。')
                .fontColor('#D4E2FF')
                .fontSize(13)
            }
            .lineHeight(19)
            .margin({ bottom: 16 })

            // 底部操作区与进度环
            Row() {
              // 白底胶囊按钮
              Row({ space: 6 }) {
                Text('继续今日练习')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2651DF')
                Text('→')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2651DF')
              }
              .backgroundColor(Color.White)
              .padding({ left: 16, right: 16, top: 9, bottom: 9 })
              .borderRadius(20)
              .shadow({ radius: 6, color: '#1A000000', offsetY: 2 })

              Blank()

              // 环形进度条
              Stack({ alignContent: Alignment.Center }) {
                Progress({ value: 68, total: 100, type: ProgressType.Ring })
                  .width(68)
                  .height(68)
                  .color(Color.White)
                  .backgroundColor('#3DFFFFFF')
                  .style({ strokeWidth: 6 })

                Column({ space: 2 }) {
                  Text('68%')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                  Text('备考进度')
                    .fontSize(10)
                    .fontColor('#D4E2FF')
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 16, bottom: 16 })
          .borderRadius(20)
          .linearGradient({
            angle: 135,
            colors: [['#336AF8', 0.0], ['#234FDE', 1.0]]
          })
          .shadow({ radius: 12, color: '#332F65F6', offsetY: 6 })
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 18 })

          // 3. "今天，先完成这三件事" Section
          Row() {
            Column({ space: 4 }) {
              Text('今天，先完成这三件事')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A202C')
              Text('AI 根据你的薄弱项动态安排')
                .fontSize(12)
                .fontColor('#8A94A6')
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            // 1/3 已完成 状态胶囊
            Row() {
              Text('1 / 3 已完成')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#059669')
            }
            .backgroundColor('#E6F7F0')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .borderRadius(12)
          }
          .width('100%')
          .margin({ bottom: 14 })

          // 卡片 1：晨间知识复习 (已完成)
          Row() {
            // 左侧绿色完成图标
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(42)
                .height(42)
                .borderRadius(12)
                .backgroundColor('#E6F7F0')
              Text('✓')
                .fontSize(19)
                .fontWeight(FontWeight.Bolder)
                .fontColor('#059669')
            }

            // 中间信息
            Column({ space: 4 }) {
              Text('晨间知识复习')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A202C')
              Text('儿童生活照料 · 10 个知识点')
                .fontSize(12)
                .fontColor('#8A94A6')
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 14 })
            .layoutWeight(1)

            // 右侧状态
            Text('已完成')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#059669')
          }
          .width('100%')
          .padding(16)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#EEF2F6' })
          .shadow({ radius: 6, color: '#06000000', offsetY: 2 })
          .margin({ bottom: 12 })
          .alignItems(VerticalAlign.Center)

          // 卡片 2：专项强化练习 (高亮/进行中)
          Row() {
            // 左侧序号 02
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(42)
                .height(42)
                .borderRadius(12)
                .backgroundColor('#EBF2FF')
              Text('02')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2F65F6')
            }

            // 中间信息
            Column({ space: 4 }) {
              Text('专项强化练习')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A202C')
              Text('安全工作常识 · 20 题')
                .fontSize(12)
                .fontColor('#8A94A6')
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 14 })
            .layoutWeight(1)

            // 右侧蓝色进入箭头按钮
            Stack({ alignContent: Alignment.Center }) {
              Circle()
                .width(36)
                .height(36)
                .fill('#2F65F6')
                .shadow({ radius: 6, color: '#332F65F6', offsetY: 2 })
              Text('→')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
          }
          .width('100%')
          .padding(16)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1.5, color: '#D6E4FF' })
          .shadow({ radius: 8, color: '#0A2F65F6', offsetY: 3 })
          .margin({ bottom: 12 })
          .alignItems(VerticalAlign.Center)

          // 卡片 3：错题回顾 (待复习)
          Row() {
            // 左侧序号 03
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(42)
                .height(42)
                .borderRadius(12)
                .backgroundColor('#EBF2FF')
              Text('03')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2F65F6')
            }

            // 中间信息
            Column({ space: 4 }) {
              Text('错题回顾')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A202C')
              Text('6 道易错题待复习')
                .fontSize(12)
                .fontColor('#8A94A6')
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 14 })
            .layoutWeight(1)

            // 右侧箭头
            Text('›')
              .fontSize(22)
              .fontWeight(FontWeight.Medium)
              .fontColor('#A0AEC0')
          }
          .width('100%')
          .padding(16)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#EEF2F6' })
          .shadow({ radius: 6, color: '#06000000', offsetY: 2 })
          .margin({ bottom: 22 })
          .alignItems(VerticalAlign.Center)

          // 4. "题库练习进入导航" Section
          Row() {
            Column({ space: 4 }) {
              Text('题库练习')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A202C')
              Text('从基础到实战，循序渐进')
                .fontSize(12)
                .fontColor('#8A94A6')
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Text('全部')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2F65F6')
          }
          .width('100%')
          .margin({ bottom: 14 })

          // 6 张卡片，两两一行 (2列网格)
          Column({ space: 12 }) {
            Row({ space: 12 }) {
              this.QuestionBankCard('顺序刷题', '按章节系统巩固', '#EBF2FF', '#2F65F6', 'book')
              this.QuestionBankCard('乱序刷题', '打破记忆惯性', '#F3E8FF', '#8B5CF6', 'shuffle')
            }
            .width('100%')

            Row({ space: 12 }) {
              this.QuestionBankCard('每日一练', '今日还剩 12 题', '#FEF3C7', '#F59E0B', 'calendar')
              this.QuestionBankCard('模拟考试', '全真计时与评分', '#E6F7F0', '#10B981', 'exam')
            }
            .width('100%')

            Row({ space: 12 }) {
              this.QuestionBankCard('知识点', '考纲框架速记', '#E0F2FE', '#0284C7', 'layer')
              this.QuestionBankCard('图文讲解', '实操步骤图解', '#FFE4E6', '#F43F5E', 'image')
            }
            .width('100%')
          }
          .width('100%')
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 84 })
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [['#EBF3FF', 0.0], ['#F5F8FD', 0.25], ['#F8FAFC', 1.0]]
    })
  }

  // 题库练习单个小卡片
  @Builder
  QuestionBankCard(title: string, subtitle: string, iconBg: string, iconColor: string, iconType: string) {
    Row() {
      // 左侧图标容器
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(42)
          .height(42)
          .borderRadius(13)
          .backgroundColor(iconBg)

        if (iconType === 'book') {
          Path()
            .width(20)
            .height(20)
            .commands('M3 5.5C3 4.5 4 4 5 4H9.5C10 4 10.5 4.5 10.5 5.5V16.5C10.5 16 10 15.5 9.5 15.5H5C4 15.5 3 16 3 17V5.5ZM18 5.5C18 4.5 17 4 16 4H11.5C11 4 10.5 4.5 10.5 5.5V16.5C10.5 16 11 15.5 11.5 15.5H16C17 15.5 18 16 18 17V5.5Z')
            .stroke(iconColor)
            .strokeWidth(1.6)
            .fill(Color.Transparent)
        } else if (iconType === 'shuffle') {
          Path()
            .width(20)
            .height(20)
            .commands('M3 6H6L11 14H15M13 12L15 14L13 16M3 14H6L7.5 11.5M10.5 8.5L11 8H15M13 6L15 8L13 10')
            .stroke(iconColor)
            .strokeWidth(1.6)
            .fill(Color.Transparent)
            .strokeLineCap(LineCapStyle.Round)
            .strokeLineJoin(LineJoinStyle.Round)
        } else if (iconType === 'calendar') {
          Path()
            .width(20)
            .height(20)
            .commands('M4 5.5H16V16.5H4ZM4 9H16M7 3.5V6.5M13 3.5V6.5')
            .stroke(iconColor)
            .strokeWidth(1.6)
            .fill(Color.Transparent)
            .strokeLineCap(LineCapStyle.Round)
        } else if (iconType === 'exam') {
          Path()
            .width(20)
            .height(20)
            .commands('M5 3.5H12.5L15.5 6.5V16.5H5ZM8 8.5H12.5M8 11.5H12.5M8 14.5H10.5')
            .stroke(iconColor)
            .strokeWidth(1.6)
            .fill(Color.Transparent)
            .strokeLineCap(LineCapStyle.Round)
        } else if (iconType === 'layer') {
          Path()
            .width(20)
            .height(20)
            .commands('M3 7.5L10 4L17 7.5L10 11ZM3 11.5L10 15L17 11.5M3 15.5L10 19L17 15.5')
            .stroke(iconColor)
            .strokeWidth(1.6)
            .fill(Color.Transparent)
            .strokeLineCap(LineCapStyle.Round)
            .strokeLineJoin(LineJoinStyle.Round)
        } else {
          Path()
            .width(20)
            .height(20)
            .commands('M3.5 4.5H16.5V15.5H3.5ZM3.5 13L7.5 9L11.5 13M11.5 11.5L14 9L16.5 11.5')
            .stroke(iconColor)
            .strokeWidth(1.6)
            .fill(Color.Transparent)
            .strokeLineCap(LineCapStyle.Round)
            .strokeLineJoin(LineJoinStyle.Round)
        }
      }

      // 右侧文字
      Column({ space: 3 }) {
        Text(title)
          .fontSize(14.5)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
        Text(subtitle)
          .fontSize(11)
          .fontColor('#8A94A6')
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
      .layoutWeight(1)
    }
    .layoutWeight(1)
    .padding({ left: 12, right: 8, top: 15, bottom: 15 })
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#EEF2F6' })
    .shadow({ radius: 6, color: '#06000000', offsetY: 2 })
    .alignItems(VerticalAlign.Center)
  }
}
