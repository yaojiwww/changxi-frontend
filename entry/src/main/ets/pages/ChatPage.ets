import { startChatStream } from '../api/apiService';
import { ChatRequest, SSECallbacks } from '../api/apiTypes';
import { TokenManager } from '../api/tokenManager';

interface UIMessage {
  content: string;
  isUser: boolean;
}

@Component
struct UserBubble {
  @Prop content: string;

  build() {
    Row() {
      Blank()
      Text(this.content)
        .padding(12)
        .backgroundColor('#007AFF')
        .fontColor(Color.White)
        .borderRadius(12)
        .width('70%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }
}

@Component
struct AiBubble {
  @Prop content: string;

  build() {
    Row() {
      Text(this.content || '正在思考...')
        .padding(12)
        .backgroundColor('#F2F2F7')
        .fontColor(Color.Black)
        .borderRadius(12)
        .width('70%')
      Blank()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }
}

@Entry
@Component
struct ChatPage {
  @State messages: UIMessage[] = [];
  @State inputMessage: string = '';
  @State isSending: boolean = false;
  @State currentConversationId: string = '';

  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.messages = [{ content: '你好，我是你的AI助手，有什么可以帮你的吗？', isUser: false }];
  }

  async sendMessage() {
    const userMsg = this.inputMessage.trim();
    if (userMsg === '' || this.isSending) {
      return;
    }

    this.isSending = true;
    this.messages = [...this.messages, { content: userMsg, isUser: true }];
    this.inputMessage = '';
    this.messages = [...this.messages, { content: '', isUser: false }];

    try {
      const token = await TokenManager.getToken();
      if (!token) {
        console.error('Token 获取失败');
        this.isSending = false;
        return;
      }

      const req: ChatRequest = {
        message: userMsg,
        conversationId: this.currentConversationId
      };

      const callbacks: SSECallbacks = {
        onMessage: (content) => {
          let lastMsg = this.messages[this.messages.length - 1];
          lastMsg.content += content;
          this.messages = [...this.messages.slice(0, this.messages.length - 1), lastMsg];
          this.scrollToBottom();
        },
        onEnd: (convId) => {
          if (convId) this.currentConversationId = convId;
          this.isSending = false;
        },
        onError: (error) => {
          console.error('Chat error:', error);
          this.isSending = false;
        },
        onArtifact: (artifactCode) => {
          console.log('Artifact:', artifactCode);
        }
      };

      startChatStream(req, token, callbacks);

    } catch (e) {
      console.error('发送消息异常:', e);
      this.isSending = false;
    }
  }

  private scrollToBottom() {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 50);
  }

  build() {
    Column() {
      // ✅ 关键修复：scroller 写在 List() 的构造参数里
      List({ space: 4, scroller: this.scroller }) {
        ForEach(this.messages, (msg: UIMessage) => {
          ListItem() {
            if (msg.isUser) {
              UserBubble({ content: msg.content })
            } else {
              AiBubble({ content: msg.content })
            }
          }
        })
      }
      .width('100%')
      .layoutWeight(1)

      Row() {
        TextInput({ placeholder: '请输入消息...', text: this.inputMessage })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.inputMessage = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          })

        Button('发送')
          .height(40)
          .margin({ left: 8 })
          .enabled(!this.isSending)
          .onClick(() => {
            this.sendMessage();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 12 })
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
  }
}