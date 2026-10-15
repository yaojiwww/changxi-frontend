// 启动页：品牌展示约 3 秒后自动进登录页（EntryAbility 首加载页，路由 pages/SplashPage）
// 版式：吉祥物 ip_hello 居中打招呼 + APP 名 + slogan，配色与全局蓝一致
// 设计约束：内容可见性绝不依赖动画回调——state 用纯赋值驱动，兜底定时器强制显示，
//          任何异常都只会损失「入场动效」，不会让启动页变成白屏
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'SplashPage';

// 启动页停留时长（毫秒）
const SPLASH_HOLD_MS: number = 3200;

@Entry
@ComponentV2
struct SplashPage {
  @Local ready: boolean = false;      // 入场淡入
  @Local floatUp: boolean = false;    // 吉祥物上下轻浮
  private timerId: number = -1;
  private floatTimer: number = -1;
  private entryTimer: number = -1;
  private entryFallback: number = -1;

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'aboutToAppear：启动页已加载');

    // 入场：纯状态赋值驱动（不经 UIContext.animateTo，即使拿不到 context 也不影响可见性），
    // 过渡效果交给各组件的 .animation() 属性
    this.entryTimer = setTimeout(() => {
      this.ready = true;
    }, 60);

    // 兜底：900ms 后仍未就绪就强制显示，确保启动页一定看得见
    this.entryFallback = setTimeout(() => {
      if (!this.ready) {
        hilog.warn(DOMAIN, TAG, '入场兜底触发：强制显示内容');
        this.ready = true;
      }
    }, 900);

    // 吉祥物呼吸式上下浮动
    this.floatTimer = setInterval(() => {
      this.floatUp = !this.floatUp;
    }, 1300);

    // 停留后进登录页（首次安装由登录页再决定是否去引导页）
    this.timerId = setTimeout(() => {
      hilog.info(DOMAIN, TAG, '停留结束，跳转 pages/LoginPage');
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
    }, SPLASH_HOLD_MS);
  }

  aboutToDisappear(): void {
    // 离开页面时清掉定时器，防止重复跳转
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
    if (this.floatTimer !== -1) {
      clearInterval(this.floatTimer);
      this.floatTimer = -1;
    }
    if (this.entryTimer !== -1) {
      clearTimeout(this.entryTimer);
      this.entryTimer = -1;
    }
    if (this.entryFallback !== -1) {
      clearTimeout(this.entryFallback);
      this.entryFallback = -1;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // ===== 装饰：柔和浅蓝大圆（用数字定位，避免百分比/负值在不同机型上的解析差异） =====
      Circle()
        .width(320)
        .height(320)
        .fill('#DCE9FD')
        .opacity(0.55)
        .position({ x: 220, y: -110 })

      Circle()
        .width(200)
        .height(200)
        .fill('#E4EEFE')
        .opacity(0.7)
        .position({ x: -60, y: 620 })

      Circle()
        .width(90)
        .height(90)
        .fill('#DCE9FD')
        .opacity(0.6)
        .position({ x: 48, y: 130 })

      // ===== 中央品牌区 =====
      Column({ space: 14 }) {
        // 吉祥物：白圆底座 + 打招呼袋鼠宝宝
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(168)
            .height(168)
            .fill(Color.White)
            .shadow({ radius: 26, color: '#263B6BF6', offsetY: 10 })

          Image($r('app.media.ip_hello'))
            .width(128)
            .height(128)
            .objectFit(ImageFit.Contain)
            .translate({ y: this.floatUp ? -7 : 0 })
            .animation({ duration: 1300, curve: Curve.EaseInOut })
        }
        .opacity(this.ready ? 1 : 0)
        .scale({ x: this.ready ? 1 : 0.9, y: this.ready ? 1 : 0.9 })
        .animation({ duration: 600, curve: Curve.EaseOut })

        Text('保育通')
          .fontSize(38)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .letterSpacing(6)
          .opacity(this.ready ? 1 : 0)
          .translate({ y: this.ready ? 0 : 12 })
          .animation({ duration: 600, delay: 150, curve: Curve.EaseOut })

        // slogan
        Row({ space: 10 }) {
          Row().width(22).height(1.5).borderRadius(1).backgroundColor('#AECBF8')
          Text('用心保育 · 陪伴成长')
            .fontSize(15.5)
            .fontWeight(FontWeight.Medium)
            .fontColor('#5A6B85')
          Row().width(22).height(1.5).borderRadius(1).backgroundColor('#AECBF8')
        }
        .opacity(this.ready ? 1 : 0)
        .translate({ y: this.ready ? 0 : 12 })
        .animation({ duration: 600, delay: 300, curve: Curve.EaseOut })

        Text('保育师 AI 备考助手')
          .fontSize(12.5)
          .fontColor('#9AA7BC')
          .opacity(this.ready ? 1 : 0)
          .translate({ y: this.ready ? 0 : 12 })
          .animation({ duration: 600, delay: 420, curve: Curve.EaseOut })
      }
      .alignItems(HorizontalAlign.Center)

      // ===== 底部：加载指示 + 标语 =====
      Column({ space: 14 }) {
        LoadingProgress()
          .width(28)
          .height(28)
          .color('#3B6BF6')

        Text('— 备考路上的每一天都算数 —')
          .fontSize(12)
          .fontColor('#B7C1D0')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .position({ y: '82%' })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .linearGradient({
      angle: 180,
      colors: [['#FFFFFF', 0.0], ['#EAF1FC', 1.0]]
    })
  }
}
