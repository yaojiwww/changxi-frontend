import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AIPracticeHistoryStore, AIPracticeRecord } from '../common/AIPracticeHistoryStore';
import { SafeArea } from '../common/SafeArea';

// 场景选项：共 6 类保育实操场景（顺序与 SCENE_ICONS / DEMO_RESULTS 一一对应）
const SCENES: string[] = ['进餐环节', '午睡环境', '玩具消毒', '盥洗如厕', '户外活动', '晨午健康检查'];

// 场景图标：已改为 media 目录下的图片资源（scene_meal/sleep/toy/wash/outdoor/health），见组件内 sceneIcons

// 一条改进建议
interface AdviceItem {
  title: string;
  desc: string;
}

// 一个场景的分析结果（演示版内置，正式版由后端 AI 返回）
interface SceneResult {
  name: string;
  score: number;        // 达标度 0-100
  summary: string;
  advice: AdviceItem[];
  basis: string[];      // 判断依据
}

const DEMO_RESULTS: SceneResult[] = [
  {
    name: '进餐环节',
    score: 88,
    summary: '整体符合规范，有 3 处可优化。按建议调整后，进餐环节的安全性与规范性会更好。',
    advice: [
      { title: '餐具间距偏近', desc: '汤碗与饭碗建议间隔 10cm 以上，避免端送时洒溅烫伤。' },
      { title: '保育师站位可优化', desc: '建议站在幼儿侧后方，能同时观察到两端幼儿的进餐情况。' },
      { title: '进餐时长提示', desc: '单餐建议控制在 20–30 分钟，不催促、不训斥，允许幼儿细嚼慢咽。' }
    ],
    basis: ['《托儿所、幼儿园卫生保健工作规范》进餐管理', '《保育师国家职业技能标准》四级 · 生活照料']
  },
  {
    name: '午睡环境',
    score: 82,
    summary: '睡眠环境基本达标，寝具与巡视环节还有 3 处细节可以加强。',
    advice: [
      { title: '床铺间距不足', desc: '幼儿床间距建议保持 50cm 以上，方便巡视与通风。' },
      { title: '加强睡前通风', desc: '睡前 10–15 分钟开窗通风，睡时避免对流风直吹幼儿。' },
      { title: '巡视记录要完整', desc: '每 10 分钟巡视一次，关注睡姿与被褥覆盖，并做好记录。' }
    ],
    basis: ['《托儿所、幼儿园卫生保健工作规范》睡眠管理', '《保育师国家职业技能标准》五级 · 生活照料']
  },
  {
    name: '玩具消毒',
    score: 76,
    summary: '消毒流程有章可循，但配比与冲洗环节存在风险点，需优先整改。',
    advice: [
      { title: '消毒液配比偏高', desc: '含氯消毒剂按 250–500mg/L 配制，浓度过高会残留刺激皮肤。' },
      { title: '浸泡后须冲洗', desc: '浸泡 30 分钟后应用清水冲洗干净并晾干，再交幼儿使用。' },
      { title: '登记消毒记录', desc: '每次消毒需记录时间、浓度与操作人，便于追溯与检查。' }
    ],
    basis: ['《托儿所、幼儿园卫生保健工作规范》消毒管理', '《保育师国家职业技能标准》五级 · 环境创设']
  },
  {
    name: '盥洗如厕',
    score: 90,
    summary: '盥洗组织有序、地面干爽，仅需在提醒频次上做小幅优化。',
    advice: [
      { title: '提醒频次可加密', desc: '每隔 1.5–2 小时提醒如厕一次，避免幼儿憋便憋尿。' },
      { title: '七步洗手要到位', desc: '洗手按七步法执行，保育师应在旁示范并逐个检查。' }
    ],
    basis: ['《托儿所、幼儿园卫生保健工作规范》盥洗如厕管理', '《保育师国家职业技能标准》五级 · 生活照料']
  },
  {
    name: '户外活动',
    score: 85,
    summary: '活动组织与场地检查到位，活动量与安全防护还有 3 处可以加强。',
    advice: [
      { title: '活动前先查场地', desc: '检查场地有无积水、碎石与尖锐物，器械牢固度与安全间距需逐项确认。' },
      { title: '运动量要适中', desc: '幼儿户外活动每天不少于 2 小时，其中体育活动不少于 1 小时，注意动静交替。' },
      { title: '及时补水与防护', desc: '活动前后提醒幼儿饮水，夏季避开正午强光，出汗后及时擦干并更换衣物。' }
    ],
    basis: ['《托儿所、幼儿园卫生保健工作规范》体格锻炼', '《保育师国家职业技能标准》四级 · 健康管理']
  },
  {
    name: '晨午健康检查',
    score: 87,
    summary: '晨午检流程完整，观察与登记环节还可再细化 3 处。',
    advice: [
      { title: '按「一摸二看三问四查」执行', desc: '摸额头与颈部是否发热，看咽喉与皮肤，问饮食睡眠，查有无携带危险物品。' },
      { title: '发现异常立即上报', desc: '体温异常或出现皮疹、呕吐等症状，先隔离观察并通知保健医与家长。' },
      { title: '检查记录要留痕', desc: '晨午检结果逐日登记，异常情况记录处置过程，便于追溯与统计。' }
    ],
    basis: ['《托儿所、幼儿园卫生保健工作规范》健康检查', '《保育师国家职业技能标准》四级 · 健康管理']
  }
];

