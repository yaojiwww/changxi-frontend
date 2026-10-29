// 本地题库的公共结构：题库正文（QuestionBank）与补充题（Extra 系列）共用。
// 单独成文件是为了避免 QuestionBank ↔ 补充题文件互相 import 形成循环依赖。

// 题库里的一道题（含答案）
export interface BankQuestion {
  no: number;          // 章节内序号，从 1 开始，用于拼业务码
  stem: string;
  options: string[];   // 顺序即 A/B/C/D
  answer: string;      // 正确选项字母
  explanation: string; // 解析
}

// 一个章节的题目
export interface BankChapter {
  kpId: string;        // 与 KnowledgeCatalog 的 KP_ENTRIES 对应
  questions: BankQuestion[];
}
