// 题库知识点目录（逻辑层）。
// kpId 是前端与后端共用的稳定标识，后端 knowledge_point 表用同一批值；
// 首页知识列表点进练习页时只传了章节名，这里按「章节名 + 当前报考级别」反查 kpId。
// 首页专业知识列表本身就随报考级别变化，所以点进来的级别必然与章节匹配；
// 反查不到（如相关环境知识等尚无题库的章节）→ 练习页显示占位，不报错。
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

// 已录入题库的章节。对应题库文档《知识点练习题》的四节
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
