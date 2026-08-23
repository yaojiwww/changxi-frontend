// Index.ets
import router from '@ohos.router';
import { SideMenu } from './SideMenu';

@Entry
@Component
struct Index {
  @State inputValue: string = '';
  @State isMenuVisible: boolean = false;

  // ================= 核心业务状态机 =================
  // 阶段控制: 'idle'(主页) | 'pre_test'(摸底) | 'training'(HTML学习) | 'post_test'(结业)
  @State currentStage: string = 'idle';

  // 测试相关状态
  @State currentQuestionIndex: number = 0;
  @State selectedOption: number = -1;
  private totalQuestions: number = 5;

  // 模拟题目数据
  private questions: string[] = [
    '1. 发现有人倒地，第一步应该做什么？',
    '2. 心肺复苏的正确按压频率是？',
    '3. 使用AED前需要做什么？',
    '4. 气道异物梗阻的首选急救方法是？',
    '5. 急救电话是多少？'
  ];

  // ================= 流程控制函数 =================

  // 1. 开启急救培训流程
  startTraining() {
    this.currentQuestionIndex = 0;
    this.selectedOption = -1;
    this.currentStage = 'pre_test'; // 进入摸底测试
  }

  // 2. 测试中点击“下一题”
  nextQuestion() {
    if (this.currentQuestionIndex < this.totalQuestions - 1) {
      this.currentQuestionIndex++;
      this.selectedOption = -1; // 重置选项
    } else {
      // 已经是最后一题，完成当前阶段的测试
      this.finishCurrentStage();
    }
  }

  // 3. 点击“跳过”或测试完成
  finishCurrentStage() {
    if (this.currentStage === 'pre_test') {
      // 摸底结束，进入 HTML 学习
      this.currentStage = 'training';
    } else if (this.currentStage === 'post_test') {
      // 结业结束，整个流程完成，回到主页
      this.currentStage = 'idle';
    }
  }

