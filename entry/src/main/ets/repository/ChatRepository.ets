import { startChatStream } from '../network/SseClient';
import { TokenManager } from '../network/TokenManager';
import { ChatRequest, SSECallbacks } from '../network/ApiTypes';

/**
 * 聊天数据源。
 *
 * ── 后端接口契约 ──────────────────────────────
 * POST /api/v1/chat   { message, conversationId, stream, mode }
 * Header: Authorization: Bearer <token>
 * 响应：text/event-stream，每行形如
 *   data: {"type":"message","content":"急救"}
 *   data: {"type":"message","content":"的第一步是"}
 *   data: {"type":"end","conversationId":"11111","content":""}
 *   data: {"type":"error","content":"出错了"}
 *
 * conversationId 首轮传 ""，续聊传上一轮 end 事件返回的值。
 * ────────────────────────────────────────────
 */
export class ChatRepository {

  /**
   * agent 工作流模式。接口文档没给取值范围，暂时传空串。
   * 后端确认取值后改这里一处即可。
   */
  private static readonly MODE: string = '';

  /**
   * 发起一轮流式对话。
   * 返回取消函数；拿不到 Token 时走 onError 并返回空函数。
   */
  static async send(
    message: string,
    conversationId: string,
    callbacks: SSECallbacks
  ): Promise<() => void> {
    const token = await TokenManager.getToken();
    if (token === null) {
      callbacks.onError('未登录或登录已过期');
      return () => {};
    }

    const req: ChatRequest = {
      message: message,
      conversationId: conversationId,
      stream: true,
      mode: ChatRepository.MODE
    };
    return await startChatStream(req, token, callbacks);
  }
}
