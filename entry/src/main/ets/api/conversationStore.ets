
import { ChatRequest, SSECallbacks, ChatMessage } from './apiTypes';
import { startChatStream } from './apiService';
import { ApiService } from './apiService'

export class ConversationStore {
  conversationId: string = '';
  public inputText: string = '';       // 绑定输入框的值


  messages: ChatMessage[] = [];

  // 是否正在加载中（防止重复发送）
  isLoading: boolean = false;

  init(): void {
    // 在 ArkTS 中，必须显式声明数组的类型
    const welcomeMsg: ChatMessage = {
      id: Date.now(),
      role: 'assistant',
      content: '你好，我是你的AI助手，有什么可以帮你的吗？',
      timestamp: Date.now()
    };

    this.messages = [welcomeMsg];
    this.isLoading = false;
    this.conversationId = '';
  }

  // 发送消息
  sendMessage(input: string): void {
    if (!input.trim() || this.isLoading) return;

    const trimmedInput = input.trim();

    // 1. 构建并添加用户消息
    const userMsg: ChatMessage = {
      id: Date.now(),
      role: 'user',
      content: trimmedInput,
      timestamp: Date.now()
    };
    this.messages.push(userMsg);

    // 2. 先添加一个空的 AI 消息占位，准备接收流式数据
    const emptyAiMsg: ChatMessage = {
      id: Date.now() + 1,
      role: 'assistant',
      content: '',
      timestamp: Date.now()
    };
    this.messages.push(emptyAiMsg);

    // 清空输入框，并显示加载中状态
    this.inputText = '';
    this.isLoading = true;

    // 3. 调用顶层函数 startChatStream (需要先拿到 token)

    const token: string = ''; // TODO: 在这里填入获取 token 的逻辑，例如 await TokenManager.getToken()

    // 组装请求参数
    const chatParams: ChatRequest = {
      message: trimmedInput,
      conversationId: this.conversationId
    };

    const callbacks: SSECallbacks = {
      onMessage: (content: string) => {
        // 收到片段，拼接到最后一条 AI 消息
        const lastMsg = this.messages[this.messages.length - 1];
        if (lastMsg.role === 'assistant') {
          lastMsg.content += content;
        }
      },
      onEnd: (conversationId: string) => {
        this.conversationId = conversationId;
        this.isLoading = false;
      },
      onError: (error: string) => {
        console.error('SSE Error:', error);
        this.isLoading = false;
      },
      onArtifact: (artifact: string) => {
        console.info('收到 artifact:', artifact);
      }
    };

    // 发起流式请求
    startChatStream(chatParams, token, callbacks);
  }

  clear(): void {
    this.init();
  }
}