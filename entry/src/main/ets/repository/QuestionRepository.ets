import { HttpClient } from '../network/HttpClient';
import { TestQuestion } from '../model/TestQuestion';
import { ScenarioType } from '../model/Scenario';

/**
 * 题库数据源。
 *
 * ── 后端接口契约 ──────────────────────────────
 * GET {BASE}/api/v1/questions?scenario=cpr&count=5
 *
 * 响应：
 * {
 *   "code": 0,
 *   "message": "ok",
 *   "data": [
 *     { "id": "r1", "scenario": "cpr",
 *       "content": "发现有人倒地，第一步应该做什么？",
 *       "options": ["A. …", "B. …", "C. …", "D. …"],
 *       "answer": 1 }
 *   ]
 * }
 *
 * 要点：
 * 1. 随机抽题由后端做（前端原来用 Fisher-Yates 本地打乱，逻辑还写反了）
 * 2. answer 是正确选项下标，0-based
 * 3. 后端返回几道题，前端就出几道题 —— 不要假设固定 5 道
 *    （原代码把 totalQuestions 写死成 5，题目多了少了都出错）
 * 4. scenario 必须覆盖 ScenarioType 全部 9 个取值，
 *    尤其是 choking_under_1 / choking_over_1 —— 旧本地题库只有笼统的
 *    'choking'，导致选了气道异物梗阻一道题都查不到
 * 旧的本地题库在 ets/mock/testData.ets，已冻结不参与编译，可作设计参考
 * ────────────────────────────────────────────
 */
export class QuestionRepository {

  static async getQuestions(scenario: ScenarioType, count: number): Promise<TestQuestion[]> {
    const params = new Map<string, string>();
    params.set('scenario', scenario);
    params.set('count', count.toString());
    return HttpClient.get<TestQuestion[]>('/questions', params);
  }
}