// 统一配色
const PRIMARY: string = '#FBDE71';
const ACCENT: string = '#E4842A';
const TEXT_MAIN: string = '#55402F';
const TEXT_SUB: string = '#9A8A6E';
const TEXT_WEAK: string = '#B5A98D';
const CARD_BORDER: string = '#F2ECD8';

@Entry
@ComponentV2
struct AIPractice {
  @Local step: number = 0;            // 0 上传 / 1 识别中 / 2 结果
  @Local sceneIndex: number = 0;      // 选中的场景
  // 场景图标资源（与顶层 SCENES 同序；SVG 为彩色矢量，PNG 为透明底小黄鸭）
  private sceneIcons: Resource[] = [
    $r('app.media.scene_meal'),
    $r('app.media.scene_sleep'),
    $r('app.media.scene_toy'),
    $r('app.media.scene_wash'),
    $r('app.media.scene_outdoor'),
    $r('app.media.scene_health')
  ];
  @Local imageUri: string = '';       // 相册/拍摄选到的照片 URI（空串=未选）
  @Local useDemo: boolean = false;    // 是否使用内置示例照片（相册为空时的兜底）
  @Local pickHint: string = '';       // 选图失败/空白时给出的一行提示
  @Local stepDone: number = 0;        // 识别进度：0-3
  private timerIds: number[] = [];

  // 历史记录半屏浮窗
  @Local historyOpen: boolean = false;
  @Local historyItems: AIPracticeRecord[] = [];

