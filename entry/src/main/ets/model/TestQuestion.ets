/** 测试题目 */

export interface TestQuestion {
  id: string;
  scenario: string;   // 对应 ScenarioType 的值
  content: string;
  options: string[];
  answer: number;     // 正确选项下标，0-based
}
