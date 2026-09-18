/**
 * 急救场景 —— 全项目场景 key 的唯一事实来源。
 *
 * 任何地方需要表示"哪个场景"，都必须用 ScenarioType，禁止再写裸字符串。
 * 后端接口的 scenario 字段取值必须与这里的枚举值逐字一致。
 */

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

/** 需要二级选择（年龄段）时的子选项 */
export interface AgeOptionItem {
  label: string;
  key: ScenarioType;
}

/**
 * 场景列表里的一项。
 * key 有值   = 可直接进入培训
 * key 为 null = 这是个大类，必须再从 ageOptions 里选一个
 * （原来的 needAgeSelect 字段删掉了：它和 ageOptions 表达同一件事，会不同步）
 */
export interface ScenarioItem {
  title: string;
  key: ScenarioType | null;
  ageOptions?: AgeOptionItem[];
}

/**
 * 场景列表属于 App 的导航结构，不是业务数据，所以保留在本地，
 * 这样没有后端也能把首页点开。真正要联网取的是"步骤"和"题目"。
 */
export const SCENARIO_LIST: ScenarioItem[] = [
  {
    title: '气道异物梗阻',
    key: null,
    ageOptions: [
      { label: '未满 1 岁', key: ScenarioType.CHOKING_UNDER_1 } as AgeOptionItem,
      { label: '满 1 岁至 6 岁', key: ScenarioType.CHOKING_OVER_1 } as AgeOptionItem
    ]
  },
  {
    title: '发热伴惊厥抽搐',
    key: null,
    ageOptions: [
      { label: '未满 3 月龄', key: ScenarioType.FEVER_UNDER_3 } as AgeOptionItem,
      { label: '3 月龄及以上', key: ScenarioType.FEVER_OVER_3 } as AgeOptionItem
    ]
  },
  { title: '心肺复苏', key: ScenarioType.CPR },
  { title: '跌倒与头部外伤', key: ScenarioType.FALL },
  { title: '烫伤与烧伤', key: ScenarioType.BURN },
  { title: '误服与异物摄入', key: ScenarioType.INGESTION },
  { title: '溺水', key: ScenarioType.DROWNING }
];
