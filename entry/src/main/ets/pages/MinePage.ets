import { ProfileModel, ProfileCache } from '../common/ProfileModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { AppConfig } from '../common/AppConfig';
import { SafeArea } from '../common/SafeArea';
import { TokenStore } from '../common/TokenStore';
import { GoalModel, GoalCache, levelShortName, LEVEL_BEGINNER, LEVEL_INTERMEDIATE, LEVEL_ADVANCED } from '../common/GoalModel';
import { StudyRecordStore, StudyRecord } from '../common/StudyRecordStore';

// 学习报告的最小统计字段集（每日一练/知识点练习的 PracticeReport 与模拟考试的 ExamFinished 通用）
interface ReportStatsLike {
  total: number;
  correctCount: number;
  duration: number;
}

@ComponentV2
export struct MineView {
  // 跨页共享的个人信息：头像与昵称同步刷新
  @Local profile: ProfileModel = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
  // 跨页共享的目标级别：与首页联动
  @Local goal: GoalModel = AppStorageV2.connect(GoalModel, () => new GoalModel())!;

  // 调整目标半屏浮窗：tempLevel 为浮窗内临时选中值，点确认才写回全局
  @Local goalSheetVisible: boolean = false;
  @Local tempLevel: number = LEVEL_INTERMEDIATE;