  async aboutToAppear(): Promise<void> {
    // 不依赖入口页先初始化：进来就按当前账号把历史读出来
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      await AIPracticeHistoryStore.init(context);
    }
    this.historyItems = AIPracticeHistoryStore.getAll();
  }

  aboutToDisappear(): void {
    for (const t of this.timerIds) {
      clearTimeout(t);
    }
    this.timerIds = [];
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2200 });
  }

  // 是否已经有一张可用于分析的照片
  private hasPhoto(): boolean {
    return this.useDemo || this.imageUri !== '';
  }

  // 从相册选一张照片（选择器内也可直接拍照）
  private async pickImage(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
        isPhotoTakingSupported: true
      };
      const result = await picker.select(options);
      if (result !== undefined && result.photoUris !== undefined && result.photoUris.length > 0) {
        this.imageUri = result.photoUris[0];
        this.useDemo = false;
        this.pickHint = '';
      } else {
        this.pickHint = '没有选到照片，可以先用下方的「用示例照片体验」。';
      }
    } catch (err) {
      // 用户主动取消也会走到这里，所以只给一行提示，不弹窗打扰
      const e = err as BusinessError;
      const code = (e !== undefined && e.code !== undefined) ? e.code : 0;
      this.pickHint = code !== 0
        ? `未能从相册取到照片（错误码 ${code}），可先用下方的「用示例照片体验」。`
        : '未能从相册取到照片，可先用下方的「用示例照片体验」。';
    }
  }

  // 兜底：使用内置示例照片，保证图库为空或模拟器无照片时也能走完整流程
  private useDemoPhoto(): void {
    this.useDemo = true;
    this.imageUri = '';
    this.pickHint = '';
    // 示例照片是晨午健康检查（一摸额头/看手心 + 记录板），自动切到对应场景
    const idx = SCENES.indexOf('晨午健康检查');
    if (idx >= 0) {
      this.sceneIndex = idx;
    }
    this.toast('已载入示例照片');
  }

  // 开始分析：三步演示动画，约 3 秒后出结果
  private startAnalyze(): void {
    if (!this.hasPhoto()) {
      this.toast('请先上传一张保育现场照片');
      return;
    }
    // 快照本次分析的入参：3 秒后归档时用，期间页面状态可能被「历史回看」改动
    const snapScene: number = this.sceneIndex;
    const snapUri: string = this.useDemo ? '' : this.imageUri;
    const snapDemo: boolean = this.useDemo;
    this.step = 1;
    this.stepDone = 0;
    this.timerIds.push(setTimeout((): void => {
      this.stepDone = 1;
    }, 800));
    this.timerIds.push(setTimeout((): void => {
      this.stepDone = 2;
    }, 1700));
    this.timerIds.push(setTimeout((): void => {
      this.stepDone = 3;
      this.step = 2;
      // 分析完成即归档：只要用照片跑过一次功能，历史里就有记录
      this.saveHistory(snapScene, snapUri, snapDemo);
    }, 3000));
  }

  // 归档本次分析
  private async saveHistory(sceneIndex: number, imageUri: string, useDemo: boolean): Promise<void> {
    await AIPracticeHistoryStore.add(
      sceneIndex,
      SCENES[sceneIndex],
      imageUri,
      useDemo,
      DEMO_RESULTS[sceneIndex].score
    );
  }

  // 打开历史：每次打开都重读，换号后不会看到上一个账号的记录
  private async openHistory(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      await AIPracticeHistoryStore.init(context);
    }
    this.historyItems = AIPracticeHistoryStore.getAll();
    this.historyOpen = true;
  }

  // 点历史条目：还原当时的照片与场景，直接进结果页（不重复分析、不再记一条）
  private openRecord(r: AIPracticeRecord): void {
    this.historyOpen = false;
    let idx: number = r.sceneIndex;
    if (idx < 0 || idx >= SCENES.length) {
      // 场景常量调整过时按名字兜底，避免越界
      idx = SCENES.indexOf(r.sceneName);
      if (idx < 0) {
        idx = 0;
      }
    }
    this.sceneIndex = idx;
    this.imageUri = r.imageUri;
    this.useDemo = r.useDemo;
    this.stepDone = 3;
    this.step = 2;
  }

  // 回到上传页
  private reset(): void {
    this.step = 0;
    this.stepDone = 0;
    this.imageUri = '';
    this.useDemo = false;
    this.pickHint = '';
  }

  // 照片缩略图：兼容「相册选到的图片」与「内置示例照片」
  @Builder
  PhotoThumb(h: number, radius: number) {
    if (this.useDemo) {
      Image($r('app.media.demo_scene'))
        .width('100%')
        .height(h)
        .borderRadius(radius)
        .objectFit(ImageFit.Cover)
    } else {
      Image(this.imageUri)
        .width('100%')
        .height(h)
        .borderRadius(radius)
        .objectFit(ImageFit.Cover)
    }
  }

  // 当前结果
  private result(): SceneResult {
    return DEMO_RESULTS[this.sceneIndex];
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.TopBar()

        if (this.step === 0) {
          this.UploadView()
        } else if (this.step === 1) {
          this.AnalyzingView()
        } else {
          this.ResultView()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FDFDED')

      // 历史记录半屏浮窗（叠在页面之上）
      if (this.historyOpen) {
        this.HistorySheet()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 顶部返回栏 ====================
  @Builder
  TopBar() {
    Row() {
      Text('‹')
        .fontSize(34.0)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_MAIN)
        .padding({ left: 16, right: 12, top: 4, bottom: 4 })
        .onClick(() => {
          this.getUIContext().getRouter().back();
        })

      Text(this.step === 2 ? 'AI实操分析结果' : 'AI实操')
        .fontSize(18.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
        .layoutWeight(1)

      Text('历史')
        .fontSize(13.5)
        .fontColor('#9A8A6E')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(14)
        .backgroundColor(Color.White)
        .border({ width: 1, color: '#FEF8E3' })
        .margin({ right: 16 })
        .onClick(() => {
          this.openHistory();
        })
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: '#F2ECD8' })
  }

  // ==================== 场景选择卡 ====================
  // 6 类知识点两列网格：选中态蓝框浅蓝底、图标底色加深，避免一行胶囊拥挤溢出
  @Builder
  ScenePicker() {
    Column() {
      Row() {
        Text('选择知识点')
          .fontSize(16.5)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)

        Blank()

        Text(`共 ${SCENES.length} 类`)
          .fontSize(13.0)
          .fontColor(TEXT_WEAK)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(SCENES, (s: string, i: number) => {
          Row({ space: 8 }) {
            Stack({ alignContent: Alignment.Center }) {
              Column()
                .width(34)
                .height(34)
                .borderRadius(11)
                .backgroundColor('#FEF8E3')

              Image(this.sceneIcons[i])
                .width(21)
                .height(21)
                .objectFit(ImageFit.Contain)
            }

            Text(s)
              .fontSize(14.5)
              .fontWeight(this.sceneIndex === i ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.sceneIndex === i ? ACCENT : '#55402F')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('48.5%')
          .padding({ left: 10, right: 8, top: 9, bottom: 9 })
          .borderRadius(12)
          .backgroundColor(this.sceneIndex === i ? '#FEF8E3' : Color.White)
          .border({
            width: this.sceneIndex === i ? 1.5 : 1,
            color: this.sceneIndex === i ? PRIMARY : '#FEF8E3'
          })
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 10 })
          .onClick(() => {
            this.sceneIndex = i;
          })
        }, (s: string) => s)
      }
      .width('100%')
    }
    .width('100%')
    .padding(15)
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: CARD_BORDER })
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 16 })
  }

  // ==================== 上传视图 ====================
  @Builder
  UploadView() {
    Column() {
      Scroll() {
        Column() {
          // 顶部说明卡
          Column() {
            Text('拍下保育现场，AI 帮你判断')
              .fontSize(18.5)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_MAIN)
              .width('100%')

            Text('按《托儿所、幼儿园卫生保健工作规范》检查场景是否达标，并给出可执行的改进建议。')
              .fontSize(14.5)
              .fontColor(TEXT_SUB)
              .lineHeight(21)
              .width('100%')
              .margin({ top: 8 })
          }
          .width('100%')
          .padding(15)
          .borderRadius(16)
          .backgroundColor('#FEF8E3')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 12 })

          // 场景选择卡：6 类知识点两列网格
          this.ScenePicker()

          // 上传框（虚线样式用浅蓝描边近似）
          Column({ space: 6 }) {
            if (!this.hasPhoto()) {
              Stack({ alignContent: Alignment.Center }) {
                Column()
                  .width(62)
                  .height(62)
                  .borderRadius(19)
                  .backgroundColor('#FEF8E3')

                Text('📷')
                  .fontSize(29.0)
              }
              .margin({ bottom: 9 })

              Text('点击上传照片')
                .fontSize(17.5)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)

              Text('从相册选择，或直接拍摄一张')
                .fontSize(14.0)
                .fontColor(TEXT_SUB)
            } else {
              this.PhotoThumb(190, 12)

              Text(this.useDemo ? '示例照片 · 点击可换成自己的照片' : '已选照片 · 点击可重新选择')
                .fontSize(14.0)
                .fontColor(TEXT_SUB)
                .margin({ top: 7 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 28, bottom: 28 })
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1.5, color: '#FEF8E3', radius: 18 })
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 10 })
          .onClick(() => {
            this.pickImage();
          })

          // 取图失败/图库为空时的一行提示
          if (this.pickHint !== '') {
            Row({ space: 8 }) {
              Text('!')
                .fontSize(13.5)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E4842A')
                .width(19)
                .height(19)
                .borderRadius(10)
                .backgroundColor('#FFFFFF')
                .textAlign(TextAlign.Center)
              Text(this.pickHint)
                .fontSize(14.0)
                .fontColor('#E4842A')
                .lineHeight(20)
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .borderRadius(12)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#FEF8E3' })
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 10 })
          }

          // 兜底入口：模拟器图库为空时也能体验完整流程
          if (!this.hasPhoto()) {
            Text('没有合适的照片？用示例照片体验 →')
              .fontSize(14.5)
              .fontWeight(FontWeight.Medium)
              .fontColor(ACCENT)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 4, bottom: 10 })
              .onClick(() => {
                this.useDemoPhoto();
              })
          }

          Text('建议在光线充足处拍摄，画面包含完整的操作区域')
            .fontSize(13.5)
            .fontColor(TEXT_WEAK)
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .width('100%')

      // 底部开始按钮
      Row() {
        Text('开始 AI 分析')
          .fontSize(17.5)
          .fontWeight(FontWeight.Bold)
          .fontColor('#8A7A50')
          .width('100%')
          .height(48)
          .textAlign(TextAlign.Center)
          .borderRadius(24)
          .backgroundColor(this.hasPhoto() ? PRIMARY : '#FEF8E3')
          .shadow(this.hasPhoto() ?
            { radius: 10, color: '#14000000', offsetY: 4 } :
            { radius: 0, color: Color.Transparent, offsetY: 0 })
          .onClick(() => {
            this.startAnalyze();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 16 + SafeArea.bottomVp })
      .margin({bottom:5})
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#F2ECD8' })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 识别中视图 ====================
  @Builder
  AnalyzingView() {
    Column() {
      Scroll() {
        Column() {
          // 照片预览卡
          Stack({ alignContent: Alignment.TopStart }) {
            this.PhotoThumb(220, 16)

            Row() {
              Text(SCENES[this.sceneIndex])
                .fontSize(12.0)
                .fontColor(Color.White)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(10)
                .backgroundColor('#E4842A')
            }
            .margin(10)

            Row() {
              Text('AI 识别中')
                .fontSize(12.0)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(10)
                .backgroundColor('#E4842A')
            }
            .justifyContent(FlexAlign.End)
            .width('100%')
            .padding({ left: 10, right: 10 })
            .margin({ top: 10 })
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 分析步骤卡
          Column({ space: 4 }) {
            this.StepRow('识别保育场景', this.stepDone >= 1 ? '完成' : '进行中', this.stepDone >= 1)
            Divider().color('#F2ECD8').margin({ left: 42 })
            this.StepRow('匹配保育规范', this.stepDone >= 2 ? '已比对 12 项' : '等待中', this.stepDone >= 2)
            Divider().color('#F2ECD8').margin({ left: 42 })
            this.StepRow('生成改进建议', this.stepDone >= 3 ? '完成' : '进行中', this.stepDone >= 3)
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor(Color.White)
          .border({ width: 1, color: CARD_BORDER })
          .alignItems(HorizontalAlign.Start)

          Text('AI 正在分析，约需 3 秒…')
            .fontSize(13.0)
            .fontColor(TEXT_WEAK)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  // 分析步骤行
  @Builder
  StepRow(title: string, status: string, done: boolean) {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(26)
          .height(26)
          .borderRadius(13)
          .backgroundColor(done ? '#F0F6EC' : '#FEF8E3')

        Text(done ? '✓' : '·')
          .fontSize(15.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(done ? '#2E9E63' : ACCENT)
      }
      .margin({ right: 12 })

      Text(title)
        .fontSize(16.5)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
        .layoutWeight(1)

      Text(status)
        .fontSize(14.0)
        .fontColor(done ? '#2E9E63' : TEXT_WEAK)
    }
    .width('100%')
    .padding({ top: 9, bottom: 9 })
    .alignItems(VerticalAlign.Center)
  }

  // ==================== 结果视图 ====================
  @Builder
  ResultView() {
    Column() {
      Scroll() {
        Column() {
          // 达标度总览卡（蓝色渐变）
          Row() {
            Column({ space: 8 }) {
              Text('AI 分析完成')
                .fontSize(12.0)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8A7A50')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(10)
                .backgroundColor('#4DFFFFFF')

              Text(this.result().name)
                .fontSize(23.0)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8A7A50')

              Text(this.result().summary)
                .fontSize(14.5)
                .fontColor('#55402F')
                .lineHeight(21)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            // 达标度圆环
            Stack({ alignContent: Alignment.Center }) {
              Progress({ value: this.result().score, total: 100, type: ProgressType.Ring })
                .width(78)
                .height(78)
                .color('#8A7A50')
                .backgroundColor('#4DFFFFFF')
                .style({ strokeWidth: 7 })

              Column({ space: 1 }) {
                Text(this.result().score.toString())
                  .fontSize(23.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#8A7A50')
                Text('达标度')
                  .fontSize(11.0)
                  .fontColor('#55402F')
              }
              .alignItems(HorizontalAlign.Center)
            }
            .margin({ left: 10 })
          }
          .width('100%')
          .padding(18)
          .borderRadius(18)
          .backgroundColor('#FEF8E3')
          .shadow({ radius: 12, color: '#14000000', offsetY: 6 })
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 14 })

          // 改进建议卡
          Column() {
            Row({ space: 7 }) {
              Text('✦')
                .fontSize(15.0)
                .fontColor(ACCENT)
              Text('改进建议')
                .fontSize(17.5)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
            }
            .width('100%')
            .margin({ bottom: 13 })

            ForEach(this.result().advice, (a: AdviceItem, i: number) => {
              Row() {
                Text((i + 1).toString())
                  .fontSize(13.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ACCENT)
                  .width(21)
                  .height(21)
                  .borderRadius(11)
                  .backgroundColor('#FEF8E3')
                  .textAlign(TextAlign.Center)
                  .margin({ right: 10, top: 2 })

                Column({ space: 4 }) {
                  Text(a.title)
                    .fontSize(16.0)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(TEXT_MAIN)
                  Text(a.desc)
                    .fontSize(14.5)
                    .fontColor('#9A8A6E')
                    .lineHeight(21)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
              .margin({ bottom: 12 })
            }, (a: AdviceItem) => a.title)
          }
          .width('100%')
          .padding(15)
          .borderRadius(16)
          .backgroundColor(Color.White)
          .border({ width: 1, color: CARD_BORDER })
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 12 })

          // 判断依据卡
          Column() {
            Row({ space: 7 }) {
              Text('✦')
                .fontSize(15.0)
                .fontColor(PRIMARY)
              Text('判断依据')
                .fontSize(17.5)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
            }
            .width('100%')
            .margin({ bottom: 13 })

            ForEach(this.result().basis, (b: string) => {
              Row({ space: 8 }) {
                Text('✓')
                  .fontSize(14.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2E9E63')
                Text(b)
                  .fontSize(14.5)
                  .fontColor('#55402F')
                  .lineHeight(21)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .borderRadius(11)
              .backgroundColor('#FFFFFF')
              .alignItems(VerticalAlign.Center)
              .margin({ bottom: 8 })
            }, (b: string) => b)
          }
          .width('100%')
          .padding(15)
          .borderRadius(16)
          .backgroundColor(Color.White)
          .border({ width: 1, color: CARD_BORDER })
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 8 })

          Text('AI 生成内容，仅供学习参考，请结合园所实际执行')
            .fontSize(12.0)
            .fontColor(TEXT_WEAK)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 6, bottom: 4 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .width('100%')

      // 底部操作
      Row({ space: 10 }) {
        Text('再分析一张')
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .layoutWeight(1)
          .height(48)
          .textAlign(TextAlign.Center)
          .borderRadius(24)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#FEF8E3' })
          .onClick(() => {
            this.reset();
          })

        Text('保存到我的')
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#8A7A50')
          .layoutWeight(1)
          .height(48)
          .textAlign(TextAlign.Center)
          .borderRadius(24)
          .backgroundColor(PRIMARY)
          .shadow({ radius: 10, color: '#14000000', offsetY: 4 })
          .onClick(() => {
            this.toast('已保存到「我的 · 实操记录」');
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 16 + SafeArea.bottomVp })
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#F2ECD8' })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 历史记录半屏浮窗 ====================
  // 结构与答题卡底部面板一致：全屏遮罩 + 底部圆角面板（叠在 Stack 里）
  @Builder
  HistorySheet() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 遮罩：点击关闭
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#29000000')
        .onClick(() => {
          this.historyOpen = false;
        })

      // 面板：有记录时高一些（列表可滚动），空态矮一些
      Column() {
        Row() {
          Text('分析历史')
            .fontSize(17.0)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)

          Blank()

          Text('×')
            .fontSize(25.0)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_SUB)
            .onClick(() => {
              this.historyOpen = false;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ bottom: 6 })

        Scroll() {
          Column() {
            if (this.historyItems.length === 0) {
              // 空态
              Column({ space: 8 }) {
                Text('⏱')
                  .fontSize(34.0)
                Text('还没有历史记录')
                  .fontSize(16.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(TEXT_MAIN)
                Text('完成一次 AI 分析后，记录会自动出现在这里')
                  .fontSize(13.5)
                  .fontColor(TEXT_SUB)
              }
              .width('100%')
              .padding({ top: 60 })
              .alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.historyItems, (r: AIPracticeRecord) => {
                this.HistoryRow(r)
              }, (r: AIPracticeRecord) => `${r.timestamp}_${r.sceneIndex}`)
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height(this.historyItems.length > 0 ? '62%' : '40%')
      .padding({ left: 18, right: 18, top: 16, bottom: 22 + SafeArea.bottomVp })
      .borderRadius({ topLeft: 20, topRight: 20 })
      .backgroundColor(Color.White)
      .alignItems(HorizontalAlign.Start)
      .shadow({ radius: 24, color: '#33000000', offsetY: 8 })
    }
    .width('100%')
    .height('100%')
  }

  // 历史列表单行：缩略图 + 场景名/时间 + 达标度，点击回看该次结果
  @Builder
  HistoryRow(r: AIPracticeRecord) {
    Row({ space: 12 }) {
      // 照片缩略图：示例照片用内置图兜底，加载失败时底色兜底不至于空白
      if (r.useDemo) {
        Image($r('app.media.demo_scene'))
          .width(52)
          .height(52)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#FEF8E3')
      } else {
        Image(r.imageUri)
          .width(52)
          .height(52)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#FEF8E3')
      }

      Column({ space: 4 }) {
        Text(r.sceneName)
          .fontSize(16.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(r.date)
          .fontSize(13.0)
          .fontColor(TEXT_WEAK)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 达标度徽标
      Text(`${r.score} 分`)
        .fontSize(13.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(ACCENT)
        .padding({ left: 9, right: 9, top: 4, bottom: 4 })
        .borderRadius(10)
        .backgroundColor('#FEF8E3')

      Text('›')
        .fontSize(20.0)
        .fontColor(TEXT_WEAK)
    }
    .width('100%')
    .padding({ top: 11, bottom: 11 })
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: '#F8F4E8' })
    .onClick(() => {
      this.openRecord(r);
    })
  }
}
