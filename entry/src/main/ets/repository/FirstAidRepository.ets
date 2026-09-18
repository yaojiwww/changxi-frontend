import { HttpClient } from '../network/HttpClient';
import { FirstAidStep } from '../model/FirstAidStep';
import { ScenarioType } from '../model/Scenario';

/**
 * 急救步骤数据源。
 *
 * ViewModel 只认这一层，不关心数据来自网络还是本地。
 * 以后要加缓存 / 离线包，改这个文件就够了，ViewModel 和 View 一行都不用动。
 *
 * ── 后端接口契约 ──────────────────────────────
 * GET {BASE}/api/v1/first-aid/steps?scenario=cpr
 *
 * 响应：
 * {
 *   "code": 0,
 *   "message": "ok",
 *   "data": [
 *     { "id": "1", "title": "判断现场安全",
 *       "description": "观察四周…", "actionType": "TAP" }
 *   ]
 * }
 *
 * actionType 取值：TAP | LONG_PRESS | DRAG
 * scenario 取值必须与 ScenarioType 枚举完全一致
 * 旧的本地数据在 ets/mock/FirstAidData.ets，已冻结不参与编译，可作设计参考
 * ────────────────────────────────────────────
 */
export class FirstAidRepository {

  static async getSteps(scenario: ScenarioType): Promise<FirstAidStep[]> {
    const params = new Map<string, string>();
    params.set('scenario', scenario);
    return HttpClient.get<FirstAidStep[]>('/first-aid/steps', params);
  }
}
