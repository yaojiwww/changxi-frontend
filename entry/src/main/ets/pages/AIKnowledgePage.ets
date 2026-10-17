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
const PRIMARY: string = '#FBDE71';
const ACCENT: string = '#E4842A';
const TEXT_MAIN: string = '#55402F';
const TEXT_SUB: string = '#9A8A6E';
const TEXT_WEAK: string = '#B5A98D';
const CARD_BORDER: string = '#FEF8E3';

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
    // 左栏默认全部收起，由用户自己展开
    this.expandedGroups = [];
    // 初始不选中任何分类，右侧显示「选择分类」提示
    this.openedId = '';
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
          } else if (this.openedId === '') {
            this.EmptyHint()
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
    .backgroundColor('#FDFDED')
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
        .fontColor(ACCENT)
        .padding({ left: 11, right: 11, top: 6, bottom: 6 })
        .borderRadius(13)
        .backgroundColor('#FEF8E3')
        .margin({ right: 16 })
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/PolicyDetailPage' });
        })
    }
    .width('100%')
    .height(58)
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: '#F2ECD8' })
  }

  // ==================== 搜索框（横跨双栏） ====================
  @Builder
  SearchBox() {
    Row() {
      Text('⌕')
        .fontSize(20.0)
        .fontColor(TEXT_SUB)
        .margin({ right: 8 })

      TextInput({ text: $$this.keyword, placeholder: '搜索知识点，如：消毒、睡眠、母乳喂养' })
        .placeholderColor('#B5A98D')
        .backgroundColor(Color.Transparent)
        .padding(0)
        .fontSize(16.0)
        .layoutWeight(1)

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
    .border({ width: { bottom: 1 }, color: '#F2ECD8' })
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
      }
      .width('100%')
      .padding({ top: 4 })
      .alignItems(HorizontalAlign.Start)
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.TopStart)
    .width(132)
    .height('100%')
    .backgroundColor(Color.White)
    .border({ width: { right: 1 }, color: '#F2ECD8' })
  }

  // 左栏分组标题（通用 / 初级 / 中级 / 高级）——点击收起或展开
  @Builder
  RailGroupHeader(g: KpGroup) {
    Row({ space: 7 }) {
      Text(this.shortLevel(g.levelName))
        .fontSize(15.0)
        .fontWeight(this.isGroupOpen(g.level) ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.isGroupOpen(g.level) ? TEXT_MAIN : '#8A7A5E')
        .layoutWeight(1)

      Text(this.isGroupOpen(g.level) ? '⌃' : '⌄')
        .fontSize(13.0)
        .fontColor(TEXT_WEAK)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 16, bottom: 16 })
    .alignItems(VerticalAlign.Center)
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
        .fontSize(13.5)
        .fontWeight(this.openedId === d.id ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.openedId === d.id ? ACCENT : '#55402F')
        .maxLines(2)
        .lineHeight(18)
        .textAlign(TextAlign.Start)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 10, right: 8, top: 10, bottom: 10 })
    .margin({ left: 6, right: 6, bottom: 3 })
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
          .fontSize(12.5)
          .fontColor(ACCENT)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.docSubtitle())
        .fontSize(14.0)
        .fontColor(TEXT_SUB)
        .lineHeight(20)
        .width('100%')
        .margin({ top: 7 })

      Text((this.openedDoc !== undefined ? this.openedDoc.sections.length : 0) + ' 小节 · '
        + this.skillCount() + ' 实操考点 · ' + this.theoryCount() + ' 理论考点')
        .fontSize(12.5)
        .fontColor(TEXT_SUB)
        .width('100%')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 13 })
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1 }, color: '#F2ECD8' })
    .alignItems(HorizontalAlign.Start)
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
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 24 })
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
      Text('向 AI 提问这个知识点')
        .fontSize(14.5)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8A7A50')
        .height(42)
        .padding({ left: 26, right: 26 })
        .borderRadius(21)
        .backgroundColor(PRIMARY)
        .textAlign(TextAlign.Center)
        .shadow({ radius: 10, color: '#14000000', offsetY: 4 })
        .onClick(() => {
          // 通知首页切到「AI 伴学」页签，再退回首页
          signalPendingTab(1);
          this.getUIContext().getRouter().back();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 14 })
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: '#F2ECD8' })
  }

  // 小节卡片：技能要求 + 知识要求
  @Builder
  SectionCard(sec: KpSection) {
    Column() {
      Row() {
        if (sec.no !== '') {
          Text(sec.no)
            .fontSize(14.0)
            .fontWeight(FontWeight.Bold)
            .fontColor(ACCENT)
            .margin({ right: 9 })
        }
        Text(sec.title)
          .fontSize(16.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      if (sec.skill.length > 0) {
        this.PointBlock('技能要求 · 实操考点', sec.skill)
      }
      if (sec.skill.length > 0 && sec.theory.length > 0) {
        Divider()
          .color('#F2ECD8')
          .margin({ top: 13, bottom: 14 })
      }
      if (sec.theory.length > 0) {
        this.PointBlock('知识要求 · 理论考点', sec.theory)
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

  // 一组考点：纯文字小标题 + 编号条目（不再使用彩色标签底，减少花哨感）
  @Builder
  PointBlock(label: string, items: string[]) {
    Column() {
      Text(label)
        .fontSize(12.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_SUB)
        .letterSpacing(1)
        .margin({ bottom: 10 })

      ForEach(items, (it: string, i: number) => {
        Row() {
          Text((i + 1).toString() + '.')
            .fontSize(12.5)
            .fontColor(TEXT_WEAK)
            .margin({ right: 8, top: 2 })

          Text(it)
            .fontSize(14.5)
            .fontColor('#55402F')
            .lineHeight(21)
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

  // ==================== 右栏：未选分类时的提示 ====================
  @Builder
  EmptyHint() {
    Column({ space: 8 }) {
      Text('选择左侧分类')
        .fontSize(16.0)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_MAIN)
      Text('展开级别后点选分类，查看考点')
        .fontSize(13.0)
        .fontColor(TEXT_SUB)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
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
                    .fontWeight(FontWeight.Bold)
                    .fontColor(ACCENT)
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
                  .fontColor('#55402F')
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
