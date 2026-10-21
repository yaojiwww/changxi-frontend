import { common } from '@kit.AbilityKit';
import { TokenStore } from './TokenStore';
import { ProfileCache } from './ProfileModel';
import { GoalCache } from './GoalModel';
import { ExamDateCache } from './ExamDateModel';
import { FavoritesStore } from './FavoritesStore';
import { WrongBookStore } from './WrongBookStore';
import { StudyRecordStore } from './StudyRecordStore';
import { ExamStore } from './ExamStore';
import { AccountScope } from './AccountScope';
import { OnboardingCache } from './OnboardingCache';

// =============================================================================
// 会话生命周期统一入口
//
// 之前「退出登录」有三套实现：个人页清 token + 资料，设置页只清 token，
// 换号清目标/日期/昵称。同一个语义三种结果，加一个 Store 必然漏清。
//
// 现在：
//   onAccountChanged  换号 → 删除上一个账号的学习数据 + 清共享资料
//   logout            退出 → 只清 token 和内存；账号级数据留在各自账号下，
//                           同一账号重新登录可以恢复
//   wipeCurrentAccount 注销 → 连当前账号的本地数据一起删
//
// 账号级 Store 的 key 由 AccountScope 加前缀，所以磁盘数据本身不会串号；
// 这里额外删除上一个账号的数据，是为了不让换号后的设备留着别人的记录。
// =============================================================================
export class SessionService {
  // 登录成功且账号发生变化时调用。previous 为空表示首次绑定，不需要清理
  static async onAccountChanged(previous: string, current: string,
    context?: common.Context): Promise<void> {
    if (previous === '' || previous === current) {
      return;
    }

    // 先打开落盘对象，才能删除 previous 账号名下的 key。
    // 此时 AccountScope 已经是新账号，init 读到的是新账号的数据，随后 reset 掉。
    if (context !== undefined) {
      await SessionService.initStores(context);
    }

    await GoalCache.clear();
    await ExamDateCache.clear();
    await ProfileCache.clear();
    await FavoritesStore.clearAccount(previous);
    await WrongBookStore.clearAccount(previous);
    await StudyRecordStore.clearAccount(previous);
    await ExamStore.clearAccount(previous);
    SessionService.resetMemory();
  }

  // 退出登录：清 token + 内存。磁盘数据按账号保留，重新登录同一账号可恢复
  static async logout(context?: common.Context): Promise<void> {
    if (context !== undefined) {
      await TokenStore.init(context);
    }
    await TokenStore.clear();
    SessionService.resetMemory();
  }

  // 注销账号：当前账号的本地数据一并删除
  static async wipeCurrentAccount(context: common.Context): Promise<void> {
    const accountKey: string = AccountScope.current();
    await SessionService.initStores(context);
    await OnboardingCache.init(context);

    await TokenStore.clear();
    await ProfileCache.clear();
    await GoalCache.clear();
    await ExamDateCache.clear();
    if (accountKey !== '') {
      await FavoritesStore.clearAccount(accountKey);
      await WrongBookStore.clearAccount(accountKey);
      await StudyRecordStore.clearAccount(accountKey);
      await ExamStore.clearAccount(accountKey);
      await OnboardingCache.clearAccount(accountKey);
    }
    await AccountScope.clear();
    SessionService.resetMemory();
  }

  // 清掉内存缓存，下次 init 按当前账号重新加载
  static resetMemory(): void {
    FavoritesStore.reset();
    WrongBookStore.reset();
    StudyRecordStore.reset();
    ExamStore.reset();
  }

  private static async initStores(context: common.Context): Promise<void> {
    await FavoritesStore.init(context);
    await WrongBookStore.init(context);
    await StudyRecordStore.init(context);
    await ExamStore.init(context);
  }
}