  // 4. HTML 学习结束（点击完成或返回）
  finishTraining() {
    this.currentQuestionIndex = 0;
    this.selectedOption = -1;
    this.currentStage = 'post_test'; // 进入结业测试
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {

      // ==========================================
      // 第一部分：主界面
      // ==========================================
      Column() {
        Row() {
          Text('☰')
            .fontSize(26)
            .fontColor('#999')
            .margin({ left: 16, top: 10 })
            .onClick(() => { this.isMenuVisible = true; })
        }
        .width('100%')

        Blank()

        Column() {
          Row({ space: 10 }) {
            // 【触发点】点击急救培训
            Button('急救培训')
              .fontSize(15)
              .backgroundColor('#EAEAEA')
              .fontColor('#333')
              .borderRadius(20)
              .onClick(() => { this.startTraining(); })

            Button('知识测试').fontSize(15).backgroundColor('#EAEAEA').fontColor('#333').borderRadius(20)
            Button('实战演练').fontSize(15).backgroundColor('#EAEAEA').fontColor('#333').borderRadius(20)
          }
          .width('100%')
          .margin({ bottom: 12 })
          .justifyContent(FlexAlign.SpaceEvenly)

          Row() {
            Image($r('app.media.xiangj'))
              .width(28).height(28).fillColor('#999')

            TextInput({ placeholder: '点击输入...', text: this.inputValue })
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .fontSize(16)
              .margin({ left: 8 })

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
      // 第二部分：侧边栏菜单
      // ==========================================
      if (this.isMenuVisible) {
        Column() {}
        .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { this.isMenuVisible = false; })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
        .zIndex(99)
      }
      if (this.isMenuVisible) {
        SideMenu({ onClose: () => { this.isMenuVisible = false; } })
          .width('75%').height('100%').backgroundColor(Color.White)
          .translate({ x: this.isMenuVisible ? 0 : '-100%' })
          .animation({ duration: 300, curve: Curve.EaseOut })
          .zIndex(100)
      }

      // ==========================================
      // 第三部分：通用测试弹窗 (摸底 & 结业复用)
      // ==========================================
      if (this.currentStage === 'pre_test' || this.currentStage === 'post_test') {
        // 遮罩层
        Column() {}
        .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.6)')
        .zIndex(200)

        // 弹窗主体
        Column() {
          // 头部：标题 + 跳过
          Row() {
            Text(this.currentStage === 'pre_test' ? '培训摸底测试' : '培训结业测试')
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
            Blank()
            Text('跳过')
              .fontSize(16).fontColor('#666')
              .onClick(() => { this.finishCurrentStage(); })
          }
          .width('100%').padding({ left: 24, right: 24, top: 24, bottom: 12 })

          // 题目区域
          Scroll() {
            Column({ space: 15 }) {
              Text(this.questions[this.currentQuestionIndex])
                .fontSize(16).fontColor('#333').width('100%').textAlign(TextAlign.Start)

              // 4个选项
              ForEach([1, 2, 3, 4], (item: number) => {
                Row() {
                  Text(`选项 ${item}`)
                    .fontSize(16)
                    .fontColor(this.selectedOption === item ? '#FFFFFF' : '#333333')
                }
                .width('100%').height(50).padding({ left: 20 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor(this.selectedOption === item ? '#0D8AFF' : '#F5F5F5')
                .borderRadius(12)
                .onClick(() => { this.selectedOption = item; })
              })
            }
            .width('100%').padding({ left: 24, right: 24, bottom: 20 })
          }
          .layoutWeight(1).width('100%').scrollBar(BarState.Off)

          // 底部按钮
          Button(this.currentQuestionIndex === this.totalQuestions - 1 ? '完成' : '下一题')
            .width('90%').height(48).backgroundColor('#0D8AFF')
            .borderRadius(24).fontSize(18).fontColor(Color.White).margin({ bottom: 30 })
            .onClick(() => { this.nextQuestion(); })
        }
        .width('90%').height('60%').backgroundColor(Color.White).borderRadius(24)
        .position({ x: '5%', y: '20%' })
        .zIndex(201)
        .transition(TransitionEffect.translate({ y: 100 }).combine(TransitionEffect.opacity(1).animation({ duration: 300 })))
      }

      // ==========================================
      // 第四部分：急救培训内容页 (HTML渲染区)
      // ==========================================
      if (this.currentStage === 'training') {
        Column() {
          Row() {
            Text('< 返回').fontSize(16).fontColor('#333')
              .onClick(() => { this.finishTraining(); })
            Blank()
            Text('急救培训过程').fontSize(18).fontWeight(FontWeight.Bold)
            Blank()
            Text('').width(40) // 占位
          }
          .width('100%').height(50).padding({ left: 20, right: 20 }).alignItems(VerticalAlign.Center)

          // 【你的 HTML 渲染区域】
          Column() {
            Text('这里放置你的 Web 组件')
              .fontSize(20).fontColor('#999')
              .width(200).height(200).backgroundColor('#EEE').borderRadius(100)
              .textAlign(TextAlign.Center).alignSelf(ItemAlign.Center).margin({ top: 100 })

            Text('HTML 动画演示内容...')
              .fontSize(16).margin({ top: 20 })
          }
          .layoutWeight(1).width('100%').backgroundColor('#F9F9F9')

          // 学习完成按钮
          Button('我已完成学习')
            .width('80%').height(48).backgroundColor('#0D8AFF')
            .borderRadius(24).fontSize(18).fontColor(Color.White).margin({ bottom: 40 })
            .onClick(() => { this.finishTraining(); })
        }
        .width('100%').height('100%').backgroundColor(Color.White).zIndex(150)
        .zIndex(150)
        .transition(
          TransitionEffect.opacity(1)
            .animation({ duration: 300, curve: Curve.EaseInOut })
        )
      }

    } // End Stack
    .width('100%').height('100%')
  }
}