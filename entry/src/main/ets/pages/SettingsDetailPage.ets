// 路由参数：只传标题，正文按标题取内置占位内容
export interface SettingsDetailParams {
  title: string;
}

// 各详情页的占位正文。接后台后改为按 title 拉取或 WebView 加载真实内容
function detailContent(title: string): string {
  if (title === '个人信息') {
    return '昵称：林小满\n\n手机号：132****0000\n\n头像、昵称等个人信息可在资料编辑页修改。\n\n（当前为占位内容，接入后台后展示真实数据）';
  }
  if (title === '考试时间') {
    return '可在此设置你的考试日期，设置后首页与练习模块将按倒计时提醒备考。\n\n（当前为占位内容，日期选择器接入后可直接编辑）';
  }
  if (title === '备案信息') {
    return 'ICP 备案号：待填写\n\n公安备案号：待填写\n\n（当前为占位内容，备案通过后补充）';
  }
  return `《${title}》\n\n第一条 本页面当前为占位内容，正式文本由后台配置下发后自动加载。\n\n第二条 我们重视你的个人信息与隐私保护，将按照法律法规规定处理你的个人信息。\n\n第三条 如对本内容有任何疑问，可通过「更多设置」中的渠道联系我们。`;
}

// 协议类 / 清单类 / 个人信息等通用详情页：移动端白底正文 + 顶部返回栏
@Entry
@ComponentV2
struct SettingsDetail {
  @Local pageTitle: string = '';

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as SettingsDetailParams | undefined;
    if (params !== undefined && params.title !== undefined) {
      this.pageTitle = params.title;
    }
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  build() {
    Column() {
      // 顶部返回栏
      Row() {
        Text('‹')
          .fontSize(34.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A202C')
          .padding({ left: 16, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.goBack();
          })

        Text(this.pageTitle)
          .fontSize(18.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F1F4F9' })

      // 正文
      Scroll() {
        Column() {
          Text(detailContent(this.pageTitle))
            .fontSize(16.0)
            .fontColor('#3A4552')
            .lineHeight(26)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 32 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
