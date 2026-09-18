import { router } from '@kit.ArkUI';
import { TrainingViewModel, TrainingStage } from '../viewmodel/TrainingViewModel';
import { HomeContent } from './components/HomeContent';
import { SideMenu } from './components/SideMenu';
import { ScenarioDialog } from './components/ScenarioDialog';
import { QuizDialog } from './components/QuizDialog';
import { TrainingStepView } from './components/TrainingStepView';

/**
 * 首页。
 *
 * 重构后这里只负责两件事：
 *   1. 持有 ViewModel
 *   2. 根据 vm.stage 决定显示哪个组件
 * 所有业务判断都在 TrainingViewModel 里，这里不写 if 业务逻辑。
 */
@Entry
@Component
struct Index {
  @State vm: TrainingViewModel = new TrainingViewModel();
  @State isMenuVisible: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {

      HomeContent({
        onOpenMenu: () => {
          this.isMenuVisible = true;
        },
        onStartTraining: () => {
          this.vm.openScenarioPicker();
        },
        onOpenChat: () => {
          this.goto('pages/ChatPage');
        },
        onOpenLogin: () => {
          this.goto('pages/LoginPage');
        }
      })

      // ---- 侧边栏 ----
      if (this.isMenuVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .onClick(() => {
            this.isMenuVisible = false;
          })
          .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
          .zIndex(99)

        SideMenu({
          onClose: () => {
            this.isMenuVisible = false;
          },
          onOpenTraining: () => {
            this.vm.openScenarioPicker();
          },
          onOpenChat: () => {
            this.goto('pages/ChatPage');
          },
          onOpenLogin: () => {
            this.goto('pages/LoginPage');
          }
        })
          .width('75%')
          .height('100%')
          .zIndex(100)
      }

      // ---- 场景选择 ----
      if (this.vm.stage === TrainingStage.SELECT_SCENARIO) {
        ScenarioDialog({ vm: this.vm })
          .zIndex(200)
      }

      // ---- 培训步骤 ----
      if (this.vm.stage === TrainingStage.TRAINING) {
        TrainingStepView({ vm: this.vm })
          .zIndex(150)
      }

      // ---- 测试弹窗 ----
      if (this.vm.isTestStage) {
        QuizDialog({ vm: this.vm })
          .zIndex(200)
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 页面跳转。url 必须与 main_pages.json 里登记的路径一致 */
  private goto(url: string): void {
    router.pushUrl({ url: url }).catch((err: Error) => {
      console.error(`[Index] 跳转 ${url} 失败: ${err.message}`);
    });
  }
}
