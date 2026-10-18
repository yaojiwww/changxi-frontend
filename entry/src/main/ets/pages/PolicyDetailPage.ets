import { POLICY_META, POLICY_CHAPTERS, PolicyChapter } from '../common/PolicyData';

// 统一配色（与全局蓝色扁平风一致）
const PRIMARY: string = '#FBDE71';
const ACCENT: string = '#E4842A';
const TEXT_MAIN: string = '#55402F';
const TEXT_SUB: string = '#9A8A6E';
const TEXT_WEAK: string = '#B5A98D';
const CARD_BORDER: string = '#FEF8E3';

// 解析后的正文块
interface PolicyBlock {
  kind: string;      // 'chapter' | 'para' | 'bullet' | 'keyval' | 'note' | 'table'
  text: string;      // para / bullet / keyval 的内容（keyval 为「值」，键在 key 里）
  key: string;       // keyval 的键
  cells: string[];   // table 的一行单元格
  head: boolean;     // table 首行（表头）
}

@Entry
@ComponentV2
struct PolicyDetail {
  @Local pageTitle: string = '政策解读';
  // 默认展开的章节：第一章
  @Local expanded: string[] = ['c1'];

  private isOpen(id: string): boolean {
    return this.expanded.includes(id);
  }

  private toggle(id: string): void {
    if (this.isOpen(id)) {
      this.expanded = this.expanded.filter((x: string) => x !== id);
    } else {
      const next: string[] = this.expanded.slice();
      next.push(id);
      this.expanded = next;
    }
  }

  private expandAll(): void {
    if (this.expanded.length === POLICY_CHAPTERS.length) {
      this.expanded = [];
    } else {
      const all: string[] = [];
      for (const c of POLICY_CHAPTERS) {
        all.push(c.id);
      }
      this.expanded = all;
    }
  }

  // 把一行原文解析成块
  private parse(line: string, isHeadRow: boolean): PolicyBlock {
    if (line.startsWith('#')) {
      return { kind: 'chapter', text: line.substring(1), key: '', cells: [], head: false };
    }
    if (line.startsWith('~')) {
      const raw = line.substring(1);
      const i = raw.indexOf('：');
      if (i > 0) {
        return { kind: 'keyval', key: raw.substring(0, i), text: raw.substring(i + 1), cells: [], head: false };
      }
      return { kind: 'para', text: raw, key: '', cells: [], head: false };
    }
    if (line.startsWith('-')) {
      return { kind: 'bullet', text: line.substring(1), key: '', cells: [], head: false };
    }
    if (line.startsWith('!')) {
      return { kind: 'note', text: line.substring(1), key: '', cells: [], head: false };
    }
    if (line.startsWith('|')) {
      const cells = line.substring(1).split('|');
      return { kind: 'table', text: '', key: '', cells: cells, head: isHeadRow };
    }
    return { kind: 'para', text: line, key: '', cells: [], head: false };
  }

  // 解析整章正文（表格第一行当表头）
  private blocksOf(body: string[]): PolicyBlock[] {
    const out: PolicyBlock[] = [];
    let headUsed: boolean = false;
    for (const line of body) {
      const b = this.parse(line, !headUsed);
      if (b.kind === 'table' && !headUsed) {
        headUsed = true;
      }
      out.push(b);
    }
    return out;
  }

