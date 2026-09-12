// types.docx
export enum ActionType {
  TAP = 'TAP',
  LONG_PRESS = 'LONG_PRESS',
  DRAG = 'DRAG' // 预留拖拽类型
}

export interface FirstAidStep {
  id: string;
  title: string;
  description: string;
  actionType: ActionType;
}

// mock/types.ets

export interface TestQuestion {
  id: string;
  scenario: string; // 新增：题目所属场景
  content: string;
  options: string[];
  answer: number;
}

// 【修改点】补充完整的场景枚举，和你在 FirstAidData.ets 里定义的一致
export enum ScenarioType {
  DROWNING = 'drowning',
  CHOKING_UNDER_1 = 'chokingUnder1',
  CHOKING_OVER_1 = 'chokingOver1',
  CPR = 'cpr',
  BURN = 'burn',
  FALL = 'fall',
  INGESTION = 'ingestion',
  FEVER_UNDER_3 = 'feverUnder3',
  FEVER_OVER_3 = 'feverOver3'
}

// 【修改点】补充完整的题库结构，和枚举一一对应
export interface QuestionBank {
  drowning: TestQuestion[];
  chokingUnder1: TestQuestion[];
  chokingOver1: TestQuestion[];
  cpr: TestQuestion[];
  burn: TestQuestion[];
  fall: TestQuestion[];
  ingestion: TestQuestion[];
  feverUnder3: TestQuestion[];
  feverOver3: TestQuestion[];
}