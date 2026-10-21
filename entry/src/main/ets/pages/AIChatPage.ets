import { SafeArea } from '../common/SafeArea';
import { ProfileModel } from '../common/ProfileModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { ChatMessage } from '../model/ChatModels';
import { AIChatViewModel } from '../viewmodel/AIChatViewModel';

@ComponentV2
export struct AIView {
  // ★ 聊天记录、输入态、提问编排全在 ViewModel，页面只渲染、只把异常弹出来。
  //   历史：wuh 分支合进来时这个页面被整个覆盖成了一个 setTimeout 假回复的演示版
  //   （AI_REPLY 写死一句"正在结合考纲为您拆解..."，1 秒后 push 进去），
  //   看起来"能聊"，实际上根本没连后端、更谈不上流式。接线已经恢复，别再退回去。
  @Local vm: AIChatViewModel = new AIChatViewModel();
  // 用户头像：与「我的」页同源（有自定义头像用头像，否则取昵称首字）
  @Local profile: ProfileModel = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;

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

  // 选图：用户取消由 ViewModel 静默处理，其余失败提示出来
  private async pickImage(): Promise<void> {
    try {
      await this.vm.pickImage();
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
                .backgroundColor('#FEF8E3')

              // 品牌 logo：盾牌+书本+嫩芽（与 App 图标同源）
              Image($r('app.media.app_logo'))
                .width(42)
                .height(42)
                .objectFit(ImageFit.Contain)
            }

            // 大标题
            Text('有疑问，随时问')
              .fontSize(30.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#55402F')
              .margin({ top: 24 })

            // 描述副标
            Text('拍题、输入文字或描述困惑，我会结合考纲拆解考点。')
              .fontSize(15.0)
              .fontColor('#9A8A6E')
              .textAlign(TextAlign.Center)
              .lineHeight(20)
              .margin({ top: 12 })
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
            // key 里必须带 content：@Builder 按值传参不会触发刷新，
            // 只有换 key 让这一条整个重建，流式增量才画得出来。
            // 其余消息 key 没变，不会跟着重绘。
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
        .border({ width: 1, color: '#F2ECD8' })
        .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })

        // 已选待发图片预览条
        if (this.vm.pendingImage !== '') {
          Row({ space: 10 }) {
            Image(this.vm.pendingImage)
              .width(56)
              .height(56)
              .borderRadius(10)
              .objectFit(ImageFit.Cover)

            Text('图片将随问题一起发送')
              .fontSize(14.0)
              .fontColor('#9A8A6E')
              .layoutWeight(1)

            Text('×')
              .fontSize(24.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#8A7A50')
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
          .border({ width: 1, color: '#F2ECD8' })
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
              .backgroundColor('#FEF8E3')
              .border({ width: 1, color: '#F2ECD8' })

            Text('+')
              .fontSize(24.0)
              .fontColor('#8A7A50')
              .fontWeight(FontWeight.Medium)
          }
          // Stack 不写死尺寸时在 Row 里可能被量成 0 宽，视觉上按钮还在，
          // 但点击热区是空的。这里必须显式给尺寸。
          .width(40)
          .height(40)
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.pickImage();
          })

          // 文本输入框。用 !! 双向绑定而不是 text+onChange 回写：
          // 回写会在输入法组词（拼音候选）阶段把值再推回组件，有打断组合态的风险。
          TextInput({ text: this.vm.inputText!!, placeholder: '输入题目或粘贴题干…' })
            .placeholderColor('#B5A98D')
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .fontSize(16.0)
            .margin({ left: 8, right: 8 })
            .enterKeyType(EnterKeyType.Send)
            .onSubmit((enterKey: EnterKeyType) => {
              if (enterKey === EnterKeyType.Send && this.vm.canSend) {
                this.send();
              }
            })

