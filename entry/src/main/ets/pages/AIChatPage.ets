import { photoAccessHelper } from '@kit.MediaLibraryKit';

// 聊天消息：发送方 user/ai，类型 text/image
export interface ChatMessage {
  from: string;      // 'user' | 'ai'
  type: string;      // 'text' | 'image'
  content: string;   // 文本内容
  imageUri: string;  // 图片本地 URI（无图为空串）
}

// AI 模拟回复文案
const AI_REPLY: string = '好的，已收到您的提问，正在结合考纲为您拆解...';
// 模拟 AI 回复延迟（毫秒）
const AI_REPLY_DELAY_MS: number = 1000;

@ComponentV2
export struct AIView {
  @Local selectedMode: number = 0;
  @Local inputText: string = '';
  @Local chatList: ChatMessage[] = [];   // 聊天记录
  @Local pendingImage: string = '';      // 已选未发送的图片 URI

  // 聊天记录非空时隐藏上部引导区，让位给聊天流
  private get hasChat(): boolean {
    return this.chatList.length > 0;
  }

  // 加号：调起系统相册选一张图片，获取本地 URI
  private async pickImage(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      };
      const result = await picker.select(options);
      if (result.photoUris.length > 0) {
        this.pendingImage = result.photoUris[0];
      }
    } catch (e) {
      // 用户取消或选择失败：保持原状态
    }
  }

  // 移除已选待发图片
  private removePendingImage(): void {
    this.pendingImage = '';
  }

  // 发送：打包文字+图片追加到列表，清空输入与图片，1 秒后追加 AI 回复
  private send(): void {
    const text: string = this.inputText.trim();
    if (text === '' && this.pendingImage === '') {
      return;
    }
    const msg: ChatMessage = {
      from: 'user',
      type: this.pendingImage !== '' ? 'image' : 'text',
      content: text,
      imageUri: this.pendingImage
    };
    this.chatList.push(msg);
    this.inputText = '';
    this.pendingImage = '';

    setTimeout((): void => {
      const reply: ChatMessage = {
        from: 'ai',
        type: 'text',
        content: AI_REPLY,
        imageUri: ''
      };
      this.chatList.push(reply);
    }, AI_REPLY_DELAY_MS);
  }

  build() {
    Column() {
      // ============ 上部：居中引导区（有聊天记录后隐藏） ============
      if (!this.hasChat) {
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
      if (this.hasChat) {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.chatList, (msg: ChatMessage, idx: number) => {
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
        if (this.pendingImage !== '') {
          Row({ space: 10 }) {
            Image(this.pendingImage)
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
                this.removePendingImage();
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
            this.pickImage();
          })

          // 文本输入框
          TextInput({ text: this.inputText, placeholder: '输入题目或粘贴题干…' })
            .placeholderColor('#9AA0AC')
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .fontSize(16.0)
            .margin({ left: 8, right: 8 })
            .onChange((value: string) => {
              this.inputText = value;
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
          Text(msg.content)
            .fontSize(16.0)
            .lineHeight(21)
            .fontColor(msg.from === 'user' ? Color.White : '#1A202C')
            .width('100%')
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
        .fontWeight(this.selectedMode === modeIndex ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selectedMode === modeIndex ? '#3B6BF6' : '#6B7280')
    }
    .layoutWeight(1)
    .height(42)
    .borderRadius(22)
    .backgroundColor(this.selectedMode === modeIndex ? '#E8F0FF' : Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.selectedMode = modeIndex;
    })
  }
}
