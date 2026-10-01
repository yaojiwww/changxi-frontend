import { router } from '@kit.ArkUI';

@Entry
@ComponentV2
struct Login {
  @Local phone: string = '';
  @Local password: string = '';
  @Local isLoading: boolean = false;

  // ★ 后端接入点：以后只改这一个方法，UI 一行不用动
  private async doLogin(): Promise<void> {
    this.isLoading = true;
    // TODO: 后端好了，这里换成真实请求，例如：
    //   const res = await LoginApi.login(this.phone, this.password);
    //   if (res.code !== 0) { 提示错误; return; }
    await new Promise<void>((resolve) => setTimeout(() => resolve(), 800)); // 假装网络耗时
    this.isLoading = false;
    router.replaceUrl({ url: 'pages/Index' });   // 登录成功 → 进首页
  }

  build() {
    Column() {
      // 标题区
      Column({ space: 8 }) {
        Text('畅息').fontSize(36).fontWeight(FontWeight.Medium).fontColor('#1F1F1F')
        Text('婴幼儿救护助手').fontSize(14).fontColor('#9AA0A6')
      }
      .margin({ bottom: 48 })

      // 输入区
      Column({ space: 16 }) {
        TextInput({ placeholder: '手机号' })
          .type(InputType.PhoneNumber)
          .height(56).borderRadius(28)
          .backgroundColor(Color.White)
          .padding({ left: 20, right: 20 })
          .onChange((v: string) => { this.phone = v })

        TextInput({ placeholder: '密码' })
          .type(InputType.Password)
          .height(56).borderRadius(28)
          .backgroundColor(Color.White)
          .padding({ left: 20, right: 20 })
          .onChange((v: string) => { this.password = v })
      }
      .width('100%')

      // 主按钮
      Button(this.isLoading ? '登录中…' : '登录')
        .width('100%').height(52).borderRadius(26)
        .backgroundColor('#1A73E8')            // ★ Gemini 同款蓝，你也可以换成别的
        .fontColor(Color.White).fontSize(17)
        .margin({ top: 24 })
        .enabled(!this.isLoading)              // 请求中禁用，防重复点
        .onClick(() => { this.doLogin() })
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .justifyContent(FlexAlign.Center)          // 整体垂直居中，大留白 = Gemini 感
    .padding({ left: 24, right: 24 })
    .linearGradient({                          // 和 Index 完全一样的背景
      angle: 180,
      colors: [['#FFFFFF', 0.0], ['#DCE9FB', 1.0]]
    })
  }
}
