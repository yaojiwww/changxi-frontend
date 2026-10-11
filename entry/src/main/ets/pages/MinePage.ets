@ComponentV2
export struct MineView {
  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          // ==================== 1. 个人名片卡片 ====================
          Column() {
            // 蓝色名片上半部分
            Row() {
              // 头像（白底圆角矩形，居中蓝色“林”字）
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(62)
                  .height(62)
                  .borderRadius(18)
                  .backgroundColor(Color.White)
                  .shadow({ radius: 8, color: '#1A000000', offsetY: 3 })

                Text('林')
                  .fontSize(26)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2F65F6')
              }

              // 个人信息
              Column({ space: 4 }) {
                Text('林小满')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)

                Text('保育师（三级）备考中')
                  .fontSize(13)
                  .fontColor('#DCE7FF')

                // 连续学习标签
                Row() {
                  Text('连续学习 18 天')
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Color.White)
                }
                .backgroundColor('#33FFFFFF')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(12)
                .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 14 })
              .layoutWeight(1)

              // 右上角设置齿轮按钮
              Stack({ alignContent: Alignment.Center }) {
                Circle()
                  .width(38)
                  .height(38)
                  .fill('#33FFFFFF')

                Text('⚙')
                  .fontSize(19)
                  .fontColor(Color.White)
              }
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 22, bottom: 22 })
            .borderRadius({ topLeft: 22, topRight: 22 })
            .linearGradient({
              angle: 135,
              colors: [['#336AF8', 0.0], ['#234FDE', 1.0]]
            })

            // 下半部分学习数据统计栏（白底）
            Row() {
              this.StatColumn('1,286', '累计答题')
              Divider().vertical(true).height(28).strokeWidth(1).color('#EEF2F6')
              this.StatColumn('76%', '平均正确率')
              Divider().vertical(true).height(28).strokeWidth(1).color('#EEF2F6')
              this.StatColumn('26h', '学习时长')
            }
            .width('100%')
            .padding({ top: 18, bottom: 18 })
            .backgroundColor(Color.White)
            .borderRadius({ bottomLeft: 22, bottomRight: 22 })
          }
          .width('100%')
          .borderRadius(22)
          .shadow({ radius: 12, color: '#142F65F6', offsetY: 4 })

          // ==================== 2. 目标到达卡片 ====================
          Column() {
            // 标题行
            Row() {
              Column({ space: 4 }) {
                Text('当前目标')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2F65F6')

                Text('保育师职业技能等级认定')
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A202C')
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Text('调整目标')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2F65F6')
            }
            .width('100%')

            // 目标里程碑步骤条
            Row() {
              // 阶段 1：初级 (已完成)
              Column({ space: 4 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(28)
                    .height(28)
                    .fill('#2F65F6')
                  Text('✓')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                }
                Text('初级')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2F65F6')
                Text('已完成')
                  .fontSize(11)
                  .fontColor('#059669')
              }

              // 进度连接线 1（实心蓝）
              Row()
                .layoutWeight(1)
                .height(3)
                .backgroundColor('#2F65F6')
                .borderRadius(1.5)
                .margin({ left: 8, right: 8, bottom: 36 })

              // 阶段 2：中级 (备考中)
              Column({ space: 4 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(28)
                    .height(28)
                    .fill('#2F65F6')
                  Text('2')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                }
                Text('中级')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2F65F6')
                Text('备考中')
                  .fontSize(11)
                  .fontColor('#2F65F6')
              }

              // 进度连接线 2（浅灰未达）
              Row()
                .layoutWeight(1)
                .height(3)
                .backgroundColor('#E2E8F0')
                .borderRadius(1.5)
                .margin({ left: 8, right: 8, bottom: 36 })

              // 阶段 3：高级 (待解锁)
              Column({ space: 4 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(28)
                    .height(28)
                    .fill('#F1F5F9')
                  Text('3')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#94A3B8')
                }
                Text('高级')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#94A3B8')
                Text('待解锁')
                  .fontSize(11)
                  .fontColor('#94A3B8')
              }
            }
            .width('100%')
            .padding({ left: 10, right: 10 })
            .alignItems(VerticalAlign.Center)
            .margin({ top: 20 })
          }
          .width('100%')
          .padding(20)
          .borderRadius(22)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#EEF2F6' })
          .shadow({ radius: 6, color: '#06000000', offsetY: 2 })

          // ==================== 3. 功能列表卡片 ====================
          Column() {
            this.FunctionListItem('wrong', '错题本', '48 题')
            Divider().color('#F8FAFC').strokeWidth(1).margin({ left: 52 })
            this.FunctionListItem('plan', '规划与进度', '进行中')
            Divider().color('#F8FAFC').strokeWidth(1).margin({ left: 52 })
            this.FunctionListItem('data', '学习数据', '本周 +12%')
            Divider().color('#F8FAFC').strokeWidth(1).margin({ left: 52 })
            this.FunctionListItem('guide', '考试指南', '2025 版')
            Divider().color('#F8FAFC').strokeWidth(1).margin({ left: 52 })
            this.FunctionListItem('setting', '账号与设置', '')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
          .borderRadius(22)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#EEF2F6' })
          .shadow({ radius: 6, color: '#06000000', offsetY: 2 })
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

  // 学习数据列单项
  @Builder
  StatColumn(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
      Text(label)
        .fontSize(12)
        .fontColor('#8A94A6')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  // 功能列表项
  @Builder
  FunctionListItem(iconType: string, title: string, hint: string) {
    Row() {
      // 浅蓝背景图标容器
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor('#EBF2FF')

        if (iconType === 'wrong') {
          // 错题本图标
          Path()
            .width(18)
            .height(18)
            .commands('M4 3.5H11.5L14.5 6.5V15.5H4ZM6.5 8.5H12M6.5 11.5H12M6.5 13.5H9.5')
            .stroke('#2F65F6')
            .strokeWidth(1.6)
            .fill(Color.Transparent)
            .strokeLineCap(LineCapStyle.Round)
        } else if (iconType === 'plan') {
          // 规划与进度日历图标
          Path()
            .width(18)
            .height(18)
            .commands('M3.5 5H14.5V15H3.5ZM3.5 8H14.5M6 3V6M12 3V6M6.5 11.5L8.5 13.5L12 9.5')
            .stroke('#2F65F6')
            .strokeWidth(1.6)
            .fill(Color.Transparent)
            .strokeLineCap(LineCapStyle.Round)
        } else if (iconType === 'data') {
          // 学习数据柱状图图标
          Path()
            .width(18)
            .height(18)
            .commands('M3 15H15M5 15V10M9 15V6M13 15V8')
            .stroke('#2F65F6')
            .strokeWidth(1.8)
            .fill(Color.Transparent)
            .strokeLineCap(LineCapStyle.Round)
        } else if (iconType === 'guide') {
          // 考试指南开卷图书图标
          Path()
            .width(18)
            .height(18)
            .commands('M2.5 4.5C2.5 3.8 3.3 3.5 4 3.5H8.5V14.5H4C3.3 14.5 2.5 15 2.5 15.5V4.5ZM15.5 4.5C15.5 3.8 14.7 3.5 14 3.5H9.5V14.5H14C14.7 14.5 15.5 15 15.5 15.5V4.5Z')
            .stroke('#2F65F6')
            .strokeWidth(1.6)
            .fill(Color.Transparent)
        } else {
          // 账号与设置盾牌/齿轮图标
          Path()
            .width(18)
            .height(18)
            .commands('M9 2.5A3.5 3.5 0 1 0 9 9.5A3.5 3.5 0 1 0 9 2.5M3.5 16.5A6.5 6.5 0 0 1 15.5 16.5')
            .stroke('#2F65F6')
            .strokeWidth(1.8)
            .fill(Color.Transparent)
        }
      }

      // 功能标题
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
        .margin({ left: 12 })
        .layoutWeight(1)

      // 提示信息与进入箭头
      if (hint !== '') {
        Text(hint)
          .fontSize(12)
          .fontColor('#8A94A6')
          .margin({ right: 6 })
      }

      Text('›')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CBD5E1')
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }
}