  build() {
    Column() {
      this.TopBar()

      Scroll() {
        Column() {
          this.HeroCard()

          ForEach(POLICY_CHAPTERS, (c: PolicyChapter) => {
            this.ChapterCard(c)
          }, (c: PolicyChapter) => c.id)

          Text('内容摘自《保育师国家职业技能标准（2021年版）》原文，仅作备考参考。')
            .fontSize(13.5)
            .fontColor(TEXT_WEAK)
            .lineHeight(20)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 6, bottom: 20 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14 })
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .width('100%')
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

      Text(this.pageTitle)
        .fontSize(20.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
        .layoutWeight(1)

      Text(this.expanded.length === POLICY_CHAPTERS.length ? '全部收起' : '全部展开')
        .fontSize(14.0)
        .fontColor(PRIMARY)
        .padding({ left: 12, right: 12, top: 7, bottom: 7 })
        .borderRadius(15)
        .backgroundColor('#FEF8E3')
        .margin({ right: 16 })
        .onClick(() => {
          this.expandAll();
        })
    }
    .width('100%')
    .height(58)
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: '#F2ECD8' })
  }

  // ==================== 标准概况卡 ====================
  @Builder
  HeroCard() {
    Column() {
      Row({ space: 8 }) {
        Text('国家职业技能标准')
          .fontSize(13.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(PRIMARY)
          .padding({ left: 9, right: 9, top: 4, bottom: 4 })
          .borderRadius(9)
          .backgroundColor('#FEF8E3')

        Text('2021 年版')
          .fontSize(13.0)
          .fontColor('#9A8A6E')
          .padding({ left: 9, right: 9, top: 4, bottom: 4 })
          .borderRadius(9)
          .backgroundColor('#FFFFFF')
      }
      .width('100%')

      Text('保育师国家职业技能标准')
        .fontSize(24.0)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
        .width('100%')
        .margin({ top: 12 })

      ForEach(POLICY_META, (m: string, i: number) => {
        Row({ space: 7 }) {
          Circle()
            .width(4)
            .height(4)
            .fill(i === 0 ? PRIMARY : '#FEF8E3')
            .margin({ top: 7 })
          Text(m)
            .fontSize(14.5)
            .fontColor('#55402F')
            .lineHeight(21)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .margin({ top: i === 0 ? 10 : 6 })
      }, (m: string, i: number) => 'meta_' + i)
    }
    .width('100%')
    .padding(18)
    .borderRadius(18)
    .backgroundColor('#FEF8E3')
    .border({ width: 1, color: '#FEF8E3' })
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
  }

  // ==================== 章节卡（可展开） ====================
  @Builder
  ChapterCard(c: PolicyChapter) {
    Column() {
      // 章节标题行（点击展开/收起）
      Row({ space: 10 }) {
        Text(c.no)
          .fontSize(14.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#8A7A50')
          .width(26)
          .height(26)
          .borderRadius(13)
          .backgroundColor(this.isOpen(c.id) ? PRIMARY : '#FEF8E3')
          .textAlign(TextAlign.Center)

        Column({ space: 3 }) {
          Text(c.title)
            .fontSize(17.5)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
            .width('100%')
          Text(c.tag)
            .fontSize(13.0)
            .fontColor(TEXT_WEAK)
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.isOpen(c.id) ? '⌃' : '⌄')
          .fontSize(17.0)
          .fontColor(this.isOpen(c.id) ? PRIMARY : '#B5A98D')
          .padding({ left: 6, right: 2 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 15, bottom: 15 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.toggle(c.id);
      })

      if (this.isOpen(c.id)) {
        Divider().color('#F8F4E8')

        Column() {
          ForEach(this.blocksOf(c.body), (b: PolicyBlock, i: number) => {
            this.BlockView(b)
          }, (b: PolicyBlock, i: number) => c.id + '_' + i)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: CARD_BORDER })
    .clip(true)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  // 单个内容块
  @Builder
  BlockView(b: PolicyBlock) {
    if (b.kind === 'chapter') {
      Row({ space: 7 }) {
        Row()
          .width(3)
          .height(15)
          .borderRadius(2)
          .backgroundColor(PRIMARY)
        Text(b.text)
          .fontSize(16.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 6, bottom: 10 })
    } else if (b.kind === 'bullet') {
      Row({ space: 9 }) {
        Text('•')
          .fontSize(16.0)
          .fontColor(PRIMARY)
          .margin({ top: 4 })
        Text(b.text)
          .fontSize(15.5)
          .fontColor('#55402F')
          .lineHeight(24)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ bottom: 9 })
    } else if (b.kind === 'keyval') {
      Row({ space: 10 }) {
        Text(b.key)
          .fontSize(14.5)
          .fontWeight(FontWeight.Bold)
          .fontColor(PRIMARY)
          .width(96)
          .lineHeight(23)
        Text(b.text)
          .fontSize(15.5)
          .fontColor('#55402F')
          .lineHeight(23)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .border({ width: { bottom: 1 }, color: '#F2ECD8' })
      .alignItems(VerticalAlign.Top)
    } else if (b.kind === 'note') {
      Row({ space: 8 }) {
        Text('!')
          .fontSize(14.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(PRIMARY)
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor('#FEF8E3')
          .textAlign(TextAlign.Center)
          .margin({ top: 2 })
        Text(b.text)
          .fontSize(15.0)
          .fontColor('#55402F')
          .lineHeight(23)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 11, bottom: 11 })
      .borderRadius(12)
      .backgroundColor('#FEF8E3')
      .alignItems(VerticalAlign.Top)
      .margin({ top: 4, bottom: 4 })
    } else if (b.kind === 'table') {
      Row() {
        ForEach(b.cells, (cell: string, ci: number) => {
          Text(cell)
            .fontSize(b.head ? 12.5 : 13)
            .fontWeight(b.head ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(b.head ? '#8A7A50' : (ci === 0 ? TEXT_MAIN : ACCENT))
            .textAlign(ci === 0 ? TextAlign.Start : TextAlign.Center)
            .layoutWeight(ci === 0 ? 1.5 : 1)
            .padding({ left: ci === 0 ? 8 : 2, right: 4, top: 9, bottom: 9 })
        }, (cell: string, ci: number) => 'cell_' + ci)
      }
      .width('100%')
      .backgroundColor(b.head ? PRIMARY : (b.cells.length > 1 && b.cells[0] === '合计' ? '#FEF8E3' : Color.White))
      .border({ width: { bottom: 1 }, color: '#FEF8E3' })
      .alignItems(VerticalAlign.Center)
    } else {
      Text(b.text)
        .fontSize(15.5)
        .fontColor('#55402F')
        .lineHeight(24)
        .width('100%')
        .margin({ top: 2, bottom: 10 })
    }
  }
}
