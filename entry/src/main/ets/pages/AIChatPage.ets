@ComponentV2
export struct AIView {
  build() {
    Column() {
      // 顶栏
      Row() {
        Text('≡').fontSize(24).fontColor('#333')
        Blank()
        Text('练题狗AI助教').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        Text('💬+').fontSize(20).fontColor('#333')
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // 中间内容
      Column() {
        Text('🤖')
          .fontSize(80)
          .margin({ bottom: 24 })
        
        Text('嗨，我是你的考试AI助教')
          .fontSize(16)
          .fontColor('#333')
          .margin({ bottom: 8 })
        
        Text('能为你导航学习、解答疑问和考情分析')
          .fontSize(16)
          .fontColor('#333')
          .margin({ bottom: 8 })
        
        Text('有什么需要帮助的吗？')
          .fontSize(16)
          .fontColor('#333')
          .margin({ bottom: 16 })
        
        Text('Powered by Deepseek·R1')
          .fontSize(12)
          .fontColor('#999')
          .margin({ bottom: 32 })
          
        Divider().width('80%').strokeWidth(1).color('#EEEEEE')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Color.White)

      // 底部输入区
      Column() {
        Row({ space: 12 }) {
          Text('R1·深度思考').fontSize(12).fontColor('#666').backgroundColor('#F5F5F5').padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(14)
          Text('🌐 联网').fontSize(12).fontColor('#666').backgroundColor('#F5F5F5').padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(14)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        
        Row() {
          TextInput({ placeholder: '请输入你想问的问题?' })
            .layoutWeight(1)
            .height(40)
            .backgroundColor('#F5F5F5')
            .borderRadius(20)
            .padding({ left: 16 })
            .fontSize(14)
          
          Button('提问')
            .width(72)
            .height(40)
            .backgroundColor('#3B82F6')
            .margin({ left: 12 })
            .borderRadius(20)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .shadow({ radius: 10, color: '#0A000000', offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
