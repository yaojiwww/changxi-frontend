import { AIView } from './AIChatPage';
import { MineView } from './MinePage';
import { ProfileModel, ProfileCache } from '../common/ProfileModel';
import { GoalModel, GoalCache, levelFullName, levelShortName, LEVEL_BEGINNER, LEVEL_INTERMEDIATE, LEVEL_ADVANCED } from '../common/GoalModel';
import { ExamDateModel, ExamDateCache, daysUntil } from '../common/ExamDateModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { DEFAULT_TOPIC_ID } from '../common/PracticeData';
import { StudyCache } from '../common/StudyCache';
import { TokenStore } from '../common/TokenStore';
import { DashboardApi } from '../api/DashboardApi';
import { NavSignal, takePendingTab } from '../common/NavSignal';
import { SafeArea } from '../common/SafeArea';

// 知识分类条目：name 为分类名，total 为题量，children 为可展开的子分类（可选）
interface KnowledgeEntry {
  name: string;
  total: number;
  children?: KnowledgeEntry[];
}

// 「基础知识」Tab 固定展示的基础知识条目（不随级别变化）
const basicEntries: KnowledgeEntry[] = [
  { name: '相关法律法规及其它试题', total: 358 },
  { name: '相关环境知识', total: 106 },
  { name: '婴幼儿安全知识', total: 186 },
  { name: '婴幼儿常见病及常见传染病防治基础知识', total: 306 },
  { name: '婴幼儿教育学知识', total: 125 },
  { name: '婴幼儿生理学知识', total: 293 },
  { name: '婴幼儿卫生保健知识', total: 237 },
  { name: '婴幼儿心理学知识', total: 231 },
  { name: '婴幼儿营养常识', total: 168 },
  { name: '保育员职业道德与职业守则', total: 173 },
];

// 报考级别 -> 专业知识条目（第二个 Tab 展示，随顶部级别下拉联动）
const beginnerEntries: KnowledgeEntry[] = [
  {
    name: '生活管理', total: 787,
    children: [
      { name: '组织饮水', total: 67 },
      { name: '保管和使用物品', total: 102 },
      { name: '健康观察', total: 255 },
      { name: '组织盥洗如厕', total: 127 },
      { name: '组织进餐', total: 134 },
      { name: '组织睡眠', total: 102 },
    ],
  },
  {
    name: '卫生管理', total: 324,
    children: [
      { name: '清洁', total: 92 },
      { name: '消毒', total: 232 },
    ],
  },
  { name: '配合教育活动', total: 390 },
];

const intermediateEntries: KnowledgeEntry[] = [
  {
    name: '生活管理', total: 288,
    children: [
      { name: '组织进餐', total: 45 },
      { name: '健康观察', total: 60 },
      { name: '组织盥洗如厕', total: 91 },
      { name: '组织睡眠', total: 92 },
    ],
  },
  {
    name: '卫生管理', total: 172,
    children: [
      { name: '清洁', total: 75 },
      { name: '消毒', total: 97 },
    ],
  },
  { name: '配合教育活动', total: 359 },
];

// 高级专业知识（高级保育员）
const advancedEntries: KnowledgeEntry[] = [
  {
    name: '生活管理', total: 319,
    children: [
      { name: '组织睡眠', total: 36 },
      { name: '防范意外伤害', total: 204 },
      { name: '组织盥洗如厕', total: 33 },
      { name: '组织进餐', total: 46 },
    ],
  },
  {
    name: '卫生管理', total: 74,
    children: [
      { name: '清洁', total: 34 },
      { name: '消毒', total: 40 },
    ],
  },
  { name: '培训与指导', total: 24 },
  { name: '配合教育活动', total: 81 },
];

const levelKnowledgeMap: Map<number, KnowledgeEntry[]> = new Map<number, KnowledgeEntry[]>();
levelKnowledgeMap.set(LEVEL_BEGINNER, beginnerEntries);
levelKnowledgeMap.set(LEVEL_INTERMEDIATE, intermediateEntries);
levelKnowledgeMap.set(LEVEL_ADVANCED, advancedEntries);

