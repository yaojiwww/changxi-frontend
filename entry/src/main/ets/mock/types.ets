// ==================== 交互动作类型枚举 ====================
export enum ActionType {
  TAP = 'TAP',
  LONG_PRESS = 'LONG_PRESS',
  DRAG = 'DRAG' // 预留拖拽类型
}

// ==================== 急救步骤接口 ====================
export interface FirstAidStep {
  id: string;
  title: string;
  description: string;
  actionType: ActionType;
}

// ==================== 测试题目接口 ====================
export interface TestQuestion {
  id: string;
  scenario: string;       // 题目所属场景
  content: string;        // 题目内容
  options: string[];      // 选项数组
  answer: number;         // 正确答案索引（0-based）
}

// ==================== 场景类型枚举 ====================
export enum ScenarioType {
  CPR = 'cpr',
  CHOKING_UNDER_1 = 'choking_under_1',
  CHOKING_OVER_1 = 'choking_over_1',
  DROWNING = 'drowning',
  BURN = 'burn',
  FALL = 'fall',
  INGESTION = 'ingestion',
  FEVER_UNDER_3 = 'fever_under_3',
  FEVER_OVER_3 = 'fever_over_3'
}

// ==================== 题库结构接口 ====================

export interface QuestionBank {
  cpr: TestQuestion[];
  choking_under_1: TestQuestion[];
  choking_over_1: TestQuestion[];
  drowning: TestQuestion[];
  burn: TestQuestion[];
  fall: TestQuestion[];
  ingestion: TestQuestion[];
  fever_under_3: TestQuestion[];
  fever_over_3: TestQuestion[];
}