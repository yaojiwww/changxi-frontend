// 题库 / 练习域的数据模型。
// 命名与后端契约、与 WrongItem / FavoriteItem 保持一致：题干 stem、选项 options: string[]、
// 答案统一用选项字母（correctOption / userAnswer），不使用下标。

// 一道练习题。不含答案：答案是判题时由接口下发（见 JudgeResult）
export interface PracticeQuestion {
  questionId: string;      // 题目业务码，如 kp-basic-law-q01
  stem: string;            // 题干
  options: string[];       // 选项，顺序即 A/B/C/D
  knowledgePoint: string;  // 知识点分类名，错题本 / 收藏按它分组
  kpId: string;            // 所属知识点 ID
  type: string;            // 题型，当前只有 single（单选）
}

// 按知识点抽题的结果
export interface PracticeQuestionsData {
  kpId: string;
  kpName: string;          // 知识点完整名
  total: number;           // 该知识点题库总题量，进度条与 x/N 按它算
  questions: PracticeQuestion[];
}

// 判题结果：即选即判，并带解析
export interface JudgeResult {
  questionId: string;
  correct: boolean;        // 本次作答是否正确
  correctOption: string;   // 正确选项字母 A/B/C/D
  explanation: string;     // 解析
}
