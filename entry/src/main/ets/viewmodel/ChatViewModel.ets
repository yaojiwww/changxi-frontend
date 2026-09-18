import { ChatMessage, ChatRole } from '../model/ChatMessage';
import { ChatRepository } from '../repository/ChatRepository';
import { SSECallbacks } from '../network/ApiTypes';

/**
 * 聊天业务状态。
 *
 * 合并了原来的两份实现：保留 ConversationStore 的"类"形态，
 * 换上 ChatPage 里能跑通的 Token 逻辑，并修掉 push() 不触发刷新的问题。
 */
@Observed
export class ChatViewModel {
  messages: ChatMessage[] = [];
  inputText: string = '';
  isSending: boolean = false;
  conversationId: string = '';
  errorMessage: string = '';

  /** 当前这轮流式请求的取消函数 */
  private cancelStream: (() => void) | null = null;

  init(): void {
    const welcome: ChatMessage = {
      id: Date.now(),
      role: ChatRole.ASSISTANT,
      content: '你好，我是你的AI助手，有什么可以帮你的吗？',
      timestamp: Date.now()
    };
    this.messages = [welcome];
    this.isSending = false;
    this.conversationId = '';
    this.errorMessage = '';
  }

  updateInput(text: string): void {
    this.inputText = text;
  }

  async send(): Promise<void> {
    const text = this.inputText.trim();
    if (text.length === 0 || this.isSending) {
      return;
    }

    const userMsg: ChatMessage = {
      id: Date.now(),
      role: ChatRole.USER,
      content: text,
      timestamp: Date.now()
    };
    const placeholder: ChatMessage = {
      id: Date.now() + 1,
      role: ChatRole.ASSISTANT,
      content: '',
      timestamp: Date.now()
    };

    // 关键：必须整体重新赋值数组。
    // 原来写的是 this.messages.push(...)，@Observed 观察不到数组内部变动，UI 不会刷新。
    this.messages = [...this.messages, userMsg, placeholder];
    this.inputText = '';
    this.isSending = true;
    this.errorMessage = '';

    const callbacks: SSECallbacks = {
      onMessage: (content: string) => {
        this.appendToLast(content);
      },
      onEnd: (conversationId: string) => {
        if (conversationId.length > 0) {
          this.conversationId = conversationId;
        }
        this.isSending = false;
        this.cancelStream = null;
      },
      onError: (error: string) => {
        this.errorMessage = error;
        this.isSending = false;
        this.cancelStream = null;
      }
    };

    this.cancelStream = await ChatRepository.send(text, this.conversationId, callbacks);
  }

  /** 把流式片段追加到最后一条助手消息 */
  private appendToLast(chunk: string): void {
    if (this.messages.length === 0) {
      return;
    }
    const last = this.messages[this.messages.length - 1];
    const updated: ChatMessage = {
      id: last.id,
      role: last.role,
      content: last.content + chunk,
      timestamp: last.timestamp
    };
    this.messages = [...this.messages.slice(0, this.messages.length - 1), updated];
  }

  /** 页面销毁时必须调用，否则 SSE 连接会一直挂着 */
  dispose(): void {
    if (this.cancelStream) {
      this.cancelStream();
      this.cancelStream = null;
    }
    this.isSending = false;
  }
}
