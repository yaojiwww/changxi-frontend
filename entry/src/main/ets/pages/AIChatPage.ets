import { SafeArea } from '../common/SafeArea';
import { ProfileModel } from '../common/ProfileModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { ChatMessage, PendingImage } from '../model/ChatModels';
import { AIChatViewModel } from '../viewmodel/AIChatViewModel';
import { NavSignal, takePendingAsk, takePendingQuestion } from '../common/NavSignal';

@ComponentV2
export struct AIView {
  // ★ 聊天记录、输入态、提问编排全在 ViewModel，页面只渲染、只把异常弹出来。
  //   历史：wuh 分支合进来时这个页面被整个覆盖成了一个 setTimeout 假回复的演示版
  //   （AI_REPLY 写死一句"正在结合考纲为您拆解..."，1 秒后 push 进去），
  //   看起来"能聊"，实际上根本没连后端、更谈不上流式。接线已经恢复，别再退回去。
  @Local vm: AIChatViewModel = new AIChatViewModel();
  // 用户头像：与「我的」页同源（有自定义头像用头像，否则取昵称首字）
  @Local profile: ProfileModel = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
  // 知识库跨页带来的提问上下文。AIView 是 Tab 组件、不是路由页，
  // 拿不到 pushUrl 参数，只能通过这个共享信号消费一次。
  @Local nav: NavSignal = AppStorageV2.connect(NavSignal, () => new NavSignal())!;

  // 聊天滚动控制：新消息 / 流式增量让内容变高时自动贴到底部
  private chatScroller: Scroller = new Scroller();
  private autoFollow: boolean = true;   // 用户往回翻看时暂停跟随，滚回底部再恢复
  private contentHeight: number = 0;
  private viewportHeight: number = 0;

  async aboutToAppear(): Promise<void> {
    // 可能 AIView 是刚创建的：先把已经写好的知识点/题目接住
    this.consumePendingAsk();
    this.consumePendingQuestion();
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    await this.vm.init(ctx);
  }

  // AIView 已经存在时，知识库写入 pendingAsk 会触发这里；
  // takePendingAsk 会把它清空，所以同一次提问只会被消费一次。
  @Monitor('nav.pendingAsk')
  onPendingAskChanged(): void {
    this.consumePendingAsk();
  }

  // 练习/报告页写入 pendingQuestion 时触发，同样只消费一次
  @Monitor('nav.pendingQuestion')
  onPendingQuestionChanged(): void {
    this.consumePendingQuestion();
  }

  private consumePendingAsk(): void {
    if (this.nav.pendingAsk === null) {
      return;
    }
    const ctx = takePendingAsk();
    if (ctx !== null) {
      this.vm.applyAskContext(ctx);
    }
  }

