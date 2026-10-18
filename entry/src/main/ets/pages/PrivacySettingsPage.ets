import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 权限卡片条目：key 用于状态映射，icon 来自 app.media
interface PermissionItem {
  key: string;
  title: string;
  desc: string;
  icon: Resource;
}

// 四项权限卡片数据，严格对齐 UI 截图的图标与文案
const PERMISSION_ITEMS: PermissionItem[] = [
  {
    key: 'storage',
    title: '存储空间权限',
    desc: '关闭后，拍照搜题、上传图片照片、保存打卡海报图片等相关功能将无法正常使用',
    icon: $r('app.media.perm_store')
  },
  {
    key: 'camera',
    title: '相机权限',
    desc: '关闭后，拍照搜题、拍照上传等相关功能将无法正常使用',
    icon: $r('app.media.perm_cam')
  },
  {
    key: 'mic',
    title: '麦克风权限',
    desc: '关闭后，语音搜题等功能将无法正常使用',
    icon: $r('app.media.perm_mic')
  },
  {
    key: 'notify',
    title: '通知权限',
    desc: '关闭后，将无法收到账号状态提醒以及优惠信息等内容',
    icon: $r('app.media.perm_bell')
  }
];

// 个人信息保护设置页：读取系统真实权限授权状态，已关闭点击「去设置」跳系统授权页
@Entry
@ComponentV2
struct PrivacySettings {
  // 与 PERMISSION_ITEMS 同序的授权状态：true 已开启 / false 已关闭。
  // 整数组重新赋值触发刷新，避免 @Local 数组元素原地改不驱动渲染
  @Local granted: boolean[] = [false, false, false, false];

  aboutToAppear(): void {
    this.refreshPermissions();
  }

  // 从系统设置返回本页时重新读取，保持状态真实
  onPageShow(): void {
    this.refreshPermissions();
  }

  // 读取四项权限真实状态：存储/相机/麦克风走 checkAccessToken，通知走 notificationManager
  private async refreshPermissions(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    const tokenId = context.applicationInfo.accessTokenId;
    const storage = await this.checkPermission(tokenId, 'ohos.permission.READ_MEDIA');
    const camera = await this.checkPermission(tokenId, 'ohos.permission.CAMERA');
    const mic = await this.checkPermission(tokenId, 'ohos.permission.MICROPHONE');
    const notify = await this.checkNotify();
    this.granted = [storage, camera, mic, notify];
  }

  // 查单个 user_grant 权限。任何异常按未授权处理（可点去设置）
  private async checkPermission(tokenId: number, permission: Permissions): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const status = await atManager.checkAccessToken(tokenId, permission);
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      return false;
    }
  }

  // 查通知开关（通知不是 runtime 权限，单独走 notificationManager）
  private async checkNotify(): Promise<boolean> {
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (err) {
      return false;
    }
  }

  // 跳系统设置：存储/相机/麦克风用 openPermissionOnSetting 直跳对应授权页，
  // 通知用 openNotificationSettings 打开本应用通知设置半模页
  private async openSettingFor(index: number): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    try {
      if (index === 3) {
        await notificationManager.openNotificationSettings(context as common.UIAbilityContext);
        return;
      }
      const permissions: Permissions[] = ['ohos.permission.READ_MEDIA', 'ohos.permission.CAMERA', 'ohos.permission.MICROPHONE'];
      const atManager = abilityAccessCtrl.createAtManager();
      await atManager.openPermissionOnSetting(context, permissions[index]);
    } catch (err) {
      const e = err as BusinessError;
      this.getUIContext().getPromptAction().showToast({ message: `无法打开系统设置(${e.code})`, duration: 2500 });
    }
  }

  build() {
    Column() {
      // 顶部返回栏：同设置页样式
      Row() {
        Text('‹')
          .fontSize(34.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#55402F')
          .padding({ left: 16, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text('个人信息保护设置')
          .fontSize(19.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F2ECD8' })

      // 权限卡片列表
      Scroll() {
        Column({ space: 16 }) {
          ForEach(PERMISSION_ITEMS, (item: PermissionItem, index: number) => {
            this.PermissionCard(item, index)
          }, (item: PermissionItem, index: number) => `${item.key}-${index}`)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 32 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }

  // 单个权限卡片：图标 + 标题 + 右侧状态（已开启 / 去设置）+ 描述小字
  @Builder
  PermissionCard(item: PermissionItem, index: number) {
    Column({ space: 12 }) {
      Row() {
        Image(item.icon)
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)

        Text(item.title)
          .fontSize(18.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .margin({ left: 10 })
          .layoutWeight(1)

        if (this.granted[index]) {
          Text('已开启')
            .fontSize(16.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2E9E63')
        } else {
          Row({ space: 2 }) {
            Text('去设置')
              .fontSize(16.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#E4842A')
            Text('›')
              .fontSize(18.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#E4842A')
          }
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(item.desc)
        .fontSize(14.0)
        .fontColor('#9A8A6E')
        .lineHeight(20)
        .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      if (!this.granted[index]) {
        this.openSettingFor(index);
      }
    })
  }
}
