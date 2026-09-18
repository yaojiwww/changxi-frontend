/**
 * 网络层的数据契约。只保留真正在用的类型。
 *
 * 已删除：SendCodeResponse / RegisterResponse / LoginResponse / LogoutResponse
 *        （它们只是给 data 套了一层，ApiResponse<T> 已经做了这件事，0 处引用）
 *        UserData（只被上面那几个引用，连带死掉）
 *        HttpResponseCode（import 了但从没使用）
 *        ChatSSEMessage（和 BackendMessage 字段完全相同，二选一保留 SseEvent）
 */

/** 后端统一响应信封：{ code, message, data } */
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export interface HttpRequestHeader {
  'Content-Type': string;
  Authorization?: string;
}

// ==================== 认证 ====================

/** 验证码用途，取值来自接口文档 */
export enum CodePurpose {
  REGISTER = 'register',
  RESET_PASSWORD = 'reset_password'
}

export interface SendCodeRequest {
  number: string;
  purpose: string;
}

export interface RegisterRequest {
  number: string;
  code: string;
  password: string;
}

export interface LoginRequest {
  number: string;
  password: string;
}

export interface LogoutRequest {
  number: string;
}

// ==================== 聊天 ====================

/**
 * 聊天请求。四个字段后端都要，不是可选的。
 * conversationId 首轮传 ""，续聊传上一轮返回的值。
 */
export interface ChatRequest {
  message: string;
  conversationId: string;
  stream: boolean;
  mode: string;
}

/**
 * SSE 单条事件（后端 → 前端）。
 * type 取值：message（中间内容）| end（结束，带 conversationId）| error（出错）
 * 接口文档里没有 artifact 字段，artifact 相关处理已移除。
 */
export interface SseEvent {
  type: string;
  content?: string;
  conversationId?: string;
}

/** SSE 回调集合 */
export interface SSECallbacks {
  onMessage: (content: string) => void;
  onEnd: (conversationId: string) => void;
  onError: (error: string) => void;
}