// 当前报考级别下的专业知识数组（无数据时回退空数组，渲染兜底文案）
function knowledgeEntriesOf(levelIndex: number): KnowledgeEntry[] {
  const list = levelKnowledgeMap.get(levelIndex);
  return list !== undefined ? list : [];
}

// 列表叶子条目总题量：含子分类的取子项之和，与截图口径一致（如高级专业知识 498）
function entriesLeafTotal(list: KnowledgeEntry[]): number {
  let sum = 0;
  for (const e of list) {
    if (e.children !== undefined && e.children.length > 0) {
      for (const c of e.children) {
        sum += c.total;
      }
    } else {
      sum += e.total;
    }
  }
  return sum;
}

// 列表第一个叶子条目名：主进度卡片高亮区展示"接下来练什么"（基础知识页签=相关法律法规…，专业知识页签=该级别第一个子项）
function firstLeafName(list: KnowledgeEntry[]): string {
  for (const e of list) {
    if (e.children !== undefined && e.children.length > 0) {
      return e.children[0].name;
    }
    return e.name;
  }
  return '';
}

@Entry
@ComponentV2
struct Index {
  @Local currentIndex: number = 0;
  // 跨页共享的个人信息：昵称修改后问候语同步刷新
  @Local profile: ProfileModel = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
  private tabsController: TabsController = new TabsController();

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await ProfileCache.load(context);
    await GoalCache.load(context);   // 应用启动即读目标级别缓存，为空回退默认中级
    await ExamDateCache.load(context);   // 读考试日期缓存，驱动首页倒计时
  }

  // 从子页面返回时，若带有页签跳转请求（如 AI 知识库点「向 AI 提问」），切到目标页签
  onPageShow(): void {
    const pending = takePendingTab();
    if (pending >= 0 && pending !== this.currentIndex) {
      this.currentIndex = pending;
      this.tabsController.changeIndex(pending);
    }
  }

  // 自定义底部导航项：选中/未选中共用同一几何结构（同尺寸、同间距、同节点），
  // 仅切换背景色与图标文字颜色，保证切换时图标文字绝对不位移
  @Builder
  NavItem(title: string, targetIndex: number) {
    Column({ space: 7 }) {
      if (targetIndex === 0) {
        Image($r('app.media.shouy'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .fillColor(this.currentIndex === targetIndex ? '#E4842A' : '#9A8A6E')
      } else if (targetIndex === 1) {
        // AI 伴学：换成 IP 形象，尺寸放大并向上突出（见 AITabItem）
        Image($r('app.media.ip_main'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
      } else {
        Image($r('app.media.wo'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .fillColor(this.currentIndex === targetIndex ? '#E4842A' : '#9A8A6E')
      }

      Text(title)
        .fontSize(15.0)
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === targetIndex ? '#E4842A' : '#9A8A6E')
    }
    // 背景与图标文字区域等高（不设额外固定高/内边距），宽度固定紧凑胶囊
    .width(60)
    .borderRadius(14)
    .backgroundColor(this.currentIndex === targetIndex ? '#FEF8E3' : Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.tabsController.changeIndex(targetIndex);
    })
  }

  // 底部中间项：IP 头像放在白色圆形容器里，向上突出导航栏并放大，作为主入口
  @Builder
  AITabItem() {
    Column({ space: 0 }) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(54)
          .height(54)
          .borderRadius(27)
          .backgroundColor(Color.White)
          .border({ width: 3, color: this.currentIndex === 1 ? '#FBDE71' : '#FEF8E3' })
          .shadow({ radius: 12, color: '#1F000000', offsetY: 3 })

        Image($r('app.media.ip_main'))
          .width(44)
          .height(44)
          .objectFit(ImageFit.Contain)
      }
      .width(54)
      .height(54)
      .translate({ y: -16 })

      Text('AI 伴学')
        .fontSize(12.5)
        .fontWeight(this.currentIndex === 1 ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === 1 ? '#E4842A' : '#9A8A6E')
        .margin({ top: -8 })
    }
    .width(80)
    .height(62)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.currentIndex = 1;
      this.tabsController.changeIndex(1);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 页面主体 Tabs
      Tabs({ index: this.currentIndex, controller: this.tabsController }) {
        // 1. 首页
        TabContent() {
          HomeView()
        }

        // 2. AI 伴学
        TabContent() {
          AIView()
        }

        // 3. 我的
        TabContent() {
          MineView()
        }
      }
      .width('100%')
      .height('100%')
      .barHeight(0)
      .scrollable(true)
      .onChange((index: number) => {
        this.currentIndex = index;
      })

      // 底部悬浮/停靠导航栏
      Row() {
        this.NavItem('首页', 0)
        this.AITabItem()
        this.NavItem('我的', 2)
      }
      .width('100%')
      .height(66)
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .shadow({ radius: 16, color: '#14000000', offsetY: -4 })
      .border({ width: { top: 1 }, color: { top: '#F2ECD8' } })
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16, bottom: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }
}

// ==================== 首页 (HomeView) ====================
@ComponentV2
struct HomeView {
  // 接入全局共享模型：昵称与目标级别跨页同步
  @Local profile: ProfileModel = AppStorageV2.connect(ProfileModel, () => new ProfileModel())!;
  @Local goal: GoalModel = AppStorageV2.connect(GoalModel, () => new GoalModel())!;
  @Local examDate: ExamDateModel = AppStorageV2.connect(ExamDateModel, () => new ExamDateModel())!;
  @Local knowledgeTab: number = 0;   // 0 基础知识 / 1 专业知识（文案随报考级别联动）
  @Local collapsedKeys: string[] = [];   // 已收起的父分类 key（默认全部展开）
  // 环形进度百分比：一进页面显示 0，真实进度由后端 total_progress 下发后覆盖
  @Local completionPercentage: number = 0;
  // 是否已开始学习：点过一次（本地 StudyCache）或后端进度>0 即为 true，按钮显示「继续练习」
  @Local started: boolean = false;
  // 练习页答过题会写 practiceTick，本页收到后补查落盘标记
  @Local nav: NavSignal = AppStorageV2.connect(NavSignal, () => new NavSignal())!;

  @Monitor('nav.practiceTick')
  onPracticeTick(): void {
    if (this.started) {
      return;
    }
    this.started = true;
  }

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await StudyCache.init(context);
    await TokenStore.init(context);
    // 本地「点过一次」标记：点过就永远是「继续练习」，先于接口结果生效，
    // 后面 fetchDashboard 里用 OR 合并，不会把这个标记覆盖回 false
    if (await StudyCache.isStarted()) {
      this.started = true;
    }
    await this.fetchDashboard();
  }

  // 拉取首页看板数据：成功则 total_progress 钳到 0-100 同步给进度环；
  // 失败保持默认 0（接口内部已降级 Mock，此处仅防极端情况）
  private async fetchDashboard(): Promise<void> {
    try {
      const token = await TokenStore.read();
      const res = await DashboardApi.getDashboardData(token);
      if (res.data !== null) {
        const progress = Math.round(res.data.total_progress);
        this.completionPercentage = Math.min(100, Math.max(0, progress));
        // 已开始 = 点过一次（本地 StudyCache）或真实做题进度 > 0，两者取或
        this.started = this.started || this.completionPercentage > 0;
        // res.data.exam_countdown 为后端倒计时天数，当前首页倒计时走本地考试日期（ExamDateModel），
        // 此字段预留，联调后如需切换数据源再在此处接入
      }
    } catch (err) {
      // 极端异常：保持 completionPercentage = 50 默认展示，UI 不崩
    }
  }

  // 当前级别名称
  private levelName(): string {
    return levelFullName(this.goal.levelIndex);
  }

  // 第二个 Tab 文案：随顶部报考级别联动（初级知识 / 中级知识 / 高级知识）
  private secondTabName(): string {
    return levelShortName(this.goal.levelIndex) + '知识';
  }

  // 当前页签展示的列表（基础知识固定 / 专业知识随级别）
  private currentList(): KnowledgeEntry[] {
    return this.knowledgeTab === 0 ? basicEntries : knowledgeEntriesOf(this.goal.levelIndex);
  }

  // 主进度卡片总题量：基础知识 2183 / 专业知识与级别联动（初级1501·中级819·高级498）
  private currentTotal(): number {
    return entriesLeafTotal(this.currentList());
  }

  // 主进度卡片高亮区"接下来练"的分类名
  private currentFirstLeaf(): string {
    const name = firstLeafName(this.currentList());
    return name === '' ? '暂无可练习的分类' : name;
  }

  // 父分类是否展开：默认全部展开，点过的记入 collapsedKeys
  private isExpanded(name: string): boolean {
    const key = this.knowledgeTab.toString() + '_' + this.goal.levelIndex.toString() + '_' + name;
    return this.collapsedKeys.indexOf(key) < 0;
  }

  // 展开/收起某个父分类
  private toggleGroup(name: string): void {
    const key = this.knowledgeTab.toString() + '_' + this.goal.levelIndex.toString() + '_' + name;
    const idx = this.collapsedKeys.indexOf(key);
    if (idx >= 0) {
      this.collapsedKeys = this.collapsedKeys.filter((k: string): boolean => k !== key);
    } else {
      this.collapsedKeys = this.collapsedKeys.concat([key]);
    }
  }

  build() {
    Column() {
      // ============ 1. 顶部标题：报考级别（固定在顶部，不随内容滚动） ============
      Row() {
        Text(this.levelName())
          .fontSize(21.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')

        Image($r('app.media.xiangxia'))
          .width(16)
          .height(16)
          .objectFit(ImageFit.Contain)
          .margin({ left: 4 })

      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 8 })
      .alignItems(VerticalAlign.Bottom)
      .bindMenu(this.LevelMenu())

      Scroll() {
        Column() {

          // 知识分类 Tab（第二项文案随报考级别联动；点击仅切换下方知识点练习列表）
          Row({ space: 30 }) {
            // Tab 1：基础知识（固定，不随级别变化）
            Column({ space: 8 }) {
              Text(' 基础知识')
                .fontSize(18.0)
                .fontWeight(this.knowledgeTab === 0 ? FontWeight.Bold : FontWeight.Medium)
                .fontColor(this.knowledgeTab === 0 ? '#55402F' : '#9A8A6E')

              Row()
                .width(28)
                .height(3)
                .borderRadius(1.5)
                .backgroundColor(this.knowledgeTab === 0 ? '#FBDE71' : Color.Transparent)
            }
            .onClick(() => {
              this.knowledgeTab = 0;
            })

            // Tab 2：初级知识 / 中级知识 / 高级知识（文案随顶部报考级别联动，点击展示对应级别专业知识）
            Column({ space: 8 }) {
              Text(this.secondTabName())
                .fontSize(18.0)
                .fontWeight(this.knowledgeTab === 1 ? FontWeight.Bold : FontWeight.Medium)
                .fontColor(this.knowledgeTab === 1 ? '#55402F' : '#9A8A6E')

              Row()
                .width(28)
                .height(3)
                .borderRadius(1.5)
                .backgroundColor(this.knowledgeTab === 1 ? '#FBDE71' : Color.Transparent)
            }
            .onClick(() => {
              this.knowledgeTab = 1;
            })
          }
          .width('100%')
          .margin({ top: 8, bottom: 10 })
          .alignItems(VerticalAlign.Bottom)

          // ============ 3. 问候卡片（早上好 + 倒计时 + 进度环） ============
          Row() {
            Column({ space: 8 }) {
              Text(`早上好，${this.profile.nickname}`)
                .fontSize(23.0)
                .fontWeight(FontWeight.Bold)
                .fontColor('#55402F')

              // 倒计时天数随设置页保存的考试日期联动：未设置显示 --，过期整句替换
              Text() {
                if (this.examDate.dateStr === '') {
                  Span('距离考试还有 ')
                    .fontColor('#55402F')
                    .fontSize(14.0)
                  Span('--')
                    .fontColor('#55402F')
                    .fontSize(16.0)
                    .fontWeight(FontWeight.Bold)
                  Span(' 天，稳稳向前')
                    .fontColor('#55402F')
                    .fontSize(14.0)
                } else if (daysUntil(this.examDate.dateStr) < 0) {
                  Span('考试日期已过期，请更新考试时间')
                    .fontColor('#55402F')
                    .fontSize(14.0)
                } else {
                  Span('距离考试还有 ')
                    .fontColor('#55402F')
                    .fontSize(14.0)
                  Span(daysUntil(this.examDate.dateStr).toString())
                    .fontColor('#E4842A')
                    .fontSize(16.0)
                    .fontWeight(FontWeight.Bold)
                  Span(' 天，稳稳向前')
                    .fontColor('#55402F')
                    .fontSize(14.0)
                }
              }
              .lineHeight(20)

              Text('每一次练习都算数')
                .fontSize(14.0)
                .fontColor('#55402F')
                .lineHeight(20)

              // 主 CTA 胶囊按钮：点过一次（本地 StudyCache）或进度>0 显示「继续练习」，否则「开始练习」
              Row({ space: 6 }) {
                Text(this.started ? '继续练习' : '开始练习')
                  .fontSize(14.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#8A7A50')
                Text('→')
                  .fontSize(16.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#8A7A50')
              }
              .backgroundColor('#FBDE71')
              .padding({ left: 18, right: 18, top: 9, bottom: 9 })
              .borderRadius(20)
              .margin({ top: 8 })
              .onClick(() => {
                this.startStudy();
              })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 环形进度：value 与中间文字均绑定 completionPercentage（接口 total_progress）
            Stack({ alignContent: Alignment.Center }) {
              Progress({ value: this.completionPercentage, total: 100, type: ProgressType.Ring })
                .width(84)
                .height(84)
                .color('#E4842A')
                .backgroundColor('#FEF8E3')
                .style({ strokeWidth: 8 })

              Text(`${this.completionPercentage}%`)
                .fontSize(21.0)
                .fontWeight(FontWeight.Bold)
                .fontColor('#55402F')
            }
            .margin({ left: 10 })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 24, bottom: 24 })
          .borderRadius(20)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#F2ECD8' })
          .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })

          // ============ 4. 五个快捷入口 ============
          Row() {
            this.QuickAction('每日一练', $r('app.media.meir'), 'pages/DailyPracticePage')
            this.QuickAction('AI知识库', $r('app.media.zhishi'), 'pages/AIKnowledgePage')
            this.QuickAction('模拟考试', $r('app.media.kaos'), 'pages/ExamListPage')
            this.QuickAction('AI实操', $r('app.media.aishic'), 'pages/AIPracticePage')
            this.QuickAction('政策解读', $r('app.media.zhengc'), 'pages/PolicyDetailPage')
          }
          .width('100%')
          .margin({ bottom: 20 })

          // ============ 5. 知识点练习 ============
          Text(' 知识点练习')
            .fontSize(18.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#55402F')
            .width('100%')
            .margin({ bottom: 12 })

          // 主进度卡片
          Column() {
            Row() {
              // 左侧半环仪表盘 0/2183
              Column() {
                Stack({ alignContent: Alignment.Top }) {
                  Progress({ value: 0, total: 100, type: ProgressType.Ring })
                    .width(96)
                    .height(96)
                    .color('#E4842A')
                    .backgroundColor('#FEF8E3')
                    .style({ strokeWidth: 9 })
                }
                .width(96)
                .height(54)
                .clip(true)

                Text('0/' + this.currentTotal().toString())
                  .fontSize(16.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#55402F')
                  .margin({ top: 4 })
              }

              // 右侧统计
              Column({ space: 14 }) {
                Row() {
                  Text('总进度')
                    .fontSize(14.0)
                    .fontColor('#9A8A6E')
                    .layoutWeight(1)
                  Text('0.0%')
                    .fontSize(16.0)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#55402F')
                }
                .width('100%')

                Row() {
                  Text('正确率')
                    .fontSize(14.0)
                    .fontColor('#9A8A6E')
                    .layoutWeight(1)
                  Text('--%')
                    .fontSize(16.0)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#55402F')
                }
                .width('100%')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 20, top: 10 })


              Path()
                .width(20)
                .height(20)
                .commands('M14.5 3.5L20.5 9.5M13 5L19 11M16.5 8L8 16.5M6 14.5L9.5 18L4.5 20Z')
                .stroke('#9A8A6E')
                .strokeWidth(1.6)
                .fill(Color.Transparent)
                .strokeLineCap(LineCapStyle.Round)
                .strokeLineJoin(LineJoinStyle.Round)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)

            // 内嵌区块 + 开始练习按钮（高亮分类随页签/级别联动）
            Column() {
              Text(this.currentFirstLeaf())
                .fontSize(16.0)
                .fontWeight(FontWeight.Bold)
                .fontColor('#55402F')
                .width('100%')
                .margin({ bottom: 12 })

              Row() {
                Text('开始练习')
                  .fontSize(16.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#8A7A50')
              }
              .width('100%')
              .height(42)
              .borderRadius(21)
              .backgroundColor('#FBDE71')
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.gotoPractice(this.currentFirstLeaf());
              })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 14, bottom: 14 })
            .borderRadius(14)
            .backgroundColor('#FEF8E3')
            .margin({ top: 16 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(16)
          .borderRadius(20)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#F2ECD8' })
          .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })
          .margin({ bottom: 14 })


          // 主体列表：各知识分类条目（随页面滚动浏览，无悬浮入口干扰）
          // Tab 0 基础知识固定；Tab 1 按当前报考级别取对应专业知识；无数据则兜底文案
          if (this.currentList().length === 0) {
            Text('暂无知识点分类')
              .fontSize(15.0)
              .fontColor('#9A8A6E')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 24, bottom: 24 })
          } else {
            Column() {
              ForEach(this.currentList(),
                (item: KnowledgeEntry) => {
                  // 每个条目包一层 Column 作为唯一根节点：
                  // ForEach 的 itemGenerator 若直接产出多个根组件（如 @Builder 调用后再跟兄弟节点），
                  // 运行时会导致整段列表不渲染（编译可通过但界面空白），必须单根
                  Column() {
                    if (item.children !== undefined && item.children.length > 0) {
                      // 可展开的父分类：名称+进度条+0/N道，点组头收起/展开（默认展开）
                      this.GroupHeader(item)
                      if (this.isExpanded(item.name)) {
                        ForEach(item.children, (child: KnowledgeEntry) => {
                          Column() {
                            this.KnowledgeRow(child.name, child.total, true)
                            Divider().color('#F8F4E8').strokeWidth(1).margin({ left: 16 })
                          }
                          .width('100%')
                        }, (child: KnowledgeEntry) => `${item.name}_${child.name}`)
                      }
                    } else {
                      // 无子分类的平铺条目
                      this.KnowledgeRow(item.name, item.total, false)
                    }
                  }
                  .width('100%')
                // key 中编入级别与 Tab：初级/中级顶级分类名相同，避免 ArkUI 按同名 key 复用旧行导致内容不刷新
                }, (item: KnowledgeEntry) => `${this.knowledgeTab}_${this.goal.levelIndex}_${item.name}`)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 4 })
            .borderRadius(20)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#F2ECD8' })
            .shadow({ radius: 10, color: '#0A000000', offsetY: 3 })
            .margin({ bottom: 24 })
          }
        }
        .padding({ left: 16, right: 16, top: 4, bottom: 84 })
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
    // 沉浸式：页面底色铺进状态栏区域，内容用 SafeArea.topVp 让出状态栏高度（自动适配机型）
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .padding({ top: SafeArea.topVp })
  }

  // 报考级别下拉菜单（初级 / 中级 / 高级）：写回全局级别并落库
  @Builder
  LevelMenu() {
    Menu() {
      MenuItem({ content: '初级保育员', labelInfo: this.goal.levelIndex === LEVEL_BEGINNER ? '✓' : '' })
        .onClick(() => {
          GoalCache.saveLevel(LEVEL_BEGINNER);
        })
      MenuItem({ content: '中级保育员', labelInfo: this.goal.levelIndex === LEVEL_INTERMEDIATE ? '✓' : '' })
        .onClick(() => {
          GoalCache.saveLevel(LEVEL_INTERMEDIATE);
        })
      MenuItem({ content: '高级保育员', labelInfo: this.goal.levelIndex === LEVEL_ADVANCED ? '✓' : '' })
        .onClick(() => {
          GoalCache.saveLevel(LEVEL_ADVANCED);
        })
    }
  }

  // 父分类组头：名称 + 展开箭头 + 细进度条 + 0/N道（点整行展开/收起）
  @Builder
  GroupHeader(item: KnowledgeEntry) {
    Column() {
      Row({ space: 10 }) {
        Text(item.name)
          .fontSize(16.5)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .layoutWeight(1)

        Text('›')
          .fontSize(21.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#B5A98D')
          .rotate({ x: 0, y: 0, z: 1, angle: this.isExpanded(item.name) ? -90 : 90 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.toggleGroup(item.name);
      })

      this.CountLine(item.total)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: 14, bottom: 12 })
  }

  // 细进度条 + 0/N道（0 蓝色、题量灰色，对齐聚题库格式）
  @Builder
  CountLine(total: number) {
    Row({ space: 10 }) {
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(5)
          .borderRadius(2.5)
          .backgroundColor('#FEF8E3')
      }
      .layoutWeight(1)

      Text() {
        Span('0')
          .fontSize(13.5)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E4842A')
        Span('/' + total.toString() + '道')
          .fontSize(13.0)
          .fontColor('#9A8A6E')
      }
    }
    .width('100%')
    .margin({ top: 8 })
    .alignItems(VerticalAlign.Center)
  }

  // 分类条目行：名称 + 细进度条 + 0/N道 + 右箭头（子分类带缩进，点击进练习页）
  @Builder
  KnowledgeRow(title: string, total: number, indent: boolean) {
    Column() {
      Row({ space: 10 }) {
        Text(title)
          .fontSize(16.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text('›')
          .fontSize(21.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#B5A98D')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      this.CountLine(total)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: 13, bottom: 13, left: indent ? 16 : 0 })
    .onClick(() => {
      this.gotoPractice(title);
    })
  }

  // 「开始练习」/「继续练习」：切到「基础知识」页签，并直接进入该页签第一个知识点练习
  private startStudy(): void {
    // 点过一次立刻变「继续练习」（本地落盘，重启后仍生效），再跳练习页
    this.started = true;
    StudyCache.markStarted();
    this.knowledgeTab = 0;   // 主按钮固定指向基础知识练习
    this.gotoPractice(firstLeafName(basicEntries));
  }

  // 进入答题页：默认跳基础知识第一个知识条目；title 为该知识点名称，随参数传给答题页做标题
  private gotoPractice(title: string = '', topicId: number = DEFAULT_TOPIC_ID): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/PracticePage',
      params: { topicId: topicId, topicName: title }
    });
  }

  // 快捷入口。routeUrl 非空时点击跳转对应页面（已注册于 main_pages.json），为空则不跳转
  @Builder
  QuickAction(title: string, icon: Resource, routeUrl: string = '') {
    Column({ space: 8 }) {
      Image(icon)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .fillColor('#55402F')

      Text(title)
        .fontSize(13.0)
        .fontColor('#9A8A6E')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (routeUrl !== '') {
        this.getUIContext().getRouter().pushUrl({ url: routeUrl });
      }
    })
  }
}