          // 发送/提问按钮：有内容时高亮为品牌橙，无内容置灰；发送中显示 loading
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(42)
              .height(42)
              .borderRadius(14)
              .backgroundColor(this.vm.sending || this.vm.canSend ? '#E4842A' : '#F0E8D2')
              .shadow({
                radius: 6,
                color: this.vm.sending || this.vm.canSend ? '#33E4842A' : '#00000000',
                offsetY: 2
              })
              .animation({ duration: 150, curve: Curve.EaseOut })

            if (this.vm.sending) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(Color.White)
            } else {
              Image($r('app.media.send'))
                .width(19)
                .height(19)
                .objectFit(ImageFit.Contain)
                .fillColor(this.vm.canSend ? Color.White : '#B5A98D')
                .animation({ duration: 150, curve: Curve.EaseOut })
            }
          }
          .width(42)
          .height(42)
          .hitTestBehavior(HitTestMode.Block)
          .opacity(this.vm.sending || this.vm.canSend ? 1 : 0.85)
          .enabled(this.vm.canSend)
          .onClick(() => {
            this.send();
          })
        }
        .width('100%')
        .padding({ left: 6, right: 6, top: 5, bottom: 5 })
        .borderRadius(20)
        .backgroundColor(Color.White)
        .border({ width: 1, color: '#F2ECD8' })
        .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })
        .margin({ top: 16 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 84 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
    // 沉浸式：底色铺进状态栏，内容自动让出状态栏高度（适配各机型，不影响内容排版）
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .padding({ top: SafeArea.topVp })
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
            .border({ width: 1, color: '#F2ECD8' })

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
          // ★ 千万别给这个 Text 加 .width('100%')，这是修过的老 bug。
          //   外层 Column 没有确定宽度，只有 constraintSize({ maxWidth: '72%' })，
          //   宽度由子内容决定；子元素再要 100% 就形成循环依赖，ArkUI 会把 100%
          //   解成整屏宽——Text 按整屏排版，Column 却卡在 72%，文字就画到气泡外面。
          Text(msg.content)
            .fontSize(16.0)
            .lineHeight(21)
            .fontColor(msg.from === 'user' ? Color.White : '#55402F')
            // AI 回复里常夹长 URL / 长英文单词：NORMAL 只在空格换行，塞不下就撑破
            // 气泡。BREAK_WORD 优先按词换、词太长才拆字，中文仍按字换行
            .wordBreak(WordBreak.BREAK_WORD)
        }
      }
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .borderRadius(14)
      .backgroundColor(msg.from === 'user' ? '#E4842A' : Color.White)
      .border(msg.from === 'user' ?
        { width: 0 } :
        { width: 1, color: '#F2ECD8' })
      .shadow(msg.from === 'user' ?
        { radius: 6, color: '#26E4842A', offsetY: 2 } :
        { radius: 4, color: '#0A000000', offsetY: 1 })
      .constraintSize({ maxWidth: '72%' })
      .alignItems(HorizontalAlign.Start)

      if (msg.from === 'user') {
        // 用户头像：右侧，与 AI 头像对称（有自定义头像用头像，否则昵称首字占位）
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(32)
            .height(32)
            .borderRadius(16)
            .backgroundColor('#FEF8E3')
            .border({ width: 1, color: '#F2ECD8' })

          if (this.profile.avatarUri !== '') {
            Image(this.profile.avatarUri)
              .width(32)
              .height(32)
              .borderRadius(16)
              .objectFit(ImageFit.Cover)
          } else {
            Text(this.profile.nickname !== '' ? this.profile.nickname.substring(0, 1) : '我')
              .fontSize(14.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E4842A')
          }
        }
        .margin({ left: 8 })
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
        .fontColor(this.vm.selectedMode === modeIndex ? '#E4842A' : '#8A7A50')
    }
    .layoutWeight(1)
    .height(42)
    .borderRadius(22)
    .backgroundColor(this.vm.selectedMode === modeIndex ? '#FEF8E3' : Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.vm.selectedMode = modeIndex;
    })
  }
}