  private consumePendingQuestion(): void {
    if (this.nav.pendingQuestion === '') {
      return;
    }
    const text: string = takePendingQuestion();
    this.vm.applyPendingQuestion(text);
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  // 发送：交给 ViewModel 发一轮流式提问，失败提示原因
  private async send(): Promise<void> {
    // 用户主动提问时强制恢复跟随：哪怕刚才在翻旧消息，也要把新问题顶到眼前
    this.autoFollow = true;
    try {
      await this.vm.send();
    } catch (err) {
      this.toast((err as Error).message);
    }
  }

  // 距底部小于该距离就算"贴底"，留 48 的容差，避免回弹和像素误差误判
  private isNearBottom(): boolean {
    const offset: number = this.chatScroller.currentOffset().yOffset;
    return this.contentHeight - offset - this.viewportHeight <= 48;
  }

  // 内容变高（新消息、流式增量、键盘顶起视口）时贴底；用户翻旧消息时不打扰
  private keepAtBottom(): void {
    if (this.autoFollow) {
      this.chatScroller.scrollEdge(Edge.Bottom);
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
        Scroll(this.chatScroller) {
          Column({ space: 12 }) {
            // key 里必须带 content：@Builder 按值传参不会触发刷新，
            // 只有换 key 让这一条整个重建，流式增量才画得出来。
            // 其余消息 key 没变，不会跟着重绘。
            ForEach(this.vm.chatList, (msg: ChatMessage, idx: number) => {
              this.ChatItem(msg)
            }, (msg: ChatMessage, idx: number) =>
              `${idx}_${msg.from}_${msg.type}_${msg.content}_${msg.imageUris.join(',')}`)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          // 气泡长高（新消息 / 流式增量）后贴底，不用用户手动翻
          .onAreaChange((_oldValue: Area, newValue: Area) => {
            this.contentHeight = newValue.height as number;
            this.keepAtBottom();
          })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .width('100%')
        // 视口变化（键盘顶起/收起）也保持贴底
        .onAreaChange((_oldValue: Area, newValue: Area) => {
          this.viewportHeight = newValue.height as number;
          this.keepAtBottom();
        })
        // 用户一开始滚就立刻暂停跟随。不能等滚出容差再停：
        // 流式增量帧率很高，用户还没滑开就会被下一次贴底拽回去
        .onWillScroll((_xOffset: number, _yOffset: number, _scrollState: ScrollState,
          source: ScrollSource) => {
          if (source === ScrollSource.DRAG || source === ScrollSource.FLING ||
            source === ScrollSource.SCROLL_BAR || source === ScrollSource.OTHER_USER_INPUT) {
            this.autoFollow = false;
          }
        })
        // 滚完再看停在哪：停在底部就恢复跟随，停在中间就保持暂停
        .onScrollStop(() => {
          this.autoFollow = this.isNearBottom();
        })
        // 兜底：手指一碰到聊天区就先让位，保证任何时候都能手动往上滑
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.autoFollow = false;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.autoFollow = this.isNearBottom();
          }
        })
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

        // 知识点上下文：从 AI 知识库选中知识点后显示，可随时关闭
        if (this.vm.hasAskContext) {
          Row({ space: 8 }) {
            Text('知识点')
              .fontSize(11.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E4842A')
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .borderRadius(8)
              .backgroundColor('#FEF8E3')

            Text(this.vm.askContextLabel())
              .fontSize(13.0)
              .fontColor('#8A7A50')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('×')
              .fontSize(21.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#8A7A50')
              .padding({ left: 6, right: 4, top: 2, bottom: 2 })
              .onClick(() => {
                this.vm.clearAskContext();
              })
          }
          .width('100%')
          .padding({ left: 10, right: 6, top: 7, bottom: 7 })
          .margin({ top: 10 })
          .borderRadius(12)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#F2ECD8' })
          .alignItems(VerticalAlign.Center)
        }

        // 已选待发图片预览条：最多 4 张，上传中盖转圈，右上角可单张删除
        if (this.vm.pendingImages.length > 0) {
          Row() {
            ForEach(this.vm.pendingImages, (item: PendingImage) => {
              Stack({ alignContent: Alignment.TopEnd }) {
                Stack({ alignContent: Alignment.Center }) {
                  Image(item.uri)
                    .width(56)
                    .height(56)
                    .borderRadius(10)
                    .objectFit(ImageFit.Cover)
                    .opacity(item.uploading ? 0.45 : 1)

                  if (item.uploading) {
                    LoadingProgress()
                      .width(22)
                      .height(22)
                      .color('#E4842A')
                  }
                }
                .width(56)
                .height(56)

                // 上传中也能删：上传结果回来时按 id 找不到这张，会被静默丢弃
                Text('×')
                  .fontSize(18.0)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
                  .textAlign(TextAlign.Center)
                  .width(18)
                  .height(18)
                  .lineHeight(18)
                  .borderRadius(9)
                  .backgroundColor('#99000000')
                  .onClick(() => {
                    this.vm.removePendingImage(item.id);
                  })
              }
              .width(56)
              .height(56)
              .margin({ right: 8 })
            }, (item: PendingImage) => `${item.id}_${item.fileId}_${item.uploading}`)
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
    // 兜底：AIView 已存在但 @Monitor 没触发时，页签切到可见也能接住知识点
    .onVisibleAreaChange([0.0, 0.01], (isVisible: boolean) => {
      if (isVisible) {
        this.consumePendingAsk();
      }
    })
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
        if (msg.type === 'image' && msg.imageUris.length > 0) {
          // 单图保持原来的 180；多图缩小到 110 并自动换行，避免气泡被撑出屏
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(msg.imageUris, (uri: string, idx: number) => {
              Image(uri)
                .width(msg.imageUris.length === 1 ? 180 : 110)
                .height(msg.imageUris.length === 1 ? 180 : 110)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)
                .margin({ right: 4, bottom: 4 })
            }, (uri: string, idx: number) => `${idx}_${uri}`)
          }
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
