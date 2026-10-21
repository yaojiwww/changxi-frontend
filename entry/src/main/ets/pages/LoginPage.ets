import { LoginViewModel } from '../viewmodel/LoginViewModel';

@Entry
@ComponentV2
struct Login {
  // 登录态与取数逻辑全在 ViewModel 里，页面只负责渲染和跳转
  @Local vm: LoginViewModel = new LoginViewModel();

  // 页面出现前，先把配置和本地存储准备好，避免第一次点登录时还没就绪
  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      this.toast('页面上下文获取失败，请重启应用');
      return;
    }
    await this.vm.init(context);
  }

  aboutToDisappear(): void {
    this.vm.dispose();   // 清掉验证码倒计时，避免页面销毁后定时器还在跑
  }

  // 登录/注册：调后端 → 存 token → 进引导页 / 首页
  private async doSubmit(): Promise<void> {
    try {
      await this.vm.submit();
      this.getUIContext().getRouter().replaceUrl({
        url: this.vm.needOnboarding ? 'pages/OnboardingPage' : 'pages/HomePage'
      });
    } catch (err) {
      this.toast((err as Error).message);
    }
  }

  // 注册模式下获取验证码（开发期验证码打在后端终端）
  private async doSendCode(): Promise<void> {
    try {
      await this.vm.sendCode();
      this.toast('验证码已发送');
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
            .backgroundColor('#FEF8E3')
            .shadow({ radius: 14, color: '#14000000', offsetY: 6 })

          // 品牌 IP：探险家小男孩挥手（与启动页同源形象）
          Image($r('app.media.ip_hello'))
            .width(72)
            .height(72)
            .objectFit(ImageFit.Contain)
        }

        Text('保育通')
          .fontSize(35.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')

        Text('保育师备考助手 · 用心保育 陪伴成长')
          .fontSize(14.5)
          .fontColor('#9A8A6E')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // ===== 中部弹性留白（品牌区与表单之间，收紧避免大段空白） =====
      Blank()
        .layoutWeight(2)

      // ===== 输入卡片：手机号 +（注册时）验证码 + 密码 =====
      Column() {
        TextInput({ placeholder: '手机号' })
          .type(InputType.PhoneNumber)
          .height(52)
          .backgroundColor(Color.Transparent)
          .padding({ left: 6, right: 6 })
          .placeholderColor('#B5A98D')
          .onChange((v: string) => { this.vm.phone = v })

        Divider()
          .color('#F8F4E8')
          .strokeWidth(1)

        // 注册模式才出现的验证码行，配色沿用页面现有的浅黄底 + 橙字
        if (this.vm.modeRegister) {
          Row() {
            TextInput({ placeholder: '验证码' })
              .type(InputType.Number)
              .height(52)
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .padding({ left: 6, right: 6 })
              .placeholderColor('#B5A98D')
              .onChange((v: string) => { this.vm.code = v })

            Button(this.vm.countdown > 0
              ? `${this.vm.countdown}s`
              : (this.vm.isSending ? '发送中…' : '获取验证码'))
              .height(32)
              .borderRadius(16)
              .padding({ left: 12, right: 12 })
              .fontSize(13.0)
              .backgroundColor('#FEF8E3')
              .fontColor(this.vm.countdown > 0 ? '#B5A98D' : '#E4842A')
              .enabled(this.vm.countdown === 0 && !this.vm.isSending)
              .onClick(() => { this.doSendCode() })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Divider()
            .color('#F8F4E8')
            .strokeWidth(1)
        }

        TextInput({ placeholder: this.vm.modeRegister ? '密码（至少 6 位）' : '密码' })
          .type(InputType.Password)
          .height(52)
          .backgroundColor(Color.Transparent)
          .padding({ left: 6, right: 6 })
          .placeholderColor('#B5A98D')
          .onChange((v: string) => { this.vm.password = v })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .borderRadius(20)
      .backgroundColor(Color.White)
      .border({ width: 1, color: '#F2ECD8' })
      .shadow({ radius: 12, color: '#14000000', offsetY: 4 })

      // 主按钮
      Button(this.vm.isLoading
        ? (this.vm.modeRegister ? '注册中…' : '登录中…')
        : (this.vm.modeRegister ? '注 册' : '登 录'))
        .width('100%')
        .height(52)
        .borderRadius(26)
        .backgroundColor('#FBDE71')
        .fontColor('#8A7A50')
        .fontSize(18.0)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20 })
        .enabled(!this.vm.isLoading)           // 请求中禁用，防重复点
        .shadow({ radius: 10, color: '#14000000', offsetY: 4 })
        .onClick(() => { this.doSubmit() })

      // ===== 登录 / 注册切换：只加一行文字，不动品牌区与表单版式 =====
      Row({ space: 4 }) {
        Text(this.vm.modeRegister ? '已有账号？' : '还没有账号？')
          .fontSize(13.5)
          .fontColor('#9A8A6E')

        Text(this.vm.modeRegister ? '去登录' : '立即注册')
          .fontSize(13.5)
          .fontColor('#E4842A')
          .onClick(() => { this.vm.switchMode(!this.vm.modeRegister) })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 12 })

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
        .width(19)
        .height(19)
        .borderRadius(9.5)
        .backgroundColor(this.vm.agreed ? '#E4842A' : '#FFFFFF')
        .border({ width: 1.5, color: this.vm.agreed ? '#E4842A' : '#B5A98D' })
        .justifyContent(FlexAlign.Center)
        .shadow({ radius: 2, color: '#10000000', offsetY: 1 })
        .onClick(() => {
          this.vm.agreed = !this.vm.agreed;
        })

        Text('我已阅读并同意')
          .fontSize(13.0)
          .fontColor('#7A6A52')

        Text('《用户协议》')
          .fontSize(13.0)
          .fontColor('#E4842A')
          .onClick(() => {
            this.toast('协议内容整理中');
          })

        Text('和')
          .fontSize(13.0)
          .fontColor('#9A8A6E')

        Text('《隐私政策》')
          .fontSize(13.0)
          .fontColor('#E4842A')
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
        .fontColor('#B5A98D')
        .margin({ bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .padding({ left: 28, right: 28 })
    .backgroundColor('#FDFDED')
  }
}
