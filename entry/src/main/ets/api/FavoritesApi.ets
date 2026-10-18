import { Http, ApiResponse } from '../common/Http';
import { FavoritesStore, FavoriteListResult, FavoriteItem } from '../common/FavoritesStore';

// 后端未就绪，先走本地 mock。联调时改 false 即可切到真接口
const USE_MOCK: boolean = true;

// 收藏列表查询结果（与 docs/api_spec.md #18 一致）
export type FavoritesListData = FavoriteListResult;

interface CancelBody {
  questionId: string;
}

interface OkData {
}

// 收藏域接口。路径与 docs/api_spec.md 一一对应，改接口先改文档再改这里
export class FavoritesApi {
  // 收藏分类及列表。category 空=全部分类；timeRange: all/today/week
  static async list(category: string, timeRange: string, token: string): Promise<ApiResponse<FavoritesListData>> {
    if (USE_MOCK) {
      return new Promise<ApiResponse<FavoritesListData>>((resolve: (v: ApiResponse<FavoritesListData>) => void): void => {
        resolve({ code: 0, message: 'ok', data: FavoritesStore.query(timeRange, category) });
      });
    }
    const q: string = `category=${encodeURIComponent(category)}&timeRange=${timeRange}`;
    return Http.get<FavoritesListData>(`/favorites/list?${q}`, token);
  }

  // 取消收藏。立即从列表与数据库移除
  static async cancel(questionId: string, token: string): Promise<ApiResponse<OkData>> {
    if (USE_MOCK) {
      return new Promise<ApiResponse<OkData>>((resolve: (v: ApiResponse<OkData>) => void): void => {
        FavoritesStore.remove(questionId).then((): void => {
          resolve({ code: 0, message: 'ok', data: {} });
        });
      });
    }
    const body: CancelBody = { questionId: questionId };
    return Http.post<OkData>('/favorites/cancel', body, token);
  }

  // 取某分类下全部收藏题（重练页用）
  static categoryItems(timeRange: string, category: string): FavoriteItem[] {
    const res: FavoriteListResult = FavoritesStore.query(timeRange, category);
    const out: FavoriteItem[] = [];
    for (let i = 0; i < res.categories.length; i++) {
      const arr: FavoriteItem[] = res.categories[i].items;
      for (let j = 0; j < arr.length; j++) {
        out.push(arr[j]);
      }
    }
    return out;
  }
}
