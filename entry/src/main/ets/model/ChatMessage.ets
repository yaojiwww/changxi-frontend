/** 聊天消息（UI 侧使用） */

export enum ChatRole {
  USER = 'user',
  ASSISTANT = 'assistant'
}

export interface ChatMessage {
  id: number;
  role: ChatRole;
  content: string;
  timestamp: number;
}
