// 模拟试卷 Mock 数据：试卷列表 + 每套试卷的题目与解析
// 后端接入后整体替换本文件数据源，结构保持不变

// 单道题目
export interface ExamQuestion {
  questionId: string;
  stem: string;
  options: string[];
  answer: number;       // 正确选项下标 0-3
  explanation: string;  // 答案解析（成绩页「试卷解析」用）
}

// 试卷
export interface ExamPaper {
  id: string;
  title: string;
  doneCount: number;    // 做过人数（展示用）
  isFree: boolean;
}

// 试卷列表
const papers: ExamPaper[] = [
  { id: 'exam-001', title: '保育师基础知识模拟试题(一)', doneCount: 53896, isFree: true },
  { id: 'exam-002', title: '保育师基础知识模拟试题(二)', doneCount: 23168, isFree: false },
  { id: 'exam-003', title: '保育师基础知识模拟试题(三)', doneCount: 10012, isFree: false },
  { id: 'exam-004', title: '保育师基础知识模拟试题(四)', doneCount: 5973, isFree: false },
  { id: 'exam-005', title: '保育师基础知识模拟试题(五)', doneCount: 4467, isFree: false },
  { id: 'exam-006', title: '保育师基础知识试卷及答案', doneCount: 1584, isFree: false }
];

// 各试卷题目（Mock：每套 6 道完整选择题）
const questionsMap: Map<string, ExamQuestion[]> = new Map<string, ExamQuestion[]>();

// 第一套：生活照料与卫生保健基础
questionsMap.set('exam-001', [
  {
    questionId: 'eq-001-1',
    stem: '保育师给幼儿分发餐具时，相邻餐位间距应不少于？',
    options: ['5cm', '10cm', '15cm', '20cm'],
    answer: 1,
    explanation: '《托儿所、幼儿园卫生保健工作规范》要求进餐时相邻餐位间距不少于 10cm，避免幼儿相互碰撞发生呛噎。'
  },
  {
    questionId: 'eq-001-2',
    stem: '幼儿午睡时，保育师巡视的间隔时间一般不超过？',
    options: ['10 分钟', '20 分钟', '30 分钟', '1 小时'],
    answer: 1,
    explanation: '午睡期间保育师应每 20 分钟巡视一次，观察幼儿睡姿、呼吸与面色，及时发现异常。'
  },
  {
    questionId: 'eq-001-3',
    stem: '配制玩具消毒液时，84 消毒液与水的常用比例约为？',
    options: ['1:50', '1:100', '1:200', '1:500'],
    answer: 1,
    explanation: '一般物体表面消毒按 1:100 配制（约 500mg/L），作用 20 分钟后用清水擦拭干净。'
  },
  {
    questionId: 'eq-001-4',
    stem: '婴幼儿活动室适宜的温度范围是？',
    options: ['16-18℃', '18-22℃', '22-26℃', '26-28℃'],
    answer: 1,
    explanation: '《托儿所、幼儿园卫生保健工作规范》规定活动室温度以 18-22℃ 为宜，相对湿度 50%-60%。'
  },
  {
    questionId: 'eq-001-5',
    stem: '发现幼儿在进餐中发生轻度呛噎，正确的处理是？',
    options: ['立即拍背', '鼓励咳嗽并观察', '立即喂水', '让幼儿平躺'],
    answer: 1,
    explanation: '轻度呛噎应鼓励幼儿自行咳嗽排出异物并密切观察；严重梗阻才采用海姆立克急救法。'
  },
  {
    questionId: 'eq-001-6',
    stem: '幼儿毛巾消毒的正确方法是？',
    options: ['日光暴晒 2 小时', '煮沸消毒 10 分钟', '清水冲洗', '酒精喷洒'],
    answer: 1,
    explanation: '毛巾等织物应煮沸或蒸汽消毒 10 分钟，也可使用含氯消毒液浸泡后清水漂洗晾干。'
  }
]);

// 其余试卷复用同一套 Mock 题目（结构按 paperId 挂载，接真数据后各自独立）
function cloneQuestions(source: ExamQuestion[], paperId: string): ExamQuestion[] {
  const out: ExamQuestion[] = [];
  for (let i = 0; i < source.length; i++) {
    const q: ExamQuestion = source[i];
    out.push({
      questionId: `${paperId}-${i + 1}`,
      stem: q.stem,
      options: q.options,
      answer: q.answer,
      explanation: q.explanation
    });
  }
  return out;
}

const base: ExamQuestion[] = questionsMap.get('exam-001') as ExamQuestion[];
for (let i = 1; i < papers.length; i++) {
  questionsMap.set(papers[i].id, cloneQuestions(base, papers[i].id));
}

// 取全部试卷
export function allPapers(): ExamPaper[] {
  return papers;
}

// 按 ID 取试卷
export function paperOf(paperId: string): ExamPaper | undefined {
  for (let i = 0; i < papers.length; i++) {
    if (papers[i].id === paperId) {
      return papers[i];
    }
  }
  return undefined;
}

// 按试卷 ID 取题目列表
export function questionsOf(paperId: string): ExamQuestion[] {
  const list = questionsMap.get(paperId);
  return list !== undefined ? list : [];
}
