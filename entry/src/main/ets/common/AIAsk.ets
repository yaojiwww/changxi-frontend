// 题目 → AI 伴学的提问拼装（逻辑层）。
// 练习页、报告页只负责点按，这里统一生成提问文本；导航由页面自己 back 到首页。
// 不自动发送：AI 伴学页只把文本填进输入框，用户确认后再发。
import { signalPendingQuestion } from './NavSignal';

// 一道待提问的题目。选项与答案都可缺省，缺省时不拼对应段落
export interface AskQuestion {
  questionId?: string;   // 与报告答题卡的 questionId 对应，用于找回原题
  stem: string;
  options?: string[];
  userAnswer?: string;
  correctAnswer?: string;
  knowledgePoint?: string;
}

const OPTION_LETTERS: string[] = ['A', 'B', 'C', 'D', 'E', 'F'];

// 拼成一段可直接发问的文本：题干 + 选项 + 我的答案 + 正确答案 + 知识点
export function buildAskPrompt(q: AskQuestion): string {
  const lines: string[] = ['这道题我不太理解，请帮我讲清考点、解题思路和易错点：', q.stem];

  if (q.options !== undefined && q.options.length > 0) {
    for (let i = 0; i < q.options.length && i < OPTION_LETTERS.length; i++) {
      lines.push(OPTION_LETTERS[i] + '. ' + q.options[i]);
    }
  }

  if (q.userAnswer !== undefined && q.userAnswer !== '') {
    lines.push('我的答案：' + q.userAnswer);
  }
  if (q.correctAnswer !== undefined && q.correctAnswer !== '') {
    lines.push('正确答案：' + q.correctAnswer);
  }
  if (q.knowledgePoint !== undefined && q.knowledgePoint !== '') {
    lines.push('所属知识点：' + q.knowledgePoint);
  }
  return lines.join('\n');
}

// 记录待填提问。页面随后切到 AI 页签并返回首页
export function signalAskQuestion(q: AskQuestion): void {
  signalPendingQuestion(buildAskPrompt(q));
}
