import { Http, ApiResponse, CODE_OK } from '../common/Http';

// 首页看板数据，字段与 docs/api_spec.md 对齐（当前文档尚未收录此接口，联调前需与后端确认路径与字段名）
export interface DashboardData {
  total_progress: number;   // 总进度百分比 0-100，驱动首页进度环
  exam_countdown: number;   // 距考试天数（后端口径，首页当前仍走本地考试日期）
  study_days: number;       // 连续学习天数
  total_answers: number;    // 累计答题数
}

// 接口未就绪 / 网络异常时的兜底数据：进度一律 0，真实进度等后端 total_progress 下发
const MOCK_DASHBOARD: DashboardData = {
  total_progress: 0,
  exam_countdown: 0,
  study_days: 0,
  total_answers: 0
};

// 首页看板接口。注意：docs/api_spec.md 目前未定义该接口，
// 后端就绪后请先把路径与字段补进文档，再同步修改这里
export class DashboardApi {
  // 拉首页看板数据。内部降级：任何异常都返回 Mock，调用方无需再兜底
  static async getDashboardData(token: string): Promise<ApiResponse<DashboardData>> {
    try {
      const res = await Http.get<DashboardData>('/home/dashboard', token);
      if (res.code === CODE_OK && res.data !== null) {
        return res;
      }
      return { code: CODE_OK, message: 'mock', data: MOCK_DASHBOARD };
    } catch (err) {
      return { code: CODE_OK, message: 'mock', data: MOCK_DASHBOARD };
    }
  }
}
