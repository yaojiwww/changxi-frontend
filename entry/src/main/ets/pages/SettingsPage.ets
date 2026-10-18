import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { AppConfig } from '../common/AppConfig';
import { TokenStore } from '../common/TokenStore';
import { UserApi } from '../api/UserApi';
import { CODE_OK } from '../common/Http';
import { SettingsDetailParams } from './SettingsDetailPage';
import { ExamDateModel, ExamDateCache, formatExamDateCN, parseExamDate } from '../common/ExamDateModel';

// 设置页：移动端列表布局，每项「标题 + 右侧值 + 右箭头」，底部固定退出登录
@Entry
@ComponentV2
struct Settings {
  // 版本更新行的右侧值 = 本机安装的版本号
  @Local localVersion: string = '';
  @Local isLoggingOut: boolean = false;
  // 跨页共享的考试目标日期：选择器确定后回显，首页倒计时同源
  @Local examDate: ExamDateModel = AppStorageV2.connect(ExamDateModel, () => new ExamDateModel())!;

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await AppConfig.load(context);
    await TokenStore.init(context);
    await ExamDateCache.load(context);   // 读考试日期缓存，为空则回显未设置
    this.loadLocalVersion();
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  // 读本机版本号，供版本更新行展示
  private loadLocalVersion(): void {
    const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    this.localVersion = info.versionName;
  }

  // 进通用详情页（协议 / 清单 / 个人信息等共用）
  private openDetail(title: string): void {
    const params: SettingsDetailParams = { title: title };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/SettingsDetailPage', params: params });
  }

  // 弹原生日期选择器（底部弹出，年/月/日）。确定后持久化并同步共享模型
  private openDatePicker(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date(2020, 0, 1),
      end: new Date(2040, 11, 31),
      selected: this.examDate.dateStr === '' ? new Date() : parseExamDate(this.examDate.dateStr),
      onAccept: (value: DatePickerResult) => {
        // 本 SDK 的 DatePickerResult.month/.day 为可选类型，判空兜底按当前月日
        const now = new Date();
        const month = value.month ?? (now.getMonth() + 1);
        const day = value.day ?? now.getDate();
        // month 为 1-12，统一补零成 YYYY-MM-DD 落库
        const monthStr = month < 10 ? `0${month}` : `${month}`;
        const dayStr = day < 10 ? `0${day}` : `${day}`;
        const dateStr = `${value.year}-${monthStr}-${dayStr}`;
        ExamDateCache.saveDate(dateStr);
        this.toast(`考试时间已设为${formatExamDateCN(dateStr)}`);
      }
    });
  }

  // 检查更新：对比后端最新版本与本机版本，只 toast 结果
  private async checkUpdate(): Promise<void> {
    try {
      const token = await TokenStore.read();
      const res = await UserApi.appVersion(token);
      if (res.code !== CODE_OK || res.data === null) {
        this.toast(res.message);
        return;
      }
      if (res.data.version !== this.localVersion) {
        this.toast(`发现新版本 ${res.data.version}：${res.data.note}`);
      } else {
        this.toast('已是最新版本');
      }
    } catch (err) {
      const e = err as BusinessError;
      this.toast(`网络异常(${e.code})，请检查网络或服务器`);
    }
  }

  // 退出登录：确认后调接口（失败不阻断），清本地 token 回登录页
  private async doLogout(): Promise<void> {
    const resp = await this.getUIContext().getPromptAction().showDialog({
      title: '退出登录',
      message: '确定要退出当前账号吗？',
      buttons: [
        { text: '取消', color: '#9A8A6E' },
        { text: '退出登录', color: '#D9534F', primary: true }
      ]
    });
    if (resp.index !== 1) {
      return;
    }

    this.isLoggingOut = true;
    try {
      const token = await TokenStore.read();
      await UserApi.logout(token);
    } catch (err) {
      // 网络异常也继续本地退出，避免用户被卡在已登录界面
    }
    await TokenStore.clear();
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
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

        Text('账号与设置')
          .fontSize(19.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F2ECD8' })

      // 列表区
      Scroll() {
        Column() {
          // 静态列表项
          this.SettingsRow('个人信息', '')
          Divider().color('#FEF8E3').strokeWidth(1)

          // 考试时间：右侧显示已设日期（未设置显示"未设置"），点击弹日期选择器。
          // 状态驱动文本直接内联读 @Local，避免 @Builder 传参在状态变化时不刷新
          Row() {
            Text('考试时间')
              .fontSize(18.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#55402F')
              .layoutWeight(1)
            Text(this.examDate.dateStr === '' ? '未设置' : formatExamDateCN(this.examDate.dateStr))
              .fontSize(18.0)
              .fontColor('#9A8A6E')
              .margin({ right: 6 })
            Text('›')
              .fontSize(21.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#B5A98D')
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 14, bottom: 14 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.openDatePicker();
          })
          Divider().color('#FEF8E3').strokeWidth(1)

          // 版本更新：右侧显示本机版本，点击检查更新
          Row() {
            Text('版本更新')
              .fontSize(18.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#55402F')
              .layoutWeight(1)
            Text(this.localVersion)
              .fontSize(18.0)
              .fontColor('#9A8A6E')
              .margin({ right: 6 })
            Text('›')
              .fontSize(26.0)
              .fontWeight(FontWeight.Medium)
              .fontColor('#B5A98D')
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 14, bottom: 14 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.checkUpdate();
          })
          Divider().color('#FEF8E3').strokeWidth(1)

          this.SettingsRow('用户协议', '')
          Divider().color('#FEF8E3').strokeWidth(1)
          this.SettingsRow('隐私政策', '')
          Divider().color('#FEF8E3').strokeWidth(1)
          this.SettingsRow('个人信息保护设置', '')
          Divider().color('#FEF8E3').strokeWidth(1)
          this.SettingsRow('更多设置', '')
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
      .width('100%')

      // 底部固定退出登录
      Column() {
        Button('退出登录')
          .width('100%')
          .height(48)
          .borderRadius(24)
          .backgroundColor(Color.White)
          .fontColor('#D9534F')
          .fontSize(18.0)
          .fontWeight(FontWeight.Medium)
          .border({ width: 1, color: '#FDF3DC' })
          .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })
          .enabled(!this.isLoggingOut)
          .onClick(() => {
            this.doLogout();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 24 })
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 1 }, color: '#F2ECD8' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }

  // 通用列表项：标题 + 右侧值（可空） + 右箭头；跳转类标题在此处约定
  @Builder
  SettingsRow(title: string, value: string) {
    Row() {
      Text(title)
        .fontSize(18.0)
        .fontWeight(FontWeight.Medium)
        .fontColor('#55402F')
        .layoutWeight(1)

      if (value !== '') {
        Text(value)
          .fontSize(18.0)
          .fontColor('#9A8A6E')
          .margin({ right: 6 })
      }

      Text('›')
        .fontSize(21.0)
        .fontWeight(FontWeight.Medium)
        .fontColor('#B5A98D')
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onRowClick(title);
    })
  }

  // 列表项跳转分发
  private onRowClick(title: string): void {
    if (title === '更多设置') {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/MoreSettingsPage' });
      return;
    }
    if (title === '个人信息') {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/ProfilePage' });
      return;
    }
    if (title === '个人信息保护设置') {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/PrivacySettingsPage' });
      return;
    }
    this.openDetail(title);
  }
}
