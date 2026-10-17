import { BusinessError } from '@kit.BasicServicesKit';
import { AppConfig } from '../common/AppConfig';
import { TokenStore } from '../common/TokenStore';
import { UserApi } from '../api/UserApi';
import { CODE_OK } from '../common/Http';

// 更多设置页：只保留「注销账号」入口，点击弹二次确认
@Entry
@ComponentV2
struct MoreSettings {
  @Local isDeleting: boolean = false;

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await AppConfig.load(context);
    await TokenStore.init(context);
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  // 二次确认后注销：接口成功才清本地并回登录页，失败保留登录态
  private async doDeleteAccount(): Promise<void> {
    const resp = await this.getUIContext().getPromptAction().showDialog({
      title: '注销账号',
      message: '注销后账号信息将被删除且无法恢复，确定继续吗？',
      buttons: [
        { text: '取消', color: '#9A8A6E' },
        { text: '确认注销', color: '#D9534F', primary: true }
      ]
    });
    if (resp.index !== 1) {
      return;
    }

    this.isDeleting = true;
    try {
      const token = await TokenStore.read();
      const res = await UserApi.deleteAccount(token);
      if (res.code !== CODE_OK) {
        this.toast(res.message);
        return;
      }
      await TokenStore.clear();
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
    } catch (err) {
      const e = err as BusinessError;
      this.toast(`网络异常(${e.code})，请检查网络或服务器`);
    } finally {
      this.isDeleting = false;
    }
  }

  build() {
    Column() {
      // 顶部返回栏
      Row() {
        Text('‹')
          .fontSize(34.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#55402F')
          .padding({ left: 16, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text('更多设置')
          .fontSize(18.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F2ECD8' })

      Scroll() {
        Column() {
          // 注销账号入口
          Row() {
            Text('注销账号')
              .fontSize(16.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#D9534F')
              .layoutWeight(1)

            Text('›')
              .fontSize(21.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#B5A98D')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor(Color.White)
          .borderRadius(16)
          .border({ width: 1, color: '#F2ECD8' })
          .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })
          .alignItems(VerticalAlign.Center)
          .enabled(!this.isDeleting)
          .onClick(() => {
            this.doDeleteAccount();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })
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
}
