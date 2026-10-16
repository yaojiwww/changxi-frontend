import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppConfig } from '../common/AppConfig';


const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 配置必须先于任何页面就绪。放在这里预加载，页面 aboutToAppear 里的
    // AppConfig.load() 就只会命中缓存直接返回，消除「页面已经能点、配置还没读完」
    // 的竞态；否则发请求时 AppConfig.get() 会抛「AppConfig 未加载」
    this.loadContentAfterConfig(windowStage);

    // ---- 问系统：安全区有多高 ----
    const win = windowStage.getMainWindowSync();
    const topPx = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;      // 状态栏
    const bottomPx = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height;                                                                      // 小白条
    hilog.info(DOMAIN, 'testTag', '状态栏 %{public}dpx / 导航条 %{public}dpx', topPx, bottomPx);

  }

  // 读 rawfile 里的 app_config.json 再进页面。读失败也照常进页面，
  // 只是把原因打到日志里，方便在页面上定位问题
  private async loadContentAfterConfig(windowStage: window.WindowStage): Promise<void> {
    try {
      await AppConfig.load(this.context);
      const cfg = AppConfig.get();
      hilog.info(DOMAIN, 'testTag', 'AppConfig 预加载完成，请求前缀=%{public}s', cfg.baseUrl + cfg.apiPrefix);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'AppConfig 预加载失败：%{public}s', JSON.stringify(err));
    }
    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}