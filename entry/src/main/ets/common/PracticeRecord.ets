// 知识点练习的报告组装与学习数据归档。
// 页面只负责收集作答，报告怎么算、怎么落库都在这里，避免逻辑再写回 pages。
import { PracticeReport, AnswerCardCell, KnowledgeMastery } from '../api/PracticeApi';
import { StudyRecordStore, StudyRecord } from './StudyRecordStore';

// 一道题的最终作答。userAnswer 为选项字母，'' 表示未作答
export interface AnsweredQuestion {
  questionId: string;
  userAnswer: string;
  correctOption: string;
  knowledgePoint: string;
}

// 按交卷时间生成报告：答对数、答题卡、知识点掌握度一次算齐
export function buildPracticeReport(itemId: string, itemName: string, practiceType: string,
  answers: AnsweredQuestion[], durationSec: number): PracticeReport {
  const card: AnswerCardCell[] = [];
  const masteryMap: Map<string, KnowledgeMastery> = new Map<string, KnowledgeMastery>();
  let correctCount = 0;

  for (let i = 0; i < answers.length; i++) {
    const a: AnsweredQuestion = answers[i];
    const correct: boolean = a.userAnswer !== '' && a.userAnswer === a.correctOption;
    if (correct) {
      correctCount++;
    }
    card.push({
      questionId: a.questionId,
      correct: correct,
      userAnswer: a.userAnswer,
      correctOption: a.correctOption
    });

    const kp: string = a.knowledgePoint === '' ? '综合' : a.knowledgePoint;
    let m: KnowledgeMastery | undefined = masteryMap.get(kp);
    if (m === undefined) {
      m = { knowledgePoint: kp, correct: 0, total: 0, accuracy: 0 };
      masteryMap.set(kp, m);
    }
    m.total++;
    if (correct) {
      m.correct++;
    }
  }

  const mastery: KnowledgeMastery[] = [];
  masteryMap.forEach((m: KnowledgeMastery, kp: string): void => {
    mastery.push({
      knowledgePoint: kp,
      correct: m.correct,
      total: m.total,
      accuracy: m.total > 0 ? Math.round(m.correct * 100 / m.total) : 0
    });
  });

  const total: number = answers.length;
  const accuracy: number = total > 0 ? Math.round(correctCount * 100 / total) : 0;
  return {
    itemId: itemId,
    itemName: itemName,
    practiceType: practiceType,
    submitTime: formatNow(),
    correctCount: correctCount,
    total: total,
    accuracy: accuracy,
    duration: durationSec,
    compare: null,
    answerCard: card,
    mastery: mastery
  };
}

// 写入学习数据。归档失败不阻断报告展示，页面自行 catch
export async function archiveKnowledgePractice(report: PracticeReport): Promise<void> {
  const title: string = report.itemName !== '' ? report.itemName : '知识点练习';
  await StudyRecordStore.add({
    id: StudyRecordStore.newId(),
    type: 'knowledge',
    title: title,
    score: report.accuracy !== null ? `${report.accuracy}%` : `${report.correctCount}/${report.total}`,
    date: report.submitTime,
    timestamp: Date.now(),
    detailData: JSON.stringify(report)
  } as StudyRecord);
}

// YYYY-MM-DD HH:mm:ss
function formatNow(): string {
  const d: Date = new Date();
  const p = (n: number): string => (n < 10 ? '0' + n : '' + n);
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ` +
    `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}
