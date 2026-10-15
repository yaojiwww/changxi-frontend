import { KP_DOCS, KP_GROUPS, KpDoc, KpGroup, KpSection } from '../common/KnowledgeData';
import { GoalModel, LEVEL_INTERMEDIATE, LEVEL_ADVANCED } from '../common/GoalModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { signalPendingTab } from '../common/NavSignal';

// 关键词命中条目
interface SearchHit {
  docName: string;
  levelName: string;
  section: string;
  text: string;
}

// 统一配色（与全局蓝色扁平风一致）
const PRIMARY: string = '#3B6BF6';
const TEXT_MAIN: string = '#1A202C';
const TEXT_SUB: string = '#6B7484';
const TEXT_WEAK: string = '#9AA3B2';
const CARD_BORDER: string = '#E9EEF6';

function levelNameOf(levelIndex: number): string {
  if (levelIndex === LEVEL_INTERMEDIATE) {
    return '中级';
  }
  if (levelIndex === LEVEL_ADVANCED) {
    return '高级';
  }
  return '初级';
}

// 分类考点总数：技能要求 + 知识要求
function pointsOf(doc: KpDoc): number {
  let n = 0;
  for (const s of doc.sections) {
    n += s.skill.length + s.theory.length;
  }
  return n;
}

@Entry
@ComponentV2
struct AIKnowledge {
  @Local openedId: string = '';         // 当前选中的分类 id
  @Local keyword: string = '';          // 搜索关键词
  @Local expandedGroups: string[] = []; // 左栏已展开的级别分组
  // 我的备考级别：与新用户引导、首页共用一个真源
  @Local goal: GoalModel = AppStorageV2.connect(GoalModel, () => new GoalModel())!;

  aboutToAppear(): void {
    // 左栏默认展开「通用」与「我的备考级别」，其余收起
    const myCode = this.myLevelCode();
    const opened: string[] = ['GENERAL'];
    if (myCode !== 'GENERAL') {
      opened.push(myCode);
    }
    this.expandedGroups = opened;

    // 默认选中「我的备考级别」的第一个分类，没命中则选通用第一个
    const myLevel = levelNameOf(this.goal.levelIndex);
    for (const g of KP_GROUPS) {
      if (g.levelName.startsWith(myLevel) && g.docs.length > 0) {
        this.openedId = g.docs[0].id;
        return;
      }
    }
    this.openedId = KP_DOCS[0].id;
  }

  // 当前选中的分类文档
  private get openedDoc(): KpDoc | undefined {
    return KP_DOCS.find((d: KpDoc) => d.id === this.openedId);
  }

  private docTitle(): string {
    const d = this.openedDoc;
    return d !== undefined ? d.funcName : '知识点';
  }

  private docSubtitle(): string {
    const d = this.openedDoc;
    return d !== undefined ? d.subtitle : '';
  }

  private docLevel(): string {
    const d = this.openedDoc;
    return d !== undefined ? d.levelName : '';
  }

  // 级别短名（去掉括号说明），用于左栏分组标题
  private shortLevel(levelName: string): string {
    const i = levelName.indexOf('（');
    return i > 0 ? levelName.substring(0, i) : levelName;
  }

  // 我的备考级别代码（L5/L4/L3）
  private myLevelCode(): string {
    const n = levelNameOf(this.goal.levelIndex);
    if (n === '中级') {
      return 'L4';
    }
    if (n === '高级') {
      return 'L3';
    }
    return 'L5';
  }

  private isGroupOpen(level: string): boolean {
    return this.expandedGroups.includes(level);
  }

  private toggleGroup(level: string): void {
    if (this.isGroupOpen(level)) {
      this.expandedGroups = this.expandedGroups.filter((x: string) => x !== level);
    } else {
      const next: string[] = this.expandedGroups.slice();
      next.push(level);
      this.expandedGroups = next;
    }
  }

  // 全部考点总数
  private totalPoints(): number {
    let n = 0;
    for (const d of KP_DOCS) {
      n += pointsOf(d);
    }
    return n;
  }

  private skillCount(): number {
    const d = this.openedDoc;
    if (d === undefined) {
      return 0;
    }
    let n = 0;
    for (const s of d.sections) {
      n += s.skill.length;
    }
    return n;
  }

