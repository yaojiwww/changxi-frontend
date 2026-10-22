import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, display } from '@kit.ArkUI';
import { SafeArea } from '../common/SafeArea';


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

    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      // 窗口底色与页面背景同色，消除状态栏/导航栏区域露出的白边
      try {
        const mainWindow = windowStage.getMainWindowSync();
        mainWindow.setWindowBackgroundColor('#FDFDED');
      } catch (err) {
        hilog.error(DOMAIN, 'testTag', 'Failed to set window background. Cause: %{public}s', JSON.stringify(err));
      }
    });
    // ---- 问系统：安全区有多高，并做沉浸式适配（适配任何机型，不写死数字） ----
    const win = windowStage.getMainWindowSync();
    // 状态栏底色与页面同色、图标用深色：非沉浸式页面顶部不再出现白条
    win.setWindowSystemBarProperties({
      statusBarColor: '#FDFDED',
      statusBarContentColor: '#55402F'
    }).catch((err: Object) => {
      hilog.error(DOMAIN, 'testTag', 'setWindowSystemBarProperties failed: %{public}s', JSON.stringify(err));
    });
    // 状态栏/小白条高度换算成 vp 存到全局，供页面做 padding（vp = px / 屏幕密度）
    const topPx = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;      // 状态栏
    const bottomPx = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height;                                                                      // 小白条
    const density = display.getDefaultDisplaySync().densityPixels;
    SafeArea.topVp = topPx / density;
    SafeArea.bottomVp = bottomPx / density;
    hilog.info(DOMAIN, 'testTag', '状态栏 %{public}dpx / 导航条 %{public}dpx => vp %{public}f / %{public}f',
      topPx, bottomPx, SafeArea.topVp, SafeArea.bottomVp);

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