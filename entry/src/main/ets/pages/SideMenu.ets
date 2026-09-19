import { router } from '@kit.ArkUI';

@Component
export struct SideMenu {
 onClose: () => void = () => {};

  build() {
    Column() {
      // --- 1. 顶部：搜索框和加号 ---
      Row() {
        // 搜索框
        Row() {
          // 如果你有放大镜图标，也可以替换这里的 Text
          Text('点击搜索...').fontSize(16).fontColor('#999')
        }
        .width('90%')
        .height(35)
        .borderRadius(20)
        .backgroundColor('#F2F2F2') // 稍微调整了背景色，看起来更柔和
        .padding({ left: 15 })
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)

        // 右上角加号 (+) 按钮
        Button() {
          // 将 'ic_add.png' 替换为你项目中实际的加号图标文件名
          Image($r('app.media.jiah'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
        }
        .width(35)
        .height(35)
        .borderRadius(20)
        .backgroundColor('#FFFFFF') // 和搜索框保持一致的背景色
        .onClick(() => {
          console.log("点击了加号按钮")
        })
      }
      .width('100%')
      .padding(15)
      .justifyContent(FlexAlign.SpaceBetween)

      // --- 2. 中部：列表区域 ---

      Scroll() {
        Column({ space: 0 }) {
          Text('错题集')
            .fontSize(18)
            .fontColor('#333')
            .padding({ left: 15, right: 15, top: 20, bottom: 20 })
          Divider().color('#EEEEEE')

          Text('聊天记录')
            .fontSize(18)
            .fontColor('#333')
            .padding({ left: 15, right: 15, top: 20, bottom: 20 })
          Divider().color('#EEEEEE')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start) // 关键：让 Column 内所有子组件靠左对齐
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F8F8F8')
      .align(Alignment.Top) // 关键：让 Scroll 的内容从顶部开始排列，而不是居中

      // --- 3. 底部：功能图标 ---
      Row() {
        // 左下角：联系人/个人中心图标
        Button() {
          // 将 'ic_profile.png' 替换为你项目中实际的个人图标文件名
          Image($r('app.media.toux'))
            .width(32)
            .height(32)
            .objectFit(ImageFit.Contain)
        }
        .width(50)
        .height(50)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          console.log("点击了个人主页")
        })
        .margin({ left: 15 })

        Blank() // 占位，把右边的设置按钮挤到最右侧

        // 右下角：设置图标
        Button() {
          // 将 'ic_settings.png' 替换为你项目中实际的设置图标文件名
          Image($r('app.media.shez'))
            .width(28)
            .height(28)
            .objectFit(ImageFit.Contain)
        }
        .width(50)
        .height(50)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          console.log("点击了设置")
        })
        .margin({ right: 15 })
      }
      .width('100%')
      .padding({ top: 10, bottom: 15 })
      .backgroundColor(Color.White) // 底部加一个白色背景，防止透明
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}