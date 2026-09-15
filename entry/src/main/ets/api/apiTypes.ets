// apiTypes.ets

// 定义后端返回的 Token 数据结构
export interface UserData {
  token: string;
  userId: string;
}

// 1. 发送验证码
export interface SendCodeRequest {
  number: string;
  purpose: string;
}
export interface SendCodeResponse {
  data: null;
}

// 2. 注册
export interface RegisterRequest {
  number: string;
  code: string;
  password: string;
}
export interface RegisterResponse {
  data: UserData; // 使用上面定义的接口
}

// 3. 登录
export interface LoginRequest {
  number: string;
  password: string;
}
export interface LoginResponse {
  data: UserData; // 使用上面定义的接口
}

// 4. 登出
export interface LogoutRequest {
  number: string;
}
export interface LogoutResponse {
  data: null;
}

// 聊天请求参数
export interface ChatRequest {
  message: string;
  conversationId?: string;
  stream?: boolean;
  mode?: string;

}

// SSE 流式消息（后端→前端）
export interface BackendMessage {
  type: 'message' | 'end' | 'error' | 'artifact';
  content?: string;
  artifact?: string;
  conversationId?: string;
}

// SSE 事件回调接口（用于流式通知UI更新）
export interface SSECallbacks {
  onMessage: (content: string) => void;       // 收到文本片段
  onArtifact: (artifactCode: string) => void;  // 收到效果代码
  onEnd: (conversationId: string) => void;     // 本轮结束
  onError: (error: string) => void;            // 发生错误
}

// 聊天消息（前端UI使用）
export interface ChatMessage {
  id: number;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
  artifactCode?: string;  // 如果有artifact，保存代码供后续渲染
}

// 请求头类型
export interface HttpRequestHeader {
  'Content-Type': string;
  Authorization?: string;
}

// 统一响应格式
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export enum HttpResponseCode {
  OK = 200,
  CREATED = 201,
  NO_CONTENT = 204
}

