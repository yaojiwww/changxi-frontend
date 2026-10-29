// 题库知识点目录（逻辑层）。
// kpId 是前端与后端共用的稳定标识，后端 knowledge_point 表用同一批值；
// 首页知识列表点进练习页时只传了章节名，这里按「章节名 + 当前报考级别」反查 kpId。
// 首页专业知识列表本身就随报考级别变化，所以点进来的级别必然与章节匹配；
// 反查不到时练习页显示空态，不报错（当前所有叶子节点都已覆盖）。
import { LEVEL_BEGINNER, LEVEL_INTERMEDIATE, LEVEL_ADVANCED } from './GoalModel';

// 基础知识页签的条目不分级别
export const LEVEL_ANY: number = -1;

// 一个知识点（= 首页列表里的一个可点击章节）
export interface KpEntry {
  kpId: string;
  name: string;       // 首页列表里显示的章节名，用于反查
  label: string;      // 答题页标签 / 错题本分类名，带级别前缀避免同名混淆
  levelIndex: number; // 所属报考级别；LEVEL_ANY 表示不分级别
  total: number;      // 该章节题库总题量，与首页列表显示的数量一致
}

// 已录入题库的章节：覆盖首页「基础知识」全部条目与初中高三个级别的全部专业知识叶子节点。
// 前四节来自题库文档《知识点练习题》，其余为前端补充题（每题均不少于 5 题）。
export const KP_ENTRIES: KpEntry[] = [
  {
    kpId: 'kp-basic-law',
    name: '相关法律法规及其它试题',
    label: '相关法律法规及其它试题',
    levelIndex: LEVEL_ANY,
    total: 358
  },
  {
    kpId: 'kp-beginner-water',
    name: '组织饮水',
    label: '初级 · 组织饮水',
    levelIndex: LEVEL_BEGINNER,
    total: 67
  },
  {
    kpId: 'kp-intermediate-meal',
    name: '组织进餐',
    label: '中级 · 组织进餐',
    levelIndex: LEVEL_INTERMEDIATE,
    total: 45
  },
  {
    kpId: 'kp-advanced-sleep',
    name: '组织睡眠',
    label: '高级 · 组织睡眠',
    levelIndex: LEVEL_ADVANCED,
    total: 36
  },
  // ===== 基础知识其余章节（题目见 QuestionBankBasicExtra） =====
  {
    kpId: 'kp-basic-environment',
    name: '相关环境知识',
    label: '相关环境知识',
    levelIndex: LEVEL_ANY,
    total: 106
  },
  {
    kpId: 'kp-basic-safety',
    name: '婴幼儿安全知识',
    label: '婴幼儿安全知识',
    levelIndex: LEVEL_ANY,
    total: 186
  },
  {
    kpId: 'kp-basic-disease',
    name: '婴幼儿常见病及常见传染病防治基础知识',
    label: '常见病及传染病防治',
    levelIndex: LEVEL_ANY,
    total: 306
  },
  {
    kpId: 'kp-basic-pedagogy',
    name: '婴幼儿教育学知识',
    label: '婴幼儿教育学知识',
    levelIndex: LEVEL_ANY,
    total: 125
  },
  {
    kpId: 'kp-basic-physiology',
    name: '婴幼儿生理学知识',
    label: '婴幼儿生理学知识',
    levelIndex: LEVEL_ANY,
    total: 293
  },
  {
    kpId: 'kp-basic-hygiene',
    name: '婴幼儿卫生保健知识',
    label: '婴幼儿卫生保健知识',
    levelIndex: LEVEL_ANY,
    total: 237
  },
  {
    kpId: 'kp-basic-psychology',
    name: '婴幼儿心理学知识',
    label: '婴幼儿心理学知识',
    levelIndex: LEVEL_ANY,
    total: 231
  },
  {
    kpId: 'kp-basic-nutrition',
    name: '婴幼儿营养常识',
    label: '婴幼儿营养常识',
    levelIndex: LEVEL_ANY,
    total: 168
  },
  {
    kpId: 'kp-basic-ethics',
    name: '保育员职业道德与职业守则',
    label: '保育员职业道德与职业守则',
    levelIndex: LEVEL_ANY,
    total: 173
  },
  // ===== 初级 · 生活管理 / 卫生管理 / 配合教育活动 =====
  {
    kpId: 'kp-beginner-storage',
    name: '保管和使用物品',
    label: '初级 · 保管和使用物品',
    levelIndex: LEVEL_BEGINNER,
    total: 102
  },
  {
    kpId: 'kp-beginner-health',
    name: '健康观察',
    label: '初级 · 健康观察',
    levelIndex: LEVEL_BEGINNER,
    total: 255
  },
  {
    kpId: 'kp-beginner-toilet',
    name: '组织盥洗如厕',
    label: '初级 · 组织盥洗如厕',
    levelIndex: LEVEL_BEGINNER,
    total: 127
  },
  {
    kpId: 'kp-beginner-meal',
    name: '组织进餐',
    label: '初级 · 组织进餐',
    levelIndex: LEVEL_BEGINNER,
    total: 134
  },
  {
    kpId: 'kp-beginner-sleep',
    name: '组织睡眠',
    label: '初级 · 组织睡眠',
    levelIndex: LEVEL_BEGINNER,
    total: 102
  },
  {
    kpId: 'kp-beginner-clean',
    name: '清洁',
    label: '初级 · 清洁',
    levelIndex: LEVEL_BEGINNER,
    total: 92
  },
  {
    kpId: 'kp-beginner-disinfect',
    name: '消毒',
    label: '初级 · 消毒',
    levelIndex: LEVEL_BEGINNER,
    total: 232
  },
  {
    kpId: 'kp-beginner-activity',
    name: '配合教育活动',
    label: '初级 · 配合教育活动',
    levelIndex: LEVEL_BEGINNER,
    total: 390
  },
  // ===== 中级 =====
  {
    kpId: 'kp-intermediate-health',
    name: '健康观察',
    label: '中级 · 健康观察',
    levelIndex: LEVEL_INTERMEDIATE,
    total: 60
  },
  {
    kpId: 'kp-intermediate-toilet',
    name: '组织盥洗如厕',
    label: '中级 · 组织盥洗如厕',
    levelIndex: LEVEL_INTERMEDIATE,
    total: 91
  },
  {
    kpId: 'kp-intermediate-sleep',
    name: '组织睡眠',
    label: '中级 · 组织睡眠',
    levelIndex: LEVEL_INTERMEDIATE,
    total: 92
  },
  {
    kpId: 'kp-intermediate-clean',
    name: '清洁',
    label: '中级 · 清洁',
    levelIndex: LEVEL_INTERMEDIATE,
    total: 75
  },
  {
    kpId: 'kp-intermediate-disinfect',
    name: '消毒',
    label: '中级 · 消毒',
    levelIndex: LEVEL_INTERMEDIATE,
    total: 97
  },
  {
    kpId: 'kp-intermediate-activity',
    name: '配合教育活动',
    label: '中级 · 配合教育活动',
    levelIndex: LEVEL_INTERMEDIATE,
    total: 359
  },
  // ===== 高级 =====
  {
    kpId: 'kp-advanced-injury',
    name: '防范意外伤害',
    label: '高级 · 防范意外伤害',
    levelIndex: LEVEL_ADVANCED,
    total: 204
  },
  {
    kpId: 'kp-advanced-toilet',
    name: '组织盥洗如厕',
    label: '高级 · 组织盥洗如厕',
    levelIndex: LEVEL_ADVANCED,
    total: 33
  },
  {
    kpId: 'kp-advanced-meal',
    name: '组织进餐',
    label: '高级 · 组织进餐',
    levelIndex: LEVEL_ADVANCED,
    total: 46
  },
  {
    kpId: 'kp-advanced-clean',
    name: '清洁',
    label: '高级 · 清洁',
    levelIndex: LEVEL_ADVANCED,
    total: 34
  },
  {
    kpId: 'kp-advanced-disinfect',
    name: '消毒',
    label: '高级 · 消毒',
    levelIndex: LEVEL_ADVANCED,
    total: 40
  },
  {
    kpId: 'kp-advanced-training',
    name: '培训与指导',
    label: '高级 · 培训与指导',
    levelIndex: LEVEL_ADVANCED,
    total: 24
  },
  {
    kpId: 'kp-advanced-activity',
    name: '配合教育活动',
    label: '高级 · 配合教育活动',
    levelIndex: LEVEL_ADVANCED,
    total: 81
  },
];

// 按章节名反查知识点。同名章节（组织进餐 / 组织睡眠）用报考级别消歧；找不到返回 undefined
export function resolveKp(name: string, levelIndex: number): KpEntry | undefined {
  for (let i = 0; i < KP_ENTRIES.length; i++) {
    const entry: KpEntry = KP_ENTRIES[i];
    if (entry.name !== name) {
      continue;
    }
    if (entry.levelIndex === LEVEL_ANY || entry.levelIndex === levelIndex) {
      return entry;
    }
  }
  return undefined;
}

// 按 kpId 取知识点
export function kpOf(kpId: string): KpEntry | undefined {
  for (let i = 0; i < KP_ENTRIES.length; i++) {
    if (KP_ENTRIES[i].kpId === kpId) {
      return KP_ENTRIES[i];
    }
  }
  return undefined;
}
