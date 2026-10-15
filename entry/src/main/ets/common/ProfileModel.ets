import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

import { AppStorageV2 } from '@kit.ArkUI';

// 个人信息跨页共享模型：@Traceable 字段变更会驱动所有引用页面刷新
@ObservedV2
export class ProfileModel {
  @Trace nickname: string = '用户001';   // 默认昵称，用户可在引导页/我的页自行修改
  @Trace avatarUri: string = '';
  @Trace userId: string = '';
  @Trace phone: string = '';
  @Trace wechatBound: boolean = false;
}

// 掩码手机号：151****7939
export function maskPhone(phone: string): string {
  if (phone.length < 11) {
    return phone;
  }
  return phone.substring(0, 3) + '****' + phone.substring(7);
}

// 手机号格式校验：1 开头 + 10 位数字
export function isValidPhone(phone: string): boolean {
  return /^1[3-9]\d{9}$/.test(phone);
}

const STORE_NAME: string = 'changxi_profile';
const KEY_NICKNAME: string = 'nickname';
const KEY_AVATAR: string = 'avatarUri';

// 个人信息本地缓存：写 preferences，重启后仍能回显
export class ProfileCache {
  private static store: preferences.Preferences | undefined = undefined;

  // 打开存储并把缓存写回共享模型。幂等，可多页调用
  static async load(context: common.Context): Promise<void> {
    if (ProfileCache.store === undefined) {
      ProfileCache.store = await preferences.getPreferences(context, { name: STORE_NAME });
    }
    const model = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
    const nick = await ProfileCache.store.get(KEY_NICKNAME, '') as string;
    if (nick !== '') {
      model.nickname = nick;
    }
    const avatar = await ProfileCache.store.get(KEY_AVATAR, '') as string;
    if (avatar !== '') {
      model.avatarUri = avatar;
    }
  }

  // 接口/选择器成功后落库。只在成功路径调用，失败不碰缓存
  static async saveNickname(nickname: string): Promise<void> {
    const model = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
    model.nickname = nickname;
    const store = ProfileCache.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_NICKNAME, nickname);
    await store.flush();
  }

  static async saveAvatar(avatarUri: string): Promise<void> {
    const model = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
    model.avatarUri = avatarUri;
    const store = ProfileCache.store;
    if (store === undefined) {
      return;
    }
    await store.put(KEY_AVATAR, avatarUri);
    await store.flush();
  }

  // 退出登录/注销后清空
  static async clear(): Promise<void> {
    const model = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
    model.nickname = '用户001';
    model.avatarUri = '';
    model.userId = '';
    model.phone = '';
    model.wechatBound = false;
    const store = ProfileCache.store;
    if (store === undefined) {
      return;
    }
    await store.delete(KEY_NICKNAME);
    await store.delete(KEY_AVATAR);
    await store.flush();
  }
}
