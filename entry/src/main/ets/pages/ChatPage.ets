import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { ChatMessage, ChatRole } from '../model/ChatMessage';

@Component
struct MessageBubble {
  @Prop content: string;
  @Prop isUser: boolean;

  build() {
    Row() {
      if (this.isUser) {
        Blank()
        Text(this.content)
          .padding(12)
          .backgroundColor('#007AFF')
          .fontColor(Color.White)
          .borderRadius(12)
          .constraintSize({ maxWidth: '70%' })
      } else {
        Text(this.content.length > 0 ? this.content : '正在思考...')
          .padding(12)
          .backgroundColor('#F2F2F7')
          .fontColor(Color.Black)
          .borderRadius(12)
          .constraintSize({ maxWidth: '70%' })
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }
}

/**
 * 聊天页。只剩 UI —— 所有业务在 ChatViewModel 里。
 * （原来这里和 api/conversationStore.ets 各有一份聊天逻辑，现已合并。）
 */
@Entry
@Component
struct ChatPage {
  @State vm: ChatViewModel = new ChatViewModel();
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.vm.init();
  }

  aboutToDisappear(): void {
    // 必须断开 SSE，否则离开页面后连接还挂着
    this.vm.dispose();
  }

  build() {
    Column() {
      List({ space: 4, scroller: this.scroller }) {
        ForEach(this.vm.messages, (msg: ChatMessage) => {
          ListItem() {
            MessageBubble({
              content: msg.content,
              isUser: msg.role === ChatRole.USER
            })
          }
        }, (msg: ChatMessage) => msg.id.toString())
      }
      .width('100%')
      .layoutWeight(1)

      if (this.vm.errorMessage.length > 0) {
        Text(this.vm.errorMessage)
          .fontSize(13)
          .fontColor('#D32F2F')
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 4 })
      }

      Row() {
        TextInput({ placeholder: '请输入消息...', text: this.vm.inputText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.vm.updateInput(value);
          })
          .onSubmit(() => {
            this.submit();
          })

        Button('发送')
          .height(40)
          .margin({ left: 8 })
          .enabled(!this.vm.isSending)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 12 })
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
  }

  private submit(): void {
    this.vm.send().then(() => {
      this.scrollToBottom();
    });
    this.scrollToBottom();
  }

  private scrollToBottom(): void {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 50);
  }
}
