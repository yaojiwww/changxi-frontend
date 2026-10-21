import { AppStorageV2 } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { GoalCache, GoalModel, LEVEL_BEGINNER } from '../common/GoalModel';
import { ProfileCache, ProfileModel } from '../common/ProfileModel';
import { ExamDateCache, ExamDateModel } from '../common/ExamDateModel';
import { OnboardingCache } from '../common/OnboardingCache';
import { TokenStore } from '../common/TokenStore';
import { ProfileApi } from '../api/ProfileApi';

// 新用户引导页 ViewModel：目标级别、昵称、考试时间与落库逻辑都在这里，页面只负责渲染。
// 失败 throw Error，由页面 catch 后 toast。
@ObservedV2
export class OnboardingViewModel {
  @Trace selectedLevel: number = LEVEL_BEGINNER;   // 未选择时就是初级（跳过即默认初级）
  @Trace nickname: string = '用户001';             // 默认昵称，用户可自行修改
  @Trace dateStr: string = '';                     // YYYY-MM-DD，空串=未设置
  @Trace isSaving: boolean = false;

  // 页面 aboutToAppear 调一次：准备存储，并把已有缓存回显到表单
  async init(context: common.Context): Promise<void> {
    await GoalCache.init(context);
    await GoalCache.load(context);
    await ProfileCache.init(context);
    await ProfileCache.load(context);
    await ExamDateCache.init(context);
    await ExamDateCache.load(context);
    await OnboardingCache.init(context);
    await TokenStore.init(context);

    const goal: GoalModel = AppStorageV2.connect(GoalModel, () => new GoalModel())!;
    this.selectedLevel = goal.levelIndex;

    const profile: ProfileModel = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
    this.nickname = profile.nickname;

    const exam: ExamDateModel = AppStorageV2.connect(ExamDateModel, () => new ExamDateModel())!;
    this.dateStr = exam.dateStr;
  }

  // 开始备考：本地落库 + 昵称尽力同步服务端，然后标记引导完成
  async start(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      await GoalCache.saveLevel(this.selectedLevel);
      if (this.nickname !== '') {
        await ProfileCache.saveNickname(this.nickname);
        // 不阻塞进首页：接口未上线/网络慢都只影响服务端同步，本地已经保存
        this.syncNickname(this.nickname);
      }
      if (this.dateStr !== '') {
        await ExamDateCache.saveDate(this.dateStr);
      }
      await OnboardingCache.markDone();
    } finally {
      this.isSaving = false;
    }
  }

  // 跳过：目标按初级落库，其余不写，之后可在设置里改
  async skip(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      await GoalCache.saveLevel(LEVEL_BEGINNER);
      await OnboardingCache.markDone();
    } finally {
      this.isSaving = false;
    }
  }

  // 昵称同步服务端。后端 /user/update/nickname 尚未上线（当前返回 1004 接口不存在），
  // 所以这里只做「尽力而为」：失败保留本地值，绝不阻塞进首页。
  private async syncNickname(nickname: string): Promise<void> {
    try {
      const token: string = await TokenStore.read();
      if (token === '') {
        return;
      }
      await ProfileApi.updateNickname(token, nickname);
    } catch (err) {
      // 网络异常 / 接口未实现都按本地保存成功处理
    }
  }
}
