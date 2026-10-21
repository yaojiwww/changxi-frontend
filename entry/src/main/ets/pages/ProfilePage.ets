import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AppConfig } from '../common/AppConfig';
import { TokenStore } from '../common/TokenStore';
import { SessionService } from '../common/SessionService';
import { ProfileModel, ProfileCache, maskPhone, isValidPhone } from '../common/ProfileModel';
import { ProfileApi } from '../api/ProfileApi';
import { UserApi } from '../api/UserApi';
import { CODE_OK } from '../common/Http';

import { AppStorageV2 } from '@kit.ArkUI';
// 个人信息页：头像/昵称/ID/绑定手机号/绑定微信 + 底部退出登录
@Entry
@ComponentV2
struct ProfilePage {
  // 跨页共享模型：修改成功后首页问候语与「我的」页同步刷新
  @Local profile: ProfileModel = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;

  // 昵称编辑弹层
  @Local nicknameEditing: boolean = false;
  @Local nicknameInput: string = '';
  @Local isSavingNickname: boolean = false;

  // 换绑手机号底部面板
  @Local phonePanelVisible: boolean = false;
  @Local newPhone: string = '';
  @Local smsCode: string = '';
  @Local countdown: number = 0;
  @Local isSending: boolean = false;
  @Local isUpdatingPhone: boolean = false;

  // 微信绑定
  @Local isBindingWechat: boolean = false;

  @Local isLoggingOut: boolean = false;

