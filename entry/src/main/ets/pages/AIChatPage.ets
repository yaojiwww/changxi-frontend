@ComponentV2
export struct AIView {
  @Local selectedMode: number = 0;
  @Local inputText: string = '';

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          // ==================== 核心 AI 伴学主卡片 ====================
          Column() {
            // 1. 卡片顶栏：育见 AI 与对话记录
            Row() {
              // 品牌 Logo 与状态
              Row({ space: 12 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Row()
                    .width(42)
                    .height(42)
                    .borderRadius(13)
                    .backgroundColor('#2F65F6')
                    .shadow({ radius: 8, color: '#332F65F6', offsetY: 3 })

                  // 星光矢量图标
                  Text('✨')
                    .fontSize(18)
                    .fontColor(Color.White)
                }

                Column({ space: 3 }) {
                  Text('育见 AI')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1A202C')

                  Row({ space: 5 }) {
                    Circle()
                      .width(6)
                      .height(6)
                      .fill('#10B981')

                    Text('已接入你的学习数据与保育师考纲')
                      .fontSize(11)
                      .fontColor('#8A94A6')
                  }
                  .alignItems(VerticalAlign.Center)
                }
                .alignItems(HorizontalAlign.Start)
              }

              Blank()

              // 对话记录按钮
              Row({ space: 4 }) {
                Path()
                  .width(14)
                  .height(14)
                  .commands('M7 1A6 6 0 1 0 7 13A6 6 0 1 0 7 1M7 4V7L9.5 9.5')
                  .stroke('#4A5568')
                  .strokeWidth(1.5)
                  .fill(Color.Transparent)

                Text('对话记录')
                  .fontSize(12)
                  .fontColor('#4A5568')
              }
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(16)
              .border({ width: 1, color: '#E2E8F0' })
              .backgroundColor('#F8FAFC')
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(1)
              .color('#F1F5F9')
              .margin({ top: 16, bottom: 22 })

            // 2. 中间引导与问答主题区
            Column() {
              // 居中大对话气泡图标
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(58)
                  .height(58)
                  .borderRadius(18)
                  .backgroundColor('#EBF2FF')

                Path()
                  .width(26)
                  .height(26)
                  .commands('M4 5A3 3 0 0 1 7 2H17A3 3 0 0 1 20 5V13A3 3 0 0 1 17 16H10L5 19V16A3 3 0 0 1 4 13Z')
                  .stroke('#2F65F6')
                  .strokeWidth(1.8)
                  .fill(Color.Transparent)

                Path()
                  .width(10)
                  .height(6)
                  .commands('M2 2H8M2 5H6')
                  .stroke('#2F65F6')
                  .strokeWidth(1.6)
                  .strokeLineCap(LineCapStyle.Round)
              }
              .margin({ bottom: 4 })

              // 专属教练小标
              Text('你的专属备考教练')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2F65F6')
                .margin({ top: 10, bottom: 6 })

              // 大标题
              Text('有疑问，随时问')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A202C')
                .margin({ bottom: 8 })

              // 描述副标
              Text('拍题、输入文字或描述困惑，我会结合考纲拆解考点。')
                .fontSize(12)
                .fontColor('#8A94A6')
                .textAlign(TextAlign.Center)
                .lineHeight(18)
                .margin({ bottom: 22 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)

            // 3. 智能推荐标题
            Row({ space: 4 }) {
              Text('✨')
                .fontSize(12)
                .fontColor('#2F65F6')

              Text('已结合你近 7 天的答题表现，为你优先推荐')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2F65F6')
            }
            .width('100%')
            .margin({ bottom: 12 })

            // 4. 三张优先推荐问题卡片（横向滚动）
            Scroll() {
              Row({ space: 10 }) {
                this.RecommendQuestionCard('幼儿鼻出血时\n应该怎么处理？')
                this.RecommendQuestionCard('这道题为什么\n不能选 A？')
                this.RecommendQuestionCard('帮我总结儿童\n意外伤害考点')
              }
              .padding({ right: 4 })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
            .margin({ bottom: 24 })

            // 5. 功能模式选择胶囊栏
            Row() {
              this.ModeTabItem('题目解答', 'chat', 0)
              this.ModeTabItem('专属规划', 'calendar', 1)
              this.ModeTabItem('全程伴考', 'target', 2)
            }
            .padding(4)
            .borderRadius(20)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#EEF2F6' })
            .shadow({ radius: 6, color: '#08000000', offsetY: 2 })
            .margin({ bottom: 14 })

            // 6. 输入框区域
            Row() {
              // 拍照/上传题干加号按钮
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(40)
                  .height(40)
                  .borderRadius(13)
                  .backgroundColor('#F8FAFC')
                  .border({ width: 1, color: '#E2E8F0' })

                Text('+')
                  .fontSize(22)
                  .fontColor('#64748B')
                  .fontWeight(FontWeight.Medium)
              }

              // 文本输入框
              TextInput({ text: this.inputText, placeholder: '输入题目或粘贴题干…' })
                .placeholderColor('#94A3B8')
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .fontSize(14)
                .margin({ left: 8, right: 8 })
                .onChange((value: string) => {
                  this.inputText = value;
                })

              // 发送/提问按钮
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(40)
                  .height(40)
                  .borderRadius(13)
                  .backgroundColor('#2F65F6')
                  .shadow({ radius: 6, color: '#332F65F6', offsetY: 2 })

                Path()
                  .width(18)
                  .height(18)
                  .commands('M2.5 9L16.5 2.5L9.5 16.5L8 10.5L2.5 9Z')
                  .fill(Color.White)
              }
              .onClick(() => {
                if (this.inputText.trim() !== '') {
                  this.inputText = '';
                }
              })
            }
            .width('100%')
            .padding({ left: 6, right: 6, top: 5, bottom: 5 })
            .borderRadius(18)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#E2E8F0' })
            .shadow({ radius: 6, color: '#08000000', offsetY: 2 })

            // 7. 底部免责声明
            Text('AI 内容仅供学习参考，请以官方考试大纲为准')
              .fontSize(11)
              .fontColor('#94A3B8')
              .textAlign(TextAlign.Center)
              .margin({ top: 12, bottom: 4 })
          }
          .width('100%')
          .padding(20)
          .borderRadius(22)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#EEF2F6' })
          .shadow({ radius: 8, color: '#082F65F6', offsetY: 3 })
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 84 })
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

  // 推荐问题单个卡片
  @Builder
  RecommendQuestionCard(content: string) {
    Row() {
      // 左侧对话图标
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(32)
          .height(32)
          .borderRadius(10)
          .backgroundColor('#EBF2FF')

        Path()
          .width(14)
          .height(14)
          .commands('M2 3A2 2 0 0 1 4 1H10A2 2 0 0 1 12 3V8A2 2 0 0 1 10 10H6L3 12V10A2 2 0 0 1 2 8Z')
          .stroke('#2F65F6')
          .strokeWidth(1.4)
          .fill(Color.Transparent)
      }

      // 中间问题内容
      Text(content)
        .fontSize(12.5)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A202C')
        .lineHeight(17)
        .margin({ left: 8 })
        .layoutWeight(1)

      // 右侧小箭头
      Text('→')
        .fontSize(13)
        .fontColor('#94A3B8')
        .margin({ left: 4 })
    }
    .width(185)
    .height(76)
    .padding({ left: 12, right: 10, top: 10, bottom: 10 })
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#EEF2F6' })
    .shadow({ radius: 4, color: '#06000000', offsetY: 1 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.inputText = content.replace('\n', '');
    })
  }

  // 模式切换胶囊单项
  @Builder
  ModeTabItem(title: string, iconType: string, modeIndex: number) {
    Row({ space: 5 }) {
      if (iconType === 'chat') {
        Path()
          .width(14)
          .height(14)
          .commands('M2 3A2 2 0 0 1 4 1H10A2 2 0 0 1 12 3V8A2 2 0 0 1 10 10H6L3 12V10A2 2 0 0 1 2 8Z')
          .stroke(this.selectedMode === modeIndex ? '#2F65F6' : '#8A94A6')
          .strokeWidth(1.4)
          .fill(Color.Transparent)
      } else if (iconType === 'calendar') {
        Path()
          .width(14)
          .height(14)
          .commands('M2.5 4H11.5V12H2.5ZM2.5 6.5H11.5M4.5 2V5M9.5 2V5')
          .stroke(this.selectedMode === modeIndex ? '#2F65F6' : '#8A94A6')
          .strokeWidth(1.4)
          .fill(Color.Transparent)
      } else {
        Path()
          .width(14)
          .height(14)
          .commands('M7 1A6 6 0 1 0 7 13A6 6 0 1 0 7 1M7 4A3 3 0 1 0 7 10A3 3 0 1 0 7 4')
          .stroke(this.selectedMode === modeIndex ? '#2F65F6' : '#8A94A6')
          .strokeWidth(1.4)
          .fill(Color.Transparent)
      }

      Text(title)
        .fontSize(12)
        .fontWeight(this.selectedMode === modeIndex ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.selectedMode === modeIndex ? '#2F65F6' : '#8A94A6')
    }
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .borderRadius(16)
    .backgroundColor(this.selectedMode === modeIndex ? '#EBF2FF' : Color.Transparent)
    .onClick(() => {
      this.selectedMode = modeIndex;
    })
  }
}