  // 学习统计数据：仅做后端数据占位渲染，禁止本地计算/缓存/硬编码。
  // 字段为空或请求失败时保持 '0' / '-' 兜底，避免布局崩坏
  @Local studyDays: string = '0';
  @Local totalAnswers: string = '0';
  @Local accuracy: string = '-';
  @Local studyHours: string = '0';

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await AppConfig.load(context);
    await TokenStore.init(context);
    await ProfileCache.load(context);
    await GoalCache.load(context);   // 读目标级别缓存，为空则回退默认中级
    this.fetchLearningStats();
  }

  // 打开调整目标半屏浮窗，并回显当前选中级别
  private openGoalSheet(): void {
    this.tempLevel = this.goal.levelIndex;
    this.goalSheetVisible = true;
  }

  // 点确认：把浮窗临时值写回全局级别并落库，关闭浮窗
  private async confirmGoal(): Promise<void> {
    this.goalSheetVisible = false;
    await GoalCache.saveLevel(this.tempLevel);
  }

  // 本地统计：累计答题 / 平均正确率 / 学习时长 / 连续学习天数
  // 数据源 = 本机学习记录（每日一练、知识点练习、模拟考试交卷后归档的报告）
  private async fetchLearningStats(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        return;
      }
      await StudyRecordStore.init(context);
      const records: StudyRecord[] = StudyRecordStore.getAll();
      let totalQ: number = 0;
      let correctQ: number = 0;
      let durSec: number = 0;
      const daySet: Set<string> = new Set<string>();
      for (let i = 0; i < records.length; i++) {
        const r = records[i];
        try {
          const s = JSON.parse(r.detailData) as ReportStatsLike;
          totalQ += s.total;
          correctQ += s.correctCount;
          durSec += s.duration;
        } catch (e) {
          // 单条记录损坏：跳过不统计
        }
        daySet.add(r.date.substring(0, 10));
      }

      // 累计答题
      this.totalAnswers = totalQ.toString();
      // 平均正确率（按题加权）
      this.accuracy = totalQ > 0 ? Math.round(correctQ / totalQ * 100).toString() + '%' : '-';
      // 学习时长：≥1小时显示小时，不足1小时显示分钟
      const hours: number = durSec / 3600;
      if (durSec <= 0) {
        this.studyHours = '0';
      } else if (hours >= 1) {
        this.studyHours = hours.toFixed(1) + 'h';
      } else {
        this.studyHours = Math.max(1, Math.round(durSec / 60)).toString() + '分钟';
      }
      // 连续学习天数：今天有记录从今天数，今天没有则从昨天数，断一天即停
      let streak: number = 0;
      let cursor: number = Date.now();
      if (!daySet.has(this.dayStr(cursor)) && daySet.has(this.dayStr(cursor - 86400000))) {
        cursor -= 86400000;
      }
      while (daySet.has(this.dayStr(cursor))) {
        streak++;
        cursor -= 86400000;
      }
      this.studyDays = streak.toString();
    } catch (err) {
      // 异常时保持 '0' / '-' 兜底展示，不提示打扰
    }
  }

  // 时间戳 → 'YYYY-MM-DD'
  private dayStr(ts: number): string {
    const d = new Date(ts);
    const p = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    return d.getFullYear().toString() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          // ==================== 1. 个人名片卡片 ====================
          Column() {
            // 蓝色名片上半部分
            Row() {
              // 头像（白底圆角矩形，居中默认头像/图片）
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(62)
                  .height(62)
                  .borderRadius(18)
                  .backgroundColor(Color.White)
                  .shadow({ radius: 8, color: '#1A000000', offsetY: 3 })

                if (this.profile.avatarUri !== '') {
                  Image(this.profile.avatarUri)
                    .width(62)
                    .height(62)
                    .borderRadius(18)
                    .objectFit(ImageFit.Cover)
                } else {
                  // 这里要替换真实图标（用户头像图片）
                  Text(this.profile.nickname.substring(0, 1))
                    .fontSize(27.0)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#E4842A')
                }
              }
              .onClick(() => {
                this.getUIContext().getRouter().pushUrl({ url: 'pages/ProfilePage' });
              })

              // 个人信息
              Column({ space: 4 }) {
                Text(this.profile.nickname)
                  .fontSize(23.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#8A7A50')

                Text(`保育师${levelShortName(this.goal.levelIndex)}备考中`)
                  .fontSize(14.0)
                  .fontColor('#55402F')

                // 连续学习标签
                Row() {
                  Text(`连续学习 ${this.studyDays} 天`)
                    .fontSize(12.0)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#8A7A50')
                }
                .backgroundColor('#33FFFFFF')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(12)
                .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 14 })
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 22, bottom: 22 })
            .borderRadius({ topLeft: 22, topRight: 22 })
            .backgroundColor('#FEF8E3')

            // 下半部分学习数据统计栏（白底）。
            // 状态驱动文本直接内联读 @Local，避免 @Builder 传参在状态变化时不刷新
            Row() {
              Column({ space: 4 }) {
                Text(this.totalAnswers)
                  .fontSize(21.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#55402F')
                Text('累计答题')
                  .fontSize(13.0)
                  .fontColor('#9A8A6E')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)

              Divider().vertical(true).height(28).strokeWidth(1).color('#F2ECD8')

              Column({ space: 4 }) {
                Text(this.accuracy)
                  .fontSize(21.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#55402F')
                Text('平均正确率')
                  .fontSize(13.0)
                  .fontColor('#9A8A6E')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)

              Divider().vertical(true).height(28).strokeWidth(1).color('#F2ECD8')

              Column({ space: 4 }) {
                Text(this.studyHours)
                  .fontSize(21.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#55402F')
                Text('学习时长')
                  .fontSize(13.0)
                  .fontColor('#9A8A6E')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
            }
            .width('100%')
            .padding({ top: 18, bottom: 18 })
            .backgroundColor(Color.White)
            .borderRadius({ bottomLeft: 22, bottomRight: 22 })
          }
          .width('100%')
          .borderRadius(22)
          .shadow({ radius: 12, color: '#14000000', offsetY: 4 })

          // ==================== 2. 目标到达卡片 ====================
          Column() {
            // 标题行
            Row() {
              Column({ space: 4 }) {
                Text('当前目标')
                  .fontSize(13.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E4842A')

                Text('保育师职业技能等级认定')
                  .fontSize(18.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#55402F')
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Text('调整目标')
                .fontSize(14.0)
                .fontWeight(FontWeight.Medium)
                .fontColor('#E4842A')
                .onClick(() => {
                  this.openGoalSheet();
                })
            }
            .width('100%')

            // 目标里程碑步骤条：随全局目标级别动态渲染。
            // 状态驱动内容直接内联读 @Local goal，避免 @Builder 传参不刷新
            Row() {
              // 阶段 1：初级
              Column({ space: 4 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(28)
                    .height(28)
                    .fill('#FBDE71')

                  if (this.goal.levelIndex > LEVEL_BEGINNER) {
                    // 这里要替换真实图标（已完成对勾）
                    Text('✓')
                      .fontSize(15.0)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#8A7A50')
                  } else {
                    Text('1')
                      .fontSize(15.0)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#8A7A50')
                  }
                }
                Text('初级')
                  .fontSize(14.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E4842A')
                Text(this.goal.levelIndex > LEVEL_BEGINNER ? '已完成'
                  : (this.goal.levelIndex === LEVEL_BEGINNER ? '备考中' : '待解锁'))
                  .fontSize(12.0)
                  .fontColor(this.goal.levelIndex === LEVEL_BEGINNER ? '#E4842A' : '#B5A98D')
              }

              // 进度连接线 1
              Row()
                .layoutWeight(1)
                .height(3)
                .backgroundColor(this.goal.levelIndex > LEVEL_BEGINNER ? '#FBDE71' : '#FEF8E3')
                .borderRadius(1.5)
                .margin({ left: 8, right: 8, bottom: 36 })

              // 阶段 2：中级
              Column({ space: 4 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(28)
                    .height(28)
                    .fill(this.goal.levelIndex >= LEVEL_INTERMEDIATE ? '#FBDE71' : '#F2ECD8')

                  if (this.goal.levelIndex > LEVEL_INTERMEDIATE) {
                    Text('✓')
                      .fontSize(15.0)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#8A7A50')
                  } else {
                    Text('2')
                      .fontSize(15.0)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.goal.levelIndex >= LEVEL_INTERMEDIATE ? '#8A7A50' : '#B5A98D')
                  }
                }
                Text('中级')
                  .fontSize(14.0)
                  .fontWeight(this.goal.levelIndex >= LEVEL_INTERMEDIATE ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.goal.levelIndex >= LEVEL_INTERMEDIATE ? '#E4842A' : '#B5A98D')
                Text(this.goal.levelIndex > LEVEL_INTERMEDIATE ? '已完成'
                  : (this.goal.levelIndex === LEVEL_INTERMEDIATE ? '备考中' : '待解锁'))
                  .fontSize(12.0)
                  .fontColor(this.goal.levelIndex === LEVEL_INTERMEDIATE ? '#E4842A' : '#B5A98D')
              }

              // 进度连接线 2
              Row()
                .layoutWeight(1)
                .height(3)
                .backgroundColor(this.goal.levelIndex > LEVEL_INTERMEDIATE ? '#FBDE71' : '#FEF8E3')
                .borderRadius(1.5)
                .margin({ left: 8, right: 8, bottom: 36 })

              // 阶段 3：高级
              Column({ space: 4 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(28)
                    .height(28)
                    .fill(this.goal.levelIndex >= LEVEL_ADVANCED ? '#FBDE71' : '#F2ECD8')

                  Text('3')
                    .fontSize(15.0)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.goal.levelIndex >= LEVEL_ADVANCED ? '#8A7A50' : '#B5A98D')
                }
                Text('高级')
                  .fontSize(14.0)
                  .fontWeight(this.goal.levelIndex >= LEVEL_ADVANCED ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.goal.levelIndex >= LEVEL_ADVANCED ? '#E4842A' : '#B5A98D')
                Text(this.goal.levelIndex === LEVEL_ADVANCED ? '备考中' : '待解锁')
                  .fontSize(12.0)
                  .fontColor(this.goal.levelIndex === LEVEL_ADVANCED ? '#E4842A' : '#B5A98D')
              }
            }
            .width('100%')
            .padding({ left: 10, right: 10 })
            .alignItems(VerticalAlign.Center)
            .margin({ top: 20 })
          }
          .width('100%')
          .padding(20)
          .borderRadius(22)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#F2ECD8' })
          .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })

          // ==================== 3. 功能列表卡片 ====================
          Column() {
            this.FunctionListItem('fav', '我的收藏', 'pages/FavoritesPage')
            Divider().color('#F8F4E8').strokeWidth(1).margin({ left: 52 })
            this.FunctionListItem('wrong', '错题本', 'pages/WrongBookPage')
            Divider().color('#F8F4E8').strokeWidth(1).margin({ left: 52 })
            this.FunctionListItem('study', '学习数据', 'pages/StudyDataPage')
            Divider().color('#F8F4E8').strokeWidth(1).margin({ left: 52 })
            this.FunctionListItem('feedback', '意见反馈', 'pages/FeedbackPage')
            Divider().color('#F8F4E8').strokeWidth(1).margin({ left: 52 })
            this.FunctionListItem('setting', '账号与设置', 'pages/SettingsPage')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
          .borderRadius(22)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#F2ECD8' })
          .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 84 })
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')

    // 调整目标半屏浮窗
    if (this.goalSheetVisible) {
      this.GoalSheet()
    }
    }
    .width('100%')
    .height('100%')
    // 沉浸式：页面底色铺进状态栏区域，内容用 SafeArea.topVp 让出状态栏高度（自动适配机型）
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .padding({ top: SafeArea.topVp })
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, ratio: number): void => {
      // 「我的」是首页 Tab 的子组件，aboutToAppear 只在首次切到本页签时执行一次；
      // 做完练习/考试再切回来会停留在旧数值。这里在每次变为可见（切页签、从答题页返回）时重算统计。
      if (isVisible) {
        this.fetchLearningStats();
      }
    })
  }

  // 调整目标居中弹窗：三个单选 + 确认
  @Builder
  GoalSheet() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩：铺满全屏，点击关闭，不写回
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          this.goalSheetVisible = false;
        })

      // 居中面板：叠在遮罩之上
      Column() {
        Row() {
          Text('调整目标')
            .fontSize(18.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#55402F')

          Blank()

          Text('×')
            .fontSize(25.0)
            .fontWeight(FontWeight.Medium)
            .fontColor('#9A8A6E')
            .onClick(() => {
              this.goalSheetVisible = false;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ bottom: 8 })

        // 三个单选选项
        this.GoalOption(LEVEL_BEGINNER, '初级', '零基础起步，掌握保育入门技能')
        Divider().color('#F8F4E8').strokeWidth(1)
        this.GoalOption(LEVEL_INTERMEDIATE, '中级', '系统提升，胜任日常保育工作')
        Divider().color('#F8F4E8').strokeWidth(1)
        this.GoalOption(LEVEL_ADVANCED, '高级', '精进专业，具备管理与带教能力')

        // 确认按钮
        Button('确认')
          .width('100%')
          .height(48)
          .borderRadius(24)
          .backgroundColor('#FBDE71')
          .fontColor('#8A7A50')
          .fontSize(17.0)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 20 })
          .onClick(() => {
            this.confirmGoal();
          })
      }
      .width('86%')
      .padding({ left: 20, right: 20, top: 20, bottom: 28 })
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 24, color: '#33000000', offsetY: 8 })
    }
    .width('100%')
    .height('100%')
  }

  // 单个级别选项：读 tempLevel 判断选中态，点选只改浮窗临时值
  @Builder
  GoalOption(index: number, title: string, subtitle: string) {
    Row() {
      Column({ space: 3 }) {
        Text(title)
          .fontSize(17.0)
          .fontWeight(this.tempLevel === index ? FontWeight.Bold : FontWeight.Medium)
          .fontColor('#55402F')
        Text(subtitle)
          .fontSize(13.0)
          .fontColor('#9A8A6E')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 单选圈：选中实心蓝，未选中空心
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(22)
          .height(22)
          .fill(this.tempLevel === index ? '#FBDE71' : Color.White)
          .stroke(this.tempLevel === index ? '#E4842A' : '#FEF8E3')
          .strokeWidth(1.5)

        if (this.tempLevel === index) {
          Text('✓')
            .fontSize(13.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8A7A50')
        }
      }
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.tempLevel = index;
    })
  }

  // 功能列表项。routeUrl 非空时整行点击跳转对应页面（已注册于 main_pages.json）
  @Builder
  FunctionListItem(iconType: string, title: string, routeUrl: string) {
    Row() {
      // 浅蓝背景图标容器
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor('#FEF8E3')

        // 图标来自 app.media 资源：收藏 shouc / 错题本 cuot / 学习数据 xuexsj / 意见反馈 diaoc / 账号与设置 shez
        if (iconType === 'fav') {
          Image($r('app.media.shouc'))
            .width(23)
            .height(23)
            .objectFit(ImageFit.Contain)
            .fillColor('#E4842A')
        } else if (iconType === 'wrong') {
          Image($r('app.media.cuot'))
            .width(23)
            .height(23)
            .objectFit(ImageFit.Contain)
            .fillColor('#E4842A')
        } else if (iconType === 'study') {
          Image($r('app.media.xuexsj'))
            .width(23)
            .height(23)
            .objectFit(ImageFit.Contain)
            .fillColor('#E4842A')
        } else if (iconType === 'feedback') {
          Image($r('app.media.diaoc'))
            .width(23)
            .height(23)
            .objectFit(ImageFit.Contain)
            .fillColor('#E4842A')
        } else {
          Image($r('app.media.shez'))
            .width(23)
            .height(23)
            .objectFit(ImageFit.Contain)
            .fillColor('#E4842A')
        }
      }

      // 功能标题
      Text(title)
        .fontSize(16.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#55402F')
        .margin({ left: 12 })
        .layoutWeight(1)

      Text('›')
        .fontSize(21.0)
        .fontWeight(FontWeight.Medium)
        .fontColor('#B5A98D')
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (routeUrl !== '') {
        this.getUIContext().getRouter().pushUrl({ url: routeUrl });
      }
    })
  }
}
