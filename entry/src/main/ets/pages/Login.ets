import { BusinessError } from '@kit.BasicServicesKit';
import { AppConfig } from '../common/AppConfig';
import { TokenStore } from '../common/TokenStore';
import { AuthApi } from '../api/AuthApi';
import { CODE_OK } from '../common/Http';

@Entry
@ComponentV2
struct Login {
  @Local phone: string = '';
  @Local password: string = '';
  @Local isLoading: boolean = false;

  // 页面出现前，先把配置和本地存储准备好，避免第一次点登录时还没就绪
  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await AppConfig.load(context);
    await TokenStore.init(context);
  }

  // 登录：调后端 → 存 token → 进首页
  private async doLogin(): Promise<void> {
    if (this.phone === '' || this.password === '') {
      this.toast('手机号或密码不能为空');
      return;
    }
    this.isLoading = true;
    try {
      // const res = await AuthApi.login(this.phone, this.password);
      // if (res.code !== CODE_OK || res.data === null) {
      //   this.toast(res.message);
      //   return;
      // }
      // await TokenStore.save(res.data);
      
      // 硬编码验证
      if (this.phone === '13200000000' && this.password === '123456') {
        this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });   // 登录成功 → 进首页
      } else {
        this.toast('手机号或密码错误');
      }
    } catch (err) {
      // 走到这里说明不是业务错误，而是网络层问题：超时、连不上服务器、断网
      const e = err as BusinessError;
      this.toast(`网络异常(${e.code})，请检查网络或服务器`);
    } finally {
      this.isLoading = false;
    }
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
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