  private theoryCount(): number {
    const d = this.openedDoc;
    if (d === undefined) {
      return 0;
    }
    let n = 0;
    for (const s of d.sections) {
      n += s.theory.length;
    }
    return n;
  }

  // 关键词命中的考点明细（最多 60 条，避免长列表卡顿）
  private hitItems(): SearchHit[] {
    const kw = this.keyword.trim();
    const out: SearchHit[] = [];
    if (kw === '') {
      return out;
    }
    for (const d of KP_DOCS) {
      for (const s of d.sections) {
        for (const it of s.skill) {
          if (it.includes(kw) && out.length < 60) {
            out.push({ docName: d.funcName, levelName: d.levelName, section: s.title, text: it });
          }
        }
        for (const it of s.theory) {
          if (it.includes(kw) && out.length < 60) {
            out.push({ docName: d.funcName, levelName: d.levelName, section: s.title, text: it });
          }
        }
      }
    }
    return out;
  }

  // 关键词命中的分类数
  private hitDocCount(): number {
    const kw = this.keyword.trim();
    if (kw === '') {
      return 0;
    }
    let n = 0;
    for (const d of KP_DOCS) {
      if (d.funcName.includes(kw) || d.subtitle.includes(kw)) {
        n += 1;
        continue;
      }
      let hit = false;
      for (const s of d.sections) {
        if (hit) {
          break;
        }
        if (s.title.includes(kw) || s.no.includes(kw)) {
          hit = true;
          break;
        }
        for (const it of s.skill) {
          if (it.includes(kw)) {
            hit = true;
            break;
          }
        }
        if (hit) {
          break;
        }
        for (const it of s.theory) {
          if (it.includes(kw)) {
            hit = true;
            break;
          }
        }
      }
      if (hit) {
        n += 1;
      }
    }
    return n;
  }

