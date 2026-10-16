import { ChatMessage } from '../model/ChatModels';
import { AIChatViewModel } from '../viewmodel/AIChatViewModel';

@ComponentV2
export struct AIView {
  // 聊天记录、输入态、提问编排全在 ViewModel；页面只渲染、只把异常弹出来
  @Local vm: AIChatViewModel = new AIChatViewModel();

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    await this.vm.init(ctx);
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  // 发送：交给 ViewModel 发一轮流式提问，失败提示原因
  private async send(): Promise<void> {
    try {
      await this.vm.send();
    } catch (err) {
      this.toast((err as Error).message);
    }
  }

  build() {
    Column() {
      // ============ 上部：居中引导区（有聊天记录后隐藏） ============
      if (!this.vm.hasChat) {
        Scroll() {
          Column() {
            Row()
              .width('100%')

            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(76)
                .height(76)
                .borderRadius(24)
                .backgroundColor('#E8F0FF')

              // 替换为 service 图标
              Image($r('app.media.maop'))
                .width(34)
                .height(34)
                .objectFit(ImageFit.Contain)
                .fillColor('#3B6BF6')
            }

            // 专属教练小标
            Text('你的专属备考教练')
              .fontSize(16.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#3B6BF6')
              .margin({ top: 20 })

            // 大标题
            Text('有疑问，随时问')
              .fontSize(30.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A202C')
              .margin({ top: 12 })

            // 描述副标
            Text('拍题、输入文字或描述困惑，我会结合考纲拆解考点。')
              .fontSize(15.0)
              .fontColor('#8A94A6')
              .textAlign(TextAlign.Center)
              .lineHeight(20)
              .margin({ top: 12 })

            // 智能推荐提示
            Row({ space: 6 }) {
              Text('✦')
                .fontSize(15.0)
                .fontWeight(FontWeight.Bold)
                .fontColor('#3B6BF6')

              Text('已结合你近 7 天的答题表现，为你优先推荐')
                .fontSize(14.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#3B6BF6')
            }
            .margin({ top: 24 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          .alignItems(HorizontalAlign.Center)
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .width('100%')
      }

      // ============ 中部：聊天记录区（Tab 下方、输入框上方） ============
      if (this.vm.hasChat) {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.vm.chatList, (msg: ChatMessage, idx: number) => {
              this.ChatItem(msg)
            }, (msg: ChatMessage, idx: number) => `${idx}_${msg.from}_${msg.type}_${msg.content}_${msg.imageUri}`)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .width('100%')
      }

      // ============ 下部：模式切换 + 输入框 + 免责声明 ============
      Column() {
        // 功能模式选择胶囊栏（题目解答 / 专属规划）
        Row() {
          this.ModeTabItem('题目解答', 0)
          this.ModeTabItem('专属规划', 1)
        }
        .width('100%')
        .padding(5)
        .borderRadius(24)
        .backgroundColor(Color.White)
        .border({ width: 1, color: '#ECECF2' })
        .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })

        // 已选待发图片预览条
        if (this.vm.pendingImage !== '') {
          Row({ space: 10 }) {
            Image(this.vm.pendingImage)
              .width(56)
              .height(56)
              .borderRadius(10)
              .objectFit(ImageFit.Cover)

            Text('图片已就绪，点击发送即可提问')
              .fontSize(14.0)
              .fontColor('#8A94A6')
              .layoutWeight(1)

            Text('×')
              .fontSize(24.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#6B7280')
              .padding({ left: 8, right: 4, top: 4, bottom: 4 })
              .onClick(() => {
                this.vm.removePendingImage();
              })
          }
          .width('100%')
          .padding(8)
          .margin({ top: 10 })
          .borderRadius(12)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#ECECF2' })
          .alignItems(VerticalAlign.Center)
        }

        // 输入框区域
        Row() {
          // 拍照/上传题干加号按钮
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(40)
              .height(40)
              .borderRadius(13)
              .backgroundColor('#F4F5F8')
              .border({ width: 1, color: '#ECECF2' })

            Text('+')
              .fontSize(24.0)
              .fontColor('#6B7280')
              .fontWeight(FontWeight.Medium)
          }
          .onClick(() => {
            this.vm.pickImage();
          })

          // 文本输入框
          TextInput({ text: this.vm.inputText, placeholder: '输入题目或粘贴题干…' })
            .placeholderColor('#9AA0AC')
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .fontSize(16.0)
            .margin({ left: 8, right: 8 })
            .onChange((value: string) => {
              this.vm.inputText = value;
            })

          // 发送/提问按钮
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(42)
              .height(42)
              .borderRadius(14)
              .backgroundColor('#F4F5F9')
              .shadow({ radius: 6, color: '#333B6BF6', offsetY: 2 })

            // 替换为 send 图标
            Image($r('app.media.send'))
              .width(19)
              .height(19)
              .objectFit(ImageFit.Contain)
          }

          .onClick(() => {
            this.send();
          })
        }
        .width('100%')
        .padding({ left: 6, right: 6, top: 5, bottom: 5 })
        .borderRadius(20)
        .backgroundColor(Color.White)
        .border({ width: 1, color: '#ECECF2' })
        .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })
        .margin({ top: 16 })
        .alignItems(VerticalAlign.Center)

        // 底部免责声明
        Text('AI 内容仅供学习参考，请以官方考试大纲为准')
          .fontSize(13.0)
          .fontColor('#B0B6C3')
          .textAlign(TextAlign.Center)
          .margin({ top: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 84 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB')
  }

  // 单条聊天消息：用户右侧主色气泡，AI 左侧白底气泡；图片直接渲染预览
  @Builder
  ChatItem(msg: ChatMessage) {
    Row() {
      if (msg.from === 'ai') {
        // AI 头像：IP 兜兜
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(32)
            .height(32)
            .borderRadius(16)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#E4EAF5' })

          Image($r('app.media.ip_main'))
            .width(26)
            .height(26)
            .objectFit(ImageFit.Contain)
        }
        .margin({ right: 8 })
      }

      Column({ space: 6 }) {
        if (msg.type === 'image' && msg.imageUri !== '') {
          Image(msg.imageUri)
            .width(180)
            .height(180)
            .borderRadius(12)
            .objectFit(ImageFit.Cover)
        }
        if (msg.content !== '') {
          // ★ 这里以前有 .width('100%')，文字会溢出气泡，必须去掉。
          //   百分号宽度要吃父容器宽度，而外层 Column 没有确定宽度——它只有
          //   constraintSize({ maxWidth: '72%' })，宽度本身由子内容决定。循环依赖下
          //   ArkUI 把 100% 解成了整屏宽，于是 Text 按整屏排，Column 却卡在 72%，
          //   文字就画到气泡外面去了。不给宽度，Text 才按 Column 的上限换行。
          Text(msg.content)
            .fontSize(16.0)
            .lineHeight(21)
            .fontColor(msg.from === 'user' ? Color.White : '#1A202C')
            // AI 回复里经常夹长 URL 或长英文单词：NORMAL 只在空格处换行，遇到塞不下的
            // 东西会直接撑破气泡。BREAK_WORD 优先按词换、词太长才拆字，中文仍按字换行
            .wordBreak(WordBreak.BREAK_WORD)
        }
      }
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .borderRadius(14)
      .backgroundColor(msg.from === 'user' ? '#3B6BF6' : Color.White)
      .border(msg.from === 'user' ?
        { width: 0 } :
        { width: 1, color: '#ECECF2' })
      .shadow(msg.from === 'user' ?
        { radius: 6, color: '#263B6BF6', offsetY: 2 } :
        { radius: 4, color: '#0A000000', offsetY: 1 })
      .constraintSize({ maxWidth: '72%' })
      .alignItems(HorizontalAlign.Start)

      if (msg.from === 'user') {
        Row()
          .width(8)
      }
    }
    .width('100%')
    .justifyContent(msg.from === 'user' ? FlexAlign.End : FlexAlign.Start)
    .alignItems(VerticalAlign.Top)
  }

  // 模式切换胶囊单项
  @Builder
  ModeTabItem(title: string, modeIndex: number) {
    Row() {
      Text(title)
        .fontSize(16.0)
        .fontWeight(this.vm.selectedMode === modeIndex ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.vm.selectedMode === modeIndex ? '#3B6BF6' : '#6B7280')
    }
    .layoutWeight(1)
    .height(42)
    .borderRadius(22)
    .backgroundColor(this.vm.selectedMode === modeIndex ? '#E8F0FF' : Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.vm.selectedMode = modeIndex;
    })
  }
}