  private countdownTimer: number = -1;

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await AppConfig.load(context);
    await TokenStore.init(context);
    await ProfileCache.load(context);   // 先用本地缓存回显
    this.fetchProfile();                // 再拉接口刷新，失败不覆盖缓存
  }

  aboutToDisappear(): void {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
  }

  // 拉取个人资料。成功才写入共享模型，失败保留原值
  private async fetchProfile(): Promise<void> {
    try {
      const token = await TokenStore.read();
      const res = await ProfileApi.profile(token);
      if (res.code !== CODE_OK || res.data === null) {
        return;
      }
      this.profile.nickname = res.data.nickname;
      this.profile.avatarUri = res.data.avatarUrl;
      this.profile.userId = res.data.userId;
      this.profile.phone = res.data.phone;
      this.profile.wechatBound = res.data.wechatBound;
    } catch (err) {
      // 网络异常：保留缓存数据，不提示打扰
    }
  }

  // ==================== 头像 ====================
  private async pickAvatar(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
        isPhotoTakingSupported: true
      };
      const result = await picker.select(options);
      if (result === undefined || result.photoUris === undefined || result.photoUris.length === 0) {
        return;
      }
      await this.uploadAvatar(result.photoUris[0]);
    } catch (err) {
      // 用户主动取消也会走到这里，静默处理，不打扰
    }
  }

  // 更换头像：优先上传服务端；服务端不可用（未联调/网络异常）时退回本地保存，
  // 保证演示环境也能换头像，接口接通后自动走服务端
  private async uploadAvatar(uri: string): Promise<void> {
    try {
      const token = await TokenStore.read();
      const res = await ProfileApi.updateAvatar(token, uri);
      if (res.code === CODE_OK) {
        await ProfileCache.saveAvatar(uri);
        this.toast('头像已更新');
        return;
      }
    } catch (err) {
      // 网络异常：继续走本地兜底
    }
    await ProfileCache.saveAvatar(uri);
    this.toast('头像已更新（本地保存）');
  }

  // ==================== 昵称 ====================
  private openNicknameEditor(): void {
    this.nicknameInput = this.profile.nickname;
    this.nicknameEditing = true;
  }

  private async saveNickname(): Promise<void> {
    const nick = this.nicknameInput.trim();
    if (nick === '') {
      this.toast('昵称不能为空');
      return;
    }
    if (nick === this.profile.nickname) {
      this.nicknameEditing = false;
      return;
    }
    this.isSavingNickname = true;
    try {
      const token = await TokenStore.read();
      const res = await ProfileApi.updateNickname(token, nick);
      if (res.code !== CODE_OK) {
        this.toast(res.message);
        return;
      }
      await ProfileCache.saveNickname(nick);
      this.nicknameEditing = false;
      this.toast('昵称已保存');
    } catch (err) {
      const e = err as BusinessError;
      this.toast(`网络异常(${e.code})，请检查网络或服务器`);
    } finally {
      this.isSavingNickname = false;
    }
  }

  // ==================== 换绑手机号 ====================
  private openPhonePanel(): void {
    this.newPhone = '';
    this.smsCode = '';
    this.phonePanelVisible = true;
  }

  // 发送验证码：校验手机号 → 调接口 → 成功才启动 60 秒倒计时
  private async sendSmsCode(): Promise<void> {
    if (!isValidPhone(this.newPhone)) {
      this.toast('请输入正确的手机号');
      return;
    }
    if (this.countdown > 0 || this.isSending) {
      return;
    }
    this.isSending = true;
    try {
      const token = await TokenStore.read();
      const res = await ProfileApi.sendSmsCode(token, this.newPhone);
      if (res.code !== CODE_OK) {
        this.toast(res.message);
        return;
      }
      this.startCountdown();
      this.toast('验证码已发送');
    } catch (err) {
      const e = err as BusinessError;
      this.toast(`网络异常(${e.code})，请检查网络或服务器`);
    } finally {
      this.isSending = false;
    }
  }

  private startCountdown(): void {
    this.countdown = 60;
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
    }
    this.countdownTimer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        clearInterval(this.countdownTimer);
        this.countdownTimer = -1;
      }
    }, 1000);
  }

  // 提交换绑：验证码未填或倒计时未结束禁止提交
  private async submitPhoneUpdate(): Promise<void> {
    if (!isValidPhone(this.newPhone)) {
      this.toast('请输入正确的手机号');
      return;
    }
    if (this.smsCode.trim() === '') {
      this.toast('请输入验证码');
      return;
    }
    if (this.countdown > 0) {
      this.toast('请等待倒计时结束再提交');
      return;
    }
    this.isUpdatingPhone = true;
    try {
      const token = await TokenStore.read();
      const res = await ProfileApi.updatePhone(token, this.newPhone, this.smsCode.trim());
      if (res.code !== CODE_OK) {
        this.toast(res.message);
        return;
      }
      this.profile.phone = this.newPhone;
      this.phonePanelVisible = false;
      this.toast('手机号已更新');
    } catch (err) {
      const e = err as BusinessError;
      this.toast(`网络异常(${e.code})，请检查网络或服务器`);
    } finally {
      this.isUpdatingPhone = false;
    }
  }

  // ==================== 微信绑定 ====================
  private async bindWechat(): Promise<void> {
    if (this.profile.wechatBound) {
      this.toast('微信已绑定');
      return;
    }
    if (this.isBindingWechat) {
      return;
    }
    this.isBindingWechat = true;
    try {
      const token = await TokenStore.read();
      const res = await ProfileApi.bindWechat(token);
      if (res.code !== CODE_OK) {
        this.toast(res.message);
        return;
      }
      this.profile.wechatBound = true;
      this.toast('微信绑定成功');
    } catch (err) {
      const e = err as BusinessError;
      this.toast(`网络异常(${e.code})，请检查网络或服务器`);
    } finally {
      this.isBindingWechat = false;
    }
  }

  // ==================== 退出登录 ====================
  private async doLogout(): Promise<void> {
    const resp = await this.getUIContext().getPromptAction().showDialog({
      title: '退出登录',
      message: '确定要退出当前账号吗？',
      buttons: [
        { text: '取消', color: '#9A8A6E' },
        { text: '退出登录', color: '#D9534F', primary: true }
      ]
    });
    if (resp.index !== 1) {
      return;
    }
    this.isLoggingOut = true;
    try {
      const token = await TokenStore.read();
      await UserApi.logout(token);
    } catch (err) {
      // 网络异常也继续本地退出，避免卡在已登录界面
    }
    await SessionService.logout();
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
  }

  // ==================== UI ====================
  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        // 顶部返回栏
        Row() {
          Text('‹')
            .fontSize(34.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#55402F')
            .padding({ left: 16, right: 12, top: 4, bottom: 4 })
            .onClick(() => {
              this.getUIContext().getRouter().back();
            })

          Text('个人信息')
            .fontSize(20.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#55402F')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ right: 34 })
        }
        .width('100%')
        .height(56)
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)
        .border({ width: { bottom: 1 }, color: '#F2ECD8' })

        // 列表区
        Scroll() {
          Column() {
            // 头像
            Row() {
              Text('头像')
                .fontSize(19.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#55402F')
                .layoutWeight(1)

              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(42)
                  .height(42)
                  .borderRadius(21)
                  .backgroundColor('#FEF8E3')

                if (this.profile.avatarUri !== '') {
                  Image(this.profile.avatarUri)
                    .width(42)
                    .height(42)
                    .borderRadius(21)
                    .objectFit(ImageFit.Cover)
                } else {
                  // 这里要替换真实图标（默认头像图片）
                  Text(this.profile.nickname.substring(0, 1))
                    .fontSize(19.0)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#E4842A')
                }
              }
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.pickAvatar();
            })
            Divider().color('#FEF8E3').strokeWidth(1)

            // 昵称
            Row() {
              Text('昵称')
                .fontSize(19.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#55402F')
                .layoutWeight(1)
              Text(this.profile.nickname)
                .fontSize(19.0)
                .fontColor('#9A8A6E')
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.openNicknameEditor();
            })
            Divider().color('#FEF8E3').strokeWidth(1)

            // ID
            Row() {
              Text('ID')
                .fontSize(19.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#55402F')
                .layoutWeight(1)
              Text(this.profile.userId !== '' ? this.profile.userId : '—')
                .fontSize(19.0)
                .fontColor('#9A8A6E')
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            Divider().color('#FEF8E3').strokeWidth(1)

            // 绑定手机号
            Row() {
              Text('绑定手机号')
                .fontSize(19.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#55402F')
                .layoutWeight(1)
              Text(this.profile.phone !== '' ? maskPhone(this.profile.phone) : '未绑定 ')
                .fontSize(19.0)
                .fontColor('#9A8A6E')
              Text('›')
                .fontSize(21.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#B5A98D')
                .margin({ left: 4 })
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.openPhonePanel();
            })
            Divider().color('#FEF8E3').strokeWidth(1)

            // 绑定微信
            Row() {
              Text('绑定微信')
                .fontSize(19.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#55402F')
                .layoutWeight(1)
              Text(this.profile.wechatBound ? '已绑定 ' : '未绑定 ')
                .fontSize(19.0)
                .fontColor('#9A8A6E')
              Text('›')
                .fontSize(21.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#B5A98D')
                .margin({ left: 4 })
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.bindWechat();
            })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .align(Alignment.Top)
        .width('100%')

        // 底部固定退出登录
        Row({ space: 8 }) {
          // 这里要替换真实图标（退出登录图标）
          Text('⟲')
            .fontSize(19.0)
            .fontColor('#55402F')
          Text('退出登录')
            .fontSize(19.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#55402F')
        }
        .width('100%')
        .height(52)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .border({ width: { top: 1 }, color: '#F2ECD8' })
        .onClick(() => {
          this.doLogout();
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')

      // ============ 昵称编辑弹层 ============
      if (this.nicknameEditing) {
        Column() {
          Column({ space: 16 }) {
            Text('修改昵称')
              .fontSize(19.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#55402F')

            TextInput({ text: $$this.nicknameInput, placeholder: '请输入昵称' })
              .height(48)
              .borderRadius(12)
              .backgroundColor('#FFFFFF')
              .padding({ left: 14, right: 14 })

            Row({ space: 12 }) {
              Button('取消')
                .layoutWeight(1)
                .height(44)
                .borderRadius(22)
                .backgroundColor('#F2ECD8')
                .fontColor('#9A8A6E')
                .fontSize(19.0)
                .onClick(() => {
                  this.nicknameEditing = false;
                })

              Button(this.isSavingNickname ? '保存中…' : '保存')
                .layoutWeight(1)
                .height(44)
                .borderRadius(22)
                .backgroundColor('#FBDE71')
                .fontColor('#8A7A50')
                .fontSize(19.0)
                .enabled(!this.isSavingNickname)
                .onClick(() => {
                  this.saveNickname();
                })
            }
            .width('100%')
          }
          .width('80%')
          .padding(20)
          .borderRadius(18)
          .backgroundColor(Color.White)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#80000000')
        .onClick(() => {
          this.nicknameEditing = false;
        })
      }

      // ============ 换绑手机号底部面板 ============
      if (this.phonePanelVisible) {
        Column() {
          Column({ space: 16 }) {
            Text('更换绑定手机号')
              .fontSize(19.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#55402F')
              .alignSelf(ItemAlign.Start)

            TextInput({ text: $$this.newPhone, placeholder: '请输入新手机号' })
              .type(InputType.PhoneNumber)
              .height(48)
              .borderRadius(12)
              .backgroundColor('#FFFFFF')
              .padding({ left: 14, right: 14 })

            Row({ space: 10 }) {
              TextInput({ text: $$this.smsCode, placeholder: '请输入验证码' })
                .layoutWeight(1)
                .height(48)
                .borderRadius(12)
                .backgroundColor('#FFFFFF')
                .padding({ left: 14, right: 14 })

              Button(this.countdown > 0 ? `${this.countdown}s` : (this.isSending ? '发送中…' : '获取验证码'))
                .width(110)
                .height(48)
                .borderRadius(12)
                .backgroundColor(this.countdown > 0 ? '#FEF8E3' : '#FEF8E3')
                .fontColor(this.countdown > 0 ? '#9A8A6E' : '#E4842A')
                .fontSize(19.0)
                .enabled(this.countdown === 0 && !this.isSending)
                .onClick(() => {
                  this.sendSmsCode();
                })
            }
            .width('100%')

            Row({ space: 12 }) {
              Button('取消')
                .layoutWeight(1)
                .height(44)
                .borderRadius(22)
                .backgroundColor('#F2ECD8')
                .fontColor('#9A8A6E')
                .fontSize(19.0)
                .onClick(() => {
                  this.phonePanelVisible = false;
                })

              Button(this.isUpdatingPhone ? '提交中…' : '提交')
                .layoutWeight(1)
                .height(44)
                .borderRadius(22)
                .backgroundColor('#FBDE71')
                .fontColor('#8A7A50')
                .fontSize(19.0)
                .enabled(!this.isUpdatingPhone)
                .onClick(() => {
                  this.submitPhoneUpdate();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 24, bottom: 32 })
          .borderRadius({ topLeft: 20, topRight: 20 })
          .backgroundColor(Color.White)
          .onClick(() => {
            // 阻止点击穿透到底层遮罩
          })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .backgroundColor('#80000000')
        .onClick(() => {
          this.phonePanelVisible = false;
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }
}
