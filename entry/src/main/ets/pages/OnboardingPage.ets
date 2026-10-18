import { AppStorageV2 } from '@kit.ArkUI';
import {
  GoalCache, levelFullName, LEVEL_BEGINNER, LEVEL_INTERMEDIATE, LEVEL_ADVANCED
} from '../common/GoalModel';
import { ProfileCache, ProfileModel } from '../common/ProfileModel';
import { ExamDateCache, formatExamDateCN, parseExamDate } from '../common/ExamDateModel';
import { OnboardingCache } from '../common/OnboardingCache';

// 目标级别选项：标题 + 一句说明，帮新用户判断自己属于哪一级
interface LevelOption {
  index: number;
  name: string;
  desc: string;
}

const LEVEL_OPTIONS: LevelOption[] = [
  { index: LEVEL_BEGINNER, name: '初级保育员', desc: '零基础 / 第一次报考' },
  { index: LEVEL_INTERMEDIATE, name: '中级保育员', desc: '已有一点照护经验' },
  { index: LEVEL_ADVANCED, name: '高级保育员', desc: '资深从业 / 想升职加薪' },
];

// 新用户引导页：登录后第一次进入，问备考目标 + 基本信息，可跳过（跳过=默认初级）
@Entry
@ComponentV2
struct Onboarding {
  @Local selectedLevel: number = LEVEL_BEGINNER;   // 未选择时就是初级（跳过即默认初级）
  @Local nickname: string = '用户001';             // 默认昵称，用户可自行修改
  @Local dateStr: string = '';                     // YYYY-MM-DD，空串=未设置

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await GoalCache.load(context);
    await ProfileCache.load(context);
    await ExamDateCache.load(context);
    await OnboardingCache.init(context);
    // 已缓存过昵称则回显，否则保持默认「用户001」
    const profile = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
    this.nickname = profile.nickname;
  }

  // 弹原生日期选择器（底部弹出，年/月/日）
  private openDatePicker(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date(2020, 0, 1),
      end: new Date(2040, 11, 31),
      selected: this.dateStr === '' ? new Date() : parseExamDate(this.dateStr),
      onAccept: (value: DatePickerResult) => {
        const now = new Date();
        const month = value.month ?? (now.getMonth() + 1);
        const day = value.day ?? now.getDate();
        const monthStr = month < 10 ? `0${month}` : `${month}`;
        const dayStr = day < 10 ? `0${day}` : `${day}`;
        this.dateStr = `${value.year}-${monthStr}-${dayStr}`;
      }
    });
  }

  // 开始备考：落库已填信息后进首页
  private async start(): Promise<void> {
    await GoalCache.saveLevel(this.selectedLevel);
    if (this.nickname !== '') {
      await ProfileCache.saveNickname(this.nickname);
    }
    if (this.dateStr !== '') {
      await ExamDateCache.saveDate(this.dateStr);
    }
    await OnboardingCache.markDone();
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/HomePage' });
  }

  // 跳过：目标按初级落库，其余不写，之后可在设置里改
  private async skip(): Promise<void> {
    await GoalCache.saveLevel(LEVEL_BEGINNER);
    await OnboardingCache.markDone();
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/HomePage' });
  }

  build() {
    Column() {
      // ===== 顶部：标题 + 跳过 =====
      Row() {
        Text('设置备考目标')
          .fontSize(18.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .layoutWeight(1)

        Text('跳过')
          .fontSize(15.0)
          .fontColor('#9A8A6E')
          .padding({ left: 12, right: 4, top: 6, bottom: 6 })
          .onClick(() => {
            this.skip();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          Text('先告诉我们你的备考目标')
            .fontSize(23.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#55402F')
            .width('100%')

          Text('不同级别对应的题库和知识点不同，选好后首页会按你的级别抽题')
            .fontSize(14.0)
            .fontColor('#9A8A6E')
            .lineHeight(20)
            .width('100%')
            .margin({ top: 8, bottom: 20 })

          // ===== 目标级别选择 =====
          ForEach(LEVEL_OPTIONS, (item: LevelOption) => {
            Row({ space: 12 }) {
              // 单选圆点
              Column() {
                if (this.selectedLevel === item.index) {
                  Circle()
                    .width(9)
                    .height(9)
                    .fill(Color.White)
                }
              }
              .width(20)
              .height(20)
              .borderRadius(10)
              .backgroundColor(this.selectedLevel === item.index ? '#FBDE71' : Color.Transparent)
              .border({ width: 1.5, color: this.selectedLevel === item.index ? '#E4842A' : '#FEF8E3' })
              .justifyContent(FlexAlign.Center)

              Column({ space: 4 }) {
                Text(item.name)
                  .fontSize(16.5)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#55402F')
                Text(item.desc)
                  .fontSize(13.0)
                  .fontColor('#9A8A6E')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 15, bottom: 15 })
            .borderRadius(14)
            .backgroundColor(this.selectedLevel === item.index ? '#FEF8E3' : Color.White)
            .border({
              width: 1.5,
              color: this.selectedLevel === item.index ? '#E4842A' : '#F2ECD8'
            })
            .margin({ bottom: 10 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.selectedLevel = item.index;
            })
          }, (item: LevelOption) => item.index.toString())

          // ===== 基本信息（可留空） =====
          Text('基本信息')
            .fontSize(16.5)
            .fontWeight(FontWeight.Bold)
            .fontColor('#55402F')
            .width('100%')
            .margin({ top: 14, bottom: 10 })

          Column() {
            Row({ space: 12 }) {
              Text('昵称')
                .fontSize(16.0)
                .fontColor('#55402F')
                .width(72)

              TextInput({ text: $$this.nickname, placeholder: '怎么称呼你' })
                .height(48)
                .backgroundColor(Color.Transparent)
                .padding({ left: 0, right: 0 })
                .placeholderColor('#B5A98D')
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)

            Divider().color('#F8F4E8').strokeWidth(1).margin({ left: 16, right: 16 })

            Row() {
              Text('考试时间')
                .fontSize(16.0)
                .fontColor('#55402F')
                .width(72)

              Text(this.dateStr === '' ? '还未确定' : formatExamDateCN(this.dateStr))
                .fontSize(15.0)
                .fontColor(this.dateStr === '' ? '#B5A98D' : '#E4842A')
                .layoutWeight(1)

              Text('›')
                .fontSize(21.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#B5A98D')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.openDatePicker();
            })
          }
          .width('100%')
          .borderRadius(16)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#F2ECD8' })

          Text('信息只保存在本机，之后可在「我的 - 设置」里随时修改')
            .fontSize(12.5)
            .fontColor('#B5A98D')
            .width('100%')
            .margin({ top: 10 })

          // ===== 开始备考 =====
          Button('开始备考')
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor('#FBDE71')
            .fontColor('#8A7A50')
            .fontSize(17.0)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 24 })
            .onClick(() => {
              this.start();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }
}
