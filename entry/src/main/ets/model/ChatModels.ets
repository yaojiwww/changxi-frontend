// AI 伴学的数据模型。
// ChatMessage 原先定义在 pages/AIChatPage.ets 里，但页面要用、ViewModel 也要用，
// 留在 pages/ 下会让 viewmodel 反向依赖页面，所以按分层挪到 model/。
// 字段名与页面既有的渲染逻辑（msg.from / msg.type / msg.content / msg.imageUri）保持一致。

// 聊天消息：发送方 user/ai，类型 text/image
export interface ChatMessage {
  from: string;      // 'user' | 'ai'
  type: string;      // 'text' | 'image'
  content: string;   // 文本内容
  imageUri: string;  // 图片本地 URI（无图为空串）
}

// 提问模式（对应页面上的「题目解答 / 专属规划」胶囊）。
// 作为 Dify 应用的 inputs.mode 传下去，由智能体决定用哪套提示词；
// Dify 侧没定义 mode 变量时会被忽略，不影响提问本身。
export const AI_MODE_SOLVE: string = 'solve';   // 题目解答
export const AI_MODE_PLAN: string = 'plan';     // 专属规划