  build() {
    Column() {
      this.TopBar()
      this.SearchBox()

      // ===== 双栏主体：左分类 / 右知识点 =====
      Row() {
        this.CategoryRail()

        // 右栏
        Column() {
          if (this.keyword.trim() !== '') {
            this.SearchResultView()
          } else {
            this.RightHeader()
            this.SectionList()
          }
        }
        .layoutWeight(1)
        .height('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
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

      Text('AI知识库')
        .fontSize(20.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
        .layoutWeight(1)

      // 直接跳到政策解读，看标准原文
      Text('职业标准')
        .fontSize(13.5)
        .fontColor(PRIMARY)
        .padding({ left: 11, right: 11, top: 6, bottom: 6 })
        .borderRadius(13)
        .backgroundColor('#EAF1FF')
        .margin({ right: 16 })
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/PolicyDetailPage' });
        })
    }
    .width('100%')
    .height(58)
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: '#F1F4F9' })
  }

  // ==================== 搜索框（横跨双栏） ====================
  @Builder
  SearchBox() {
    Row() {
      Text('⌕')
        .fontSize(20.0)
        .fontColor(TEXT_SUB)
        .margin({ right: 8 })

      TextInput({ text: this.keyword, placeholder: '搜索知识点，如：消毒、睡眠、母乳喂养' })
        .placeholderColor('#9AA0AC')
        .backgroundColor(Color.Transparent)
        .padding(0)
        .fontSize(16.0)
        .layoutWeight(1)
        .onChange((v: string) => {
          this.keyword = v;
        })

      if (this.keyword !== '') {
        Text('×')
          .fontSize(21.0)
          .fontColor(TEXT_SUB)
          .padding({ left: 8, right: 4 })
          .onClick(() => {
            this.keyword = '';
          })
      }
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 14 })
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1 }, color: '#F1F4F9' })
    .alignItems(VerticalAlign.Center)
  }

  // ==================== 左栏：分类列表（分组可收起） ====================
  @Builder
  CategoryRail() {
    Scroll() {
      Column() {
        ForEach(KP_GROUPS, (g: KpGroup) => {
          this.RailGroupHeader(g)
          if (this.isGroupOpen(g.level)) {
            ForEach(g.docs, (d: KpDoc) => {
              this.RailItem(d)
            }, (d: KpDoc) => d.id)
          }
        }, (g: KpGroup) => g.level)

        Text(`共 ${KP_DOCS.length} 类 / ${this.totalPoints()} 考点`)
          .fontSize(12.0)
          .fontColor(TEXT_WEAK)
          .lineHeight(16)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 14, bottom: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width(120)
    .height('100%')
    .backgroundColor('#EFF3F9')
  }

  // 左栏分组标题（通用 / 初级 / 中级 / 高级）——点击收起或展开
  @Builder
  RailGroupHeader(g: KpGroup) {
    Column() {
      Row({ space: 6 }) {
        if (g.level === this.myLevelCode()) {
          Circle()
            .width(6)
            .height(6)
            .fill(PRIMARY)
        }
        Text(this.shortLevel(g.levelName))
          .fontSize(14.5)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isGroupOpen(g.level) ? TEXT_MAIN : '#7A8494')
          .layoutWeight(1)

        Text(this.isGroupOpen(g.level) ? '⌃' : '⌄')
          .fontSize(14.0)
          .fontColor(this.isGroupOpen(g.level) ? PRIMARY : '#AEB8C6')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(g.level === this.myLevelCode() ? '我的备考级别 · ' + g.docs.length + ' 类'
        : g.docs.length + ' 个分类')
        .fontSize(11.5)
        .fontColor(TEXT_WEAK)
        .width('100%')
        .margin({ top: 3 })
    }
    .width('100%')
    .padding({ left: 14, right: 12, top: 14, bottom: 8 })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.toggleGroup(g.level);
    })
  }

  // 左栏分类项
  @Builder
  RailItem(d: KpDoc) {
    Row() {
      Row()
        .width(3)
        .height(18)
        .borderRadius(2)
        .backgroundColor(this.openedId === d.id ? PRIMARY : Color.Transparent)
        .margin({ right: 8 })

      Text(d.funcName)
        .fontSize(15.0)
        .fontWeight(this.openedId === d.id ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.openedId === d.id ? PRIMARY : '#3F4956')
        .maxLines(2)
        .lineHeight(19)
        .textAlign(TextAlign.Start)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 9, right: 8, top: 11, bottom: 11 })
    .margin({ left: 8, right: 8, bottom: 4 })
    .borderRadius(10)
    .backgroundColor(this.openedId === d.id ? Color.White : Color.Transparent)
    .shadow(this.openedId === d.id ? { radius: 6, color: '#14000000', offsetY: 2 } : { radius: 0, color: Color.Transparent, offsetY: 0 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openedId = d.id;
    })
  }

  // ==================== 右栏头部 ====================
  @Builder
  RightHeader() {
    Column() {
      Row({ space: 8 }) {
        Text(this.docTitle())
          .fontSize(21.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .layoutWeight(1)

        Text(this.docLevel())
          .fontSize(13.5)
          .fontColor(PRIMARY)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(11)
          .backgroundColor('#EAF1FF')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.docSubtitle())
        .fontSize(14.0)
        .fontColor(TEXT_SUB)
        .lineHeight(20)
        .width('100%')
        .margin({ top: 7 })

      Row({ space: 8 }) {
        this.StatChip('小节', (this.openedDoc !== undefined ? this.openedDoc.sections.length : 0).toString())
        this.StatChip('实操考点', this.skillCount().toString())
        this.StatChip('理论考点', this.theoryCount().toString())
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 15, bottom: 15 })
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1 }, color: '#F1F4F9' })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  StatChip(label: string, value: string) {
    Row({ space: 5 }) {
      Text(value)
        .fontSize(16.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(PRIMARY)
      Text(label)
        .fontSize(13.0)
        .fontColor(TEXT_SUB)
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .borderRadius(10)
    .backgroundColor('#F0F4FE')
    .alignItems(VerticalAlign.Center)
  }

  // ==================== 右栏：小节列表 ====================
  @Builder
  SectionList() {
    Column() {
      Scroll() {
        Column() {
          ForEach(this.openedDoc !== undefined ? this.openedDoc.sections : [], (sec: KpSection) => {
            this.SectionCard(sec)
          }, (sec: KpSection, i: number) => this.openedId + '_' + sec.no + '_' + i)

          this.DetailFoot()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 18 })
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
    }
    .layoutWeight(1)
    .width('100%')

    // 底部：去 AI 伴学提问
    Row() {
      Row({ space: 7 }) {
        Text('✦')
          .fontSize(16.0)
          .fontColor(Color.White)
        Text('向 AI 提问这个知识点')
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .height(48)
      .borderRadius(24)
      .backgroundColor(PRIMARY)
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 10, color: '#333B6BF6', offsetY: 4 })
      .onClick(() => {
        // 通知首页切到「AI 伴学」页签，再退回首页
        signalPendingTab(1);
        this.getUIContext().getRouter().back();
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 14 })
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: '#F1F4F9' })
  }

  // 小节卡片：技能要求 + 知识要求
  @Builder
  SectionCard(sec: KpSection) {
    Column() {
      Row() {
        if (sec.no !== '') {
          Text(sec.no)
            .fontSize(13.5)
            .fontWeight(FontWeight.Bold)
            .fontColor(PRIMARY)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(8)
            .backgroundColor('#EAF1FF')
            .margin({ right: 9 })
        }
        Text(sec.title)
          .fontSize(17.5)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 13 })

      if (sec.skill.length > 0) {
        this.PointBlock('技能要求 · 实操考点', PRIMARY, '#EAF1FF', sec.skill)
      }
      if (sec.skill.length > 0 && sec.theory.length > 0) {
        Divider()
          .color('#F0F3F8')
          .margin({ top: 12, bottom: 13 })
      }
      if (sec.theory.length > 0) {
        this.PointBlock('知识要求 · 理论考点', '#0FA968', '#EAF9F1', sec.theory)
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: CARD_BORDER })
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  // 一组考点：标签 + 编号条目
  @Builder
  PointBlock(label: string, color: string, bg: string, items: string[]) {
    Column() {
      Text(label)
        .fontSize(13.5)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .padding({ left: 9, right: 9, top: 4, bottom: 4 })
        .borderRadius(9)
        .backgroundColor(bg)
        .margin({ bottom: 11 })

      ForEach(items, (it: string, i: number) => {
        Row() {
          Text((i + 1).toString())
            .fontSize(12.5)
            .fontWeight(FontWeight.Bold)
            .fontColor(color)
            .width(19)
            .height(19)
            .borderRadius(10)
            .backgroundColor(bg)
            .textAlign(TextAlign.Center)
            .margin({ right: 10, top: 3 })

          Text(it)
            .fontSize(16.0)
            .fontColor('#2C3542')
            .lineHeight(24)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: 10 })
      }, (it: string, i: number) => label + '_' + i)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 详情底部提示
  @Builder
  DetailFoot() {
    Row({ space: 7 }) {
      Text('✦')
        .fontSize(14.0)
        .fontColor(PRIMARY)
      Text('本分类考点已同步至 AI 伴学，可结合你的做题记录追问。')
        .fontSize(13.5)
        .fontColor(TEXT_SUB)
        .lineHeight(19)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(13)
    .borderRadius(12)
    .backgroundColor('#EFF3F9')
    .alignItems(VerticalAlign.Center)
    .margin({ top: 2 })
  }

  // ==================== 搜索结果 ====================
  @Builder
  SearchResultView() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Text(`命中 ${this.hitDocCount()} 个分类 · ${this.hitItems().length} 条考点`)
              .fontSize(14.0)
              .fontColor(TEXT_SUB)
          }
          .width('100%')
          .margin({ top: 14, bottom: 12 })

          if (this.hitItems().length === 0) {
            Column({ space: 8 }) {
              Text('没有找到相关知识点')
                .fontSize(16.5)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
              Text('换个关键词试试，或到「AI 伴学」直接提问')
                .fontSize(14.0)
                .fontColor(TEXT_SUB)
            }
            .width('100%')
            .padding({ top: 60, bottom: 60 })
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.hitItems(), (h: SearchHit, i: number) => {
              Column({ space: 7 }) {
                Row({ space: 7 }) {
                  Text(h.levelName)
                    .fontSize(12.0)
                    .fontColor(PRIMARY)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(6)
                    .backgroundColor('#EAF1FF')
                  Text(`${h.docName} · ${h.section}`)
                    .fontSize(13.5)
                    .fontColor(TEXT_SUB)
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                Text(h.text)
                  .fontSize(16.0)
                  .fontColor('#2C3542')
                  .lineHeight(23)
                  .width('100%')
              }
              .width('100%')
              .padding(14)
              .borderRadius(14)
              .backgroundColor(Color.White)
              .border({ width: 1, color: CARD_BORDER })
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 10 })
              .onClick(() => {
                this.keyword = '';
              })
            }, (h: SearchHit, i: number) => 'hititem_' + i)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 18 })
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .width('100%')
    }
    .layoutWeight(1)
    .width('100%')
  }
}
