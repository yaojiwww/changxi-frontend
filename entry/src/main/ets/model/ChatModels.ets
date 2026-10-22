// AI 伴学的数据模型。
// ChatMessage 原先定义在 pages/AIChatPage.ets 里，但页面要用、ViewModel 也要用，
// 留在 pages/ 下会让 viewmodel 反向依赖页面，所以按分层挪到 model/。
// 字段名与页面既有的渲染逻辑（msg.from / msg.type / msg.content / msg.imageUris）保持一致。

// 聊天消息：发送方 user/ai，类型 text/image
export interface ChatMessage {
  from: string;        // 'user' | 'ai'
  type: string;        // 'text' | 'image'
  content: string;     // 文本内容
  imageUris: string[]; // 随消息发送的图片本地 URI（无图为空数组）
}

// 一条消息最多带几张图，与后端限制一致
export const MAX_CHAT_IMAGES: number = 4;

// 已选、待发送的图片。选完就开始上传，拿到 fileId 后才允许发送
export interface PendingImage {
  id: string;        // 页面内唯一标识，用来更新/删除单张
  uri: string;       // 相册本地 URI，用于显示缩略图
  fileId: string;    // 上传成功后的文件 ID；空串表示还没拿到
  uploading: boolean;
}

// 提问模式（对应页面上的「题目解答 / 专属规划」胶囊）。
// 作为 Dify 应用的 inputs.mode 传下去，由智能体决定用哪套提示词；
// Dify 侧没定义 mode 变量时会被忽略，不影响提问本身。
export const AI_MODE_SOLVE: string = 'solve';   // 题目解答
export const AI_MODE_PLAN: string = 'plan';     // 专属规划

// 从「AI 知识库」带进「AI 伴学」的提问上下文。
// 知识点不是一次跳转的目标，而是这一轮提问的背景：页面先把它显示成胶囊，
// 发送时再拼进 query，用户能看到、能修改、也能随时关掉。
export class AIAskContext {
  source: string = 'knowledge';
  levelName: string = '';   // 通用 / 初级 / 中级 / 高级
  docId: string = '';
  docName: string = '';     // 职业功能分类，如「婴幼儿饮食照料」
  sectionNo: string = '';   // 小节编号，如 2.1；整份分类提问时为空
  sectionTitle: string = '';// 小节标题；整份分类提问时为空
  skill: string[] = [];     // 该小节的技能要求
  theory: string[] = [];    // 该小节的知识要求
}

// 用户只选了知识点、没写具体问题时，输入框里预填的默认问题
export const DEFAULT_KNOWLEDGE_QUESTION: string =
  '请讲解这个知识点的核心概念、常考形式和易错点，并给我一个记忆框架。';

// 拼 prompt 时每类考点最多带几条，避免整份分类的所有小节把 query 撑爆
const MAX_CONTEXT_POINTS: number = 8;

function pointLines(items: string[]): string {
  const count: number = items.length < MAX_CONTEXT_POINTS ? items.length : MAX_CONTEXT_POINTS;
  const lines: string[] = [];
  for (let i = 0; i < count; i++) {
    lines.push(`${i + 1}. ${items[i]}`);
  }
  return lines.join('\n');
}

// 知识点在输入框上方的显示文案：中级 · 婴幼儿饮食照料 · 2.1 饮食照料
export function askContextTitle(ctx: AIAskContext): string {
  let title: string = ctx.docName;
  if (ctx.sectionNo !== '' || ctx.sectionTitle !== '') {
    title += ' · ' + (ctx.sectionNo !== '' ? `${ctx.sectionNo} ` : '') + ctx.sectionTitle;
  }
  if (ctx.levelName !== '') {
    title = `${ctx.levelName} · ` + title;
  }
  return title;
}

// 把知识点上下文和用户问题拼成后端认识的 query。
// 第一版不动后端契约：/ai/chat 只收 query，上下文放 query 里即可。
export function buildKnowledgePrompt(ctx: AIAskContext, question: string): string {
  let head: string = `我在备考保育师（${ctx.levelName}），当前知识点：${ctx.docName}`;
  if (ctx.sectionNo !== '' || ctx.sectionTitle !== '') {
    head += ' / ' + (ctx.sectionNo !== '' ? `${ctx.sectionNo} ` : '') + ctx.sectionTitle;
  }
  head += '。';

  const parts: string[] = [head];
  if (ctx.skill.length > 0) {
    parts.push('技能要求：\n' + pointLines(ctx.skill));
  }
  if (ctx.theory.length > 0) {
    parts.push('知识要求：\n' + pointLines(ctx.theory));
  }
  if (question === DEFAULT_KNOWLEDGE_QUESTION) {
    // 用户没改默认问题：直接给一条完整的讲解指令，避免和「我的问题」重复
    parts.push('请结合考纲讲解这个知识点的核心概念、常考形式和易错点，并给我一个记忆框架。');
  } else {
    parts.push('请结合考纲讲解这个知识点。我的问题：' + question);
  }
  return parts.join('\n\n');
}
