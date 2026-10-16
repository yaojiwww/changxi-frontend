import { LoginViewModel } from '../viewmodel/LoginViewModel';

@Entry
@ComponentV2
struct Login {
  @Local vm: LoginViewModel = new LoginViewModel();

  // 页面出现前，先把配置和本地存储准备好，避免第一次点登录时还没就绪
  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await this.vm.init(context);
  }

  private async doLogin(): Promise<void> {
    try {
      await this.vm.login();
      this.getUIContext().getRouter().replaceUrl({
        url: this.vm.needOnboarding ? 'pages/OnboardingPage' : 'pages/HomePage'
      });
    } catch (err) {
      this.toast((err as Error).message);
    }
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  build() {
    Column() {
      // ===== 顶部弹性留白（品牌区落在约 20% 高度处，与底部对称） =====
      Blank()
        .layoutWeight(4.5)

      // ===== 品牌区：渐变圆 + 名称 =====
      Column({ space: 14 }) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(88)
            .height(88)
            .borderRadius(44)
            .linearGradient({
              angle: 135,
              colors: [['#4A7BF8', 0.0], ['#2B57E5', 1.0]]
            })
            .shadow({ radius: 14, color: '#332B57E5', offsetY: 6 })

          Text('保')
            .fontSize(39.0)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }

        Text('保育通')
          .fontSize(35.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')

        Text('保育师备考助手 · 用心保育 陪伴成长')
          .fontSize(14.5)
          .fontColor('#8A94A6')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // ===== 中部弹性留白（品牌区与表单之间，收紧避免大段空白） =====
      Blank()
        .layoutWeight(2)

      // ===== 输入卡片：手机号 + 密码（逻辑与原来完全一致） =====
      Column() {
        TextInput({ placeholder: '手机号' })
          .type(InputType.PhoneNumber)
          .height(52)
          .backgroundColor(Color.Transparent)
          .padding({ left: 6, right: 6 })
          .placeholderColor('#A8B3C5')
          .onChange((v: string) => { this.vm.phone = v })

        Divider()
          .color('#F1F4F9')
          .strokeWidth(1)

        TextInput({ placeholder: '密码' })
          .type(InputType.Password)
          .height(52)
          .backgroundColor(Color.Transparent)
          .padding({ left: 6, right: 6 })
          .placeholderColor('#A8B3C5')
          .onChange((v: string) => { this.vm.password = v })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .borderRadius(20)
      .backgroundColor(Color.White)
      .border({ width: 1, color: '#EEF2F6' })
      .shadow({ radius: 12, color: '#14000000', offsetY: 4 })

      // 主按钮
      Button(this.vm.isLoading ? '登录中…' : '登 录')
        .width('100%')
        .height(52)
        .borderRadius(26)
        .backgroundColor('#3B6BF6')
        .fontColor(Color.White)
        .fontSize(18.0)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20 })
        .enabled(!this.vm.isLoading)              // 请求中禁用，防重复点
        .shadow({ radius: 10, color: '#263B6BF6', offsetY: 4 })
        .onClick(() => { this.doLogin() })

      // ===== 用户协议与隐私政策勾选 =====
      Row({ space: 5 }) {
        // 自绘勾选框
        Column() {
          if (this.vm.agreed) {
            Text('✓')
              .fontSize(13.0)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
        }
        .width(17)
        .height(17)
        .borderRadius(9)
        .backgroundColor(this.vm.agreed ? '#3B6BF6' : Color.Transparent)
        .border({ width: 1.5, color: this.vm.agreed ? '#3B6BF6' : '#C4CEDC' })
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.vm.agreed = !this.vm.agreed;
        })

        Text('我已阅读并同意')
          .fontSize(13.0)
          .fontColor('#8A94A6')

        Text('《用户协议》')
          .fontSize(13.0)
          .fontColor('#3B6BF6')
          .onClick(() => {
            this.toast('协议内容整理中');
          })

        Text('和')
          .fontSize(13.0)
          .fontColor('#8A94A6')

        Text('《隐私政策》')
          .fontSize(13.0)
          .fontColor('#3B6BF6')
          .onClick(() => {
            this.toast('协议内容整理中');
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 16 })

      // ===== 底部弹性留白 + 底部标语（与顶部对称，标语贴底） =====
      Blank()
        .layoutWeight(4.5)

      Text('— 备考路上的每一天都算数 —')
        .fontSize(13.0)
        .fontColor('#B7C1D0')
        .margin({ bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .padding({ left: 28, right: 28 })
    .linearGradient({
      angle: 180,
      colors: [['#FFFFFF', 0.0], ['#EAF1FC', 1.0]]
    })
  }
}
