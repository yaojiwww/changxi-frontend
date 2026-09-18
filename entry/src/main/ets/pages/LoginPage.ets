import { router } from '@kit.ArkUI';
import { AuthViewModel } from '../viewmodel/AuthViewModel';
import { CodePurpose } from '../network/ApiTypes';

/** 登录 / 注册页。UI 只调 vm 的方法，业务全在 AuthViewModel 里。 */
@Entry
@Component
struct LoginPage {
  @State vm: AuthViewModel = new AuthViewModel();
  /** false = 登录模式，true = 注册模式 */
  @State isRegisterMode: boolean = false;

  aboutToAppear(): void {
    this.vm.refreshLoginState();
  }

  build() {
    Column() {
      Text(this.isRegisterMode ? '注册' : '登录')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ top: 60, bottom: 40 })

      if (this.vm.isLoggedIn) {
        this.LoggedInPanel()
      } else {
        this.FormPanel()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24 })
    .backgroundColor(Color.White)
  }

  @Builder
  LoggedInPanel() {
    Text('已登录')
      .fontSize(18)
      .fontColor('#4CAF50')
      .margin({ bottom: 30 })

    Button('去和 AI 聊天')
      .width('100%')
      .height(48)
      .borderRadius(24)
      .backgroundColor('#0D8AFF')
      .margin({ bottom: 16 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/ChatPage' }).catch((err: Error) => {
          console.error(`[LoginPage] 跳转失败: ${err.message}`);
        });
      })

    Button('退出登录')
      .width('100%')
      .height(48)
      .borderRadius(24)
      .backgroundColor('#BDBDBD')
      .enabled(!this.vm.isLoading)
      .onClick(() => {
        this.vm.logout();
      })
  }

  @Builder
  FormPanel() {
    TextInput({ placeholder: '手机号', text: this.vm.phone })
      .type(InputType.PhoneNumber)
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(24)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 14 })
      .onChange((v: string) => {
        this.vm.updatePhone(v);
      })

    if (this.isRegisterMode) {
      Row({ space: 10 }) {
        TextInput({ placeholder: '验证码', text: this.vm.code })
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(24)
          .padding({ left: 16, right: 16 })
          .onChange((v: string) => {
            this.vm.updateCode(v);
          })

        Button(this.vm.codeSent ? '已发送' : '获取验证码')
          .height(48)
          .fontSize(14)
          .borderRadius(24)
          .backgroundColor('#E6F7FF')
          .fontColor('#007AFF')
          .enabled(!this.vm.isLoading && !this.vm.codeSent)
          .onClick(() => {
            this.vm.sendCode(CodePurpose.REGISTER);
          })
      }
      .width('100%')
      .margin({ bottom: 14 })
    }

    TextInput({ placeholder: '密码', text: this.vm.password })
      .type(InputType.Password)
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(24)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 20 })
      .onChange((v: string) => {
        this.vm.updatePassword(v);
      })

    if (this.vm.errorMessage.length > 0) {
      Text(this.vm.errorMessage)
        .fontSize(13)
        .fontColor('#D32F2F')
        .width('100%')
        .margin({ bottom: 12 })
    }

    Button(this.isRegisterMode ? '注册' : '登录')
      .width('100%')
      .height(48)
      .borderRadius(24)
      .backgroundColor('#0D8AFF')
      .enabled(!this.vm.isLoading)
      .margin({ bottom: 16 })
      .onClick(() => {
        if (this.isRegisterMode) {
          this.vm.register();
        } else {
          this.vm.login();
        }
      })

    if (this.vm.isLoading) {
      LoadingProgress().width(32).height(32).color('#0D8AFF')
    }

    Text(this.isRegisterMode ? '已有账号？去登录' : '没有账号？去注册')
      .fontSize(14)
      .fontColor('#007AFF')
      .onClick(() => {
        this.isRegisterMode = !this.isRegisterMode;
      })
  }
}
