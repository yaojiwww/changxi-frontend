// mock/testData.ets

import { TestQuestion } from './types';

// 1. 模拟的题库数据 (这里放几道示例，你可以继续往里加)
const MOCK_DATABASE: Record<string, TestQuestion[]> = {
  'drowning': [
    { id: 'd1', scenario: 'drowning', content: '发现有人溺水，救上岸后第一步做什么？', options: ['A. 立即控水', 'B. 判断意识和呼吸', 'C. 胸外按压', 'D. 大声呼救'], answer: 1 },
    { id: 'd2', scenario: 'drowning', content: '溺水者无呼吸心跳时，应先人工呼吸还是胸外按压？', options: ['A. 人工呼吸', 'B. 先胸外按压', 'C. 两者交替', 'D. 先拨打120'], answer: 1 },
    { id: 'd3', scenario: 'drowning', content: '如果溺水者还有呼吸，应该让他保持什么姿势？', options: ['A. 平躺', 'B. 俯卧', 'C. 侧卧', 'D. 坐姿'], answer: 2 },
    { id: 'd4', scenario: 'drowning', content: '在施救过程中，如果溺水者发生呕吐，应该怎么做？', options: ['A. 继续按压', 'B. 把头偏向一侧清理口腔', 'C. 立即停止一切操作', 'D. 喂水稀释'], answer: 1 },
    { id: 'd5', scenario: 'drowning', content: '以下哪种情况绝对不应该尝试下水救人？', options: ['A. 会游泳', 'B. 有救生设备', 'C. 水流湍急且自己水性不好', 'D. 有人陪同'], answer: 2 },
    { id: 'd6', scenario: 'drowning', content: '如果现场没有AED，应该持续做心肺复苏直到？', options: ['A. 5分钟', 'B. 救护车到达', 'C. 10分钟', 'D. 自己累了'], answer: 1 },
  ],
  'choking': [
    { id: 'c1', scenario: 'choking', content: '成年人发生气道异物梗阻，应使用哪种方法急救？', options: ['A. 海姆立克急救法', 'B. 人工呼吸', 'C. 喝水', 'D. 拍背'], answer: 0 },
    { id: 'c2', scenario: 'choking', content: '1岁以下婴儿发生气道异物梗阻，正确的做法是？', options: ['A. 海姆立克法', 'B. 拍背法', 'C. 抠喉咙', 'D. 让他自己咳'], answer: 1 },
    // ... 可以继续补充题目
  ],
  // 其他场景的题目...
  'default': []
};

/**
 * Fisher-Yates 洗牌算法：彻底打乱数组顺序，不使用嵌套函数
 */
function shuffleArray(array: TestQuestion[]): void {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    // 使用传统变量赋值交换，不使用解构赋值
    const temp = array[i];
    array[i] = array[j];
    array[j] = temp;
  }
}

/**
 * 2. 核心函数：根据场景名，获取5道随机题目
 */
export function fetchRandomQuestions(scenario: string): TestQuestion[] {
  // 获取对应场景的题目，如果没有就使用空数组
  const questions: TestQuestion[] = MOCK_DATABASE[scenario] || [];

  // 如果题目不够5道，就返回所有题目
  if (questions.length <= 5) {
    const copy = [...questions]; // 复制一份，避免修改原数据
    shuffleArray(copy); // 打乱顺序
    return copy;
  }

  // 如果题目大于5道，截取并打乱前5道
  const copy = [...questions];
  shuffleArray(copy);
  return copy.slice(0, 5);
}