// 通用交互组件（支持TAP点击和LONG_PRESS长按进度条两种模式）

import { FirstAidStep, ActionType } from '../mock/types';

@Component
export struct UniversalAction {
  // 接收外部传入的当前步骤数据
  @Prop currentStep: FirstAidStep;
  // 步骤完成后的回调
  onStepComplete?: () => void;

  // 动画状态管理
  @State private progress: number = 0;
  private timerId: number = 0;
  private readonly LONG_PRESS_DURATION: number = 800; // 长按判定时间 800ms

  // 组件销毁时清理定时器
  aboutToDisappear() {
    clearInterval(this.timerId);
  }

  build() {
    Column() {
      // 根据动作类型渲染不同的UI
      if (this.currentStep.actionType === ActionType.LONG_PRESS) {
        // --- 长按模式：带进度条的动画交互 ---
        Column() {
          Text(this.currentStep.title)
            .fontSize(16)
            .fontColor(Color.White)
          Text('请长按 0.8 秒')
            .fontSize(12)
            .fontColor(Color.Gray)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#4A90E2')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.startAnimation();
          } else {
            this.stopAnimation();
          }
        })
      } else {
        // --- 点击模式：简单的点击交互 ---
        Button(this.currentStep.title)
          .width('100%')
          .height(60)
          .backgroundColor('#4A90E2')
          .onClick(() => {
            this.onStepComplete?.();
          })
      }

      // 仅在长按模式下显示进度条
      if (this.currentStep.actionType === ActionType.LONG_PRESS) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .color('#4A90E2')
          .backgroundColor('#E5E5E5')
          .margin({ top: 10 })
          .borderRadius(5)
      }
    }
    .width('100%')
    .padding(16)
  }

  // 启动动画逻辑
  startAnimation(): void {
    this.progress = 0;
    this.stopAnimation(); // 防止重复启动
    this.timerId = setInterval(() => {
      this.progress += 100 / (this.LONG_PRESS_DURATION / 50); // 每50ms更新一次进度
      if (this.progress >= 100) {
        this.stopAnimation();
        this.onStepComplete?.(); // 动画完成，触发回调
      }
    }, 50);
  }

  // 停止动画逻辑
  stopAnimation(): void {
    clearInterval(this.timerId);
    this.progress = 0;
  }
}