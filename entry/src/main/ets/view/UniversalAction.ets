// 通用交互组件：TAP 点击 / LONG_PRESS 长按进度条

import { FirstAidStep, ActionType } from '../../model/FirstAidStep';

@Component
export struct UniversalAction {
  @Prop currentStep: FirstAidStep;
  onStepComplete?: () => void;

  @State private progress: number = 0;
  private timerId: number = -1;
  private readonly LONG_PRESS_DURATION: number = 800;

  aboutToDisappear() {
    this.stopAnimation();
  }

  build() {
    Column() {
      if (this.currentStep.actionType === ActionType.LONG_PRESS) {
        Column() {
          Text(this.currentStep.title)
            .fontSize(16)
            .fontColor(Color.White)
          Text('请长按 0.8 秒')
            .fontSize(12)
            .fontColor('#E0E0E0')
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

        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .color('#4A90E2')
          .backgroundColor('#E5E5E5')
          .margin({ top: 10 })
          .borderRadius(5)
      } else {
        Button(this.currentStep.title)
          .width('100%')
          .height(60)
          .backgroundColor('#4A90E2')
          .onClick(() => {
            this.onStepComplete?.();
          })
      }
    }
    .width('100%')
    .padding(16)
  }

  startAnimation(): void {
    this.stopAnimation();
    this.progress = 0;
    this.timerId = setInterval(() => {
      this.progress += 100 / (this.LONG_PRESS_DURATION / 50);
      if (this.progress >= 100) {
        this.stopAnimation();
        this.onStepComplete?.();
      }
    }, 50);
  }

  stopAnimation(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.progress = 0;
  }
}
