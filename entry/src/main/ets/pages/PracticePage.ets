// 知识点练习页：首页「基础知识/专业知识」列表点击某个知识点跳入。
// 演示说明：「相关法律法规及其它试题」内置 10 道真实题目（本地即选即判，带解析）；
// 页面顶部的题号与进度条按该知识点真实题库总数（358 题）计算——演示题只是题库的一小部分。
// 做完自动生成练习报告并归档到学习数据（报告组装见 common/PracticeRecord）。
// 后端联调后：题目由后端按 kp_id 抽取，判题与解析走接口，本文件演示数据可删。
import { FavoritesStore, FavoriteItem } from '../common/FavoritesStore';
import { WrongBookStore } from '../common/WrongBookStore';
import { StudyRecordStore } from '../common/StudyRecordStore';
import { AnsweredQuestion, buildPracticeReport, archiveKnowledgePractice } from '../common/PracticeRecord';
import { PracticeReport } from '../api/PracticeApi';

interface PracticeParams {
  topicId?: number;
  topicName?: string;
}

// 演示题结构
interface LawQ {
  stem: string;
  options: string[];
  answer: string;   // 正确选项字母
  tip: string;      // 解析一句话
}

const KEYS: string[] = ['A', 'B', 'C', 'D'];

// 相关法律法规：真实题库总数（与首页列表一致，演示时题目数量与进度条按它显示）
const LAW_TOTAL: number = 358;

// 法律法规演示题（比赛演示用，平时只练这几道）
const LAW_DEMO: LawQ[] = [
  {
    stem: '《中华人民共和国未成年人保护法》规定，保障未成年人合法权益的第一责任人是（ ）。',
    options: ['父母或其他监护人', '托幼机构', '社区', '政府部门'],
    answer: 'A',
    tip: '未成年人保护法明确父母或其他监护人对未成年人的抚养、教育和保护负有第一责任。'
  },
  {
    stem: '《幼儿园工作规程》规定，正常情况下幼儿园每日户外活动时间不得少于（ ）。',
    options: ['1 小时', '2 小时', '3 小时', '4 小时'],
    answer: 'B',
    tip: '幼儿园工作规程要求正常情况下每日户外活动（含户外体育活动）不少于 2 小时，寄宿制幼儿园不少于 3 小时。'
  },
  {
    stem: '依据《托儿所幼儿园卫生保健工作规范》，3 岁以上婴幼儿每年健康检查的次数是（ ）。',
    options: ['1 次', '2 次', '3 次', '4 次'],
    answer: 'A',
    tip: '卫生保健工作规范实行"4-2-1"体检：0～1 岁每年 4 次、1～2 岁每年 2 次、3 岁以上每年 1 次。'
  },
  {
    stem: '依据《中华人民共和国食品安全法》，采购食品原料时应当查验供货者的（ ）。',
    options: ['营业执照和税务登记证', '许可证和产品合格证明', '卫生培训证书', '健康证和体检表'],
    answer: 'B',
    tip: '食品安全法规定进货查验制度：查验供货者的许可证和食品出厂检验合格证或者其他合格证明。'
  },
  {
    stem: '《中华人民共和国教师法》规定，取得幼儿园教师资格应当具备的学历是（ ）。',
    options: ['幼儿师范学校毕业', '高中毕业', '初中毕业', '任何学历均可'],
    answer: 'A',
    tip: '教师法规定取得幼儿园教师资格，应当具备幼儿师范学校毕业及其以上学历。'
  },
  {
    stem: '依据《未成年人保护法》，未成年人是指未满（ ）周岁的公民。',
    options: ['14', '16', '18', '20'],
    answer: 'C',
    tip: '未成年人保护法第二条规定：未成年人是指未满十八周岁的公民。托育、幼儿园的服务对象全部属于未成年人。'
  },
  {
    stem: '根据《托儿所幼儿园卫生保健管理办法》，婴幼儿入园（所）时应当查验的健康证明文件是（ ）。',
    options: ['出生医学证明', '儿童入园（所）健康检查表', '预防接种完成证明原件', '体格发育评价报告'],
    answer: 'B',
    tip: '管理办法规定儿童入园（所）前须经医疗卫生机构健康检查，合格后方可入园，查验的是“儿童入园（所）健康检查表”。'
  },
  {
    stem: '根据《食品安全法》，托幼机构食堂制作的食品应当（ ）。',
    options: ['每餐样品留存48小时以上，每样不少于125克', '每餐样品留存24小时以上，每样不少于100克',
      '每餐样品留存72小时以上，每样不少于150克', '无需留样，但需做好进货查验记录'],
    answer: 'A',
    tip: '每餐食品成品留样，每品种不少于125克、留存48小时以上并记录，发生食源性疾病时才能追溯。'
  },
  {
    stem: '依据《托育机构保育指导大纲（试行）》，托育机构保育工作应遵循的基本原则中，不包括以下哪项？（ ）',
    options: ['尊重儿童', '安全健康', '积极回应', '提前教学'],
    answer: 'D',
    tip: '大纲规定尊重儿童、安全健康、积极回应、科学规范四项原则。“提前教学”违背婴幼儿成长规律。'
  },
  {
    stem: '《未成年人保护法》确立的强制报告制度要求，密切接触未成年人的单位及其工作人员发现未成年人身心健康受到侵害时，应当（ ）。',
    options: ['立即向公安、民政、教育等有关部门报告', '先在单位内部处理，必要时再上报',
      '只通知家长，由家长自行处理', '等待有关部门调查后再配合提供情况'],
    answer: 'A',
    tip: '强制报告制度要求相关单位和人员立即向公安、民政、教育等部门报告，不得隐瞒、拖延。'
  }
];

@Entry
@ComponentV2
struct Practice {
  @Local pageTitle: string = '知识点练习';
  @Local topicId: number = 0;
  @Local isLaw: boolean = false;         // 是否为法律法规知识点（内置演示题）
  @Local cur: number = 0;                // 当前演示题下标
  @Local picks: string[] = [];           // 每道演示题的作答
  @Local done: boolean = false;          // 演示题全部做完
  @Local starred: boolean = false;       // 当前题收藏状态

  private startTime: number = 0;          // 本轮开始时间，用于报告里的练习时长
  private openingReport: boolean = false; // 防止连点重复提交/重复归档

  // 演示题稳定 ID：law_1 ~ law_10（错题本/收藏共用）
  private qid(i: number): string {
    return 'law_' + (i + 1).toString();
  }

  private plans: string[] = [
    '按知识点分类刷题',
    '题目由后端题库按 kp_id 抽取',
    '作答后即时判题并展示解析',
    '练完自动生成练习报告'
  ];

  async aboutToAppear(): Promise<void> {
    const params = this.getUIContext().getRouter().getParams() as PracticeParams | undefined;
    if (params !== undefined) {
      if (params.topicId !== undefined) {
        this.topicId = params.topicId;
      }
      if (params.topicName !== undefined && params.topicName !== '') {
        this.pageTitle = params.topicName;
      }
    }
    // 相关法律法规 → 进入演示答题模式
    this.isLaw = this.pageTitle.indexOf('法律法规') >= 0;
    if (this.isLaw) {
      this.picks = LAW_DEMO.map((): string => '');
      this.startTime = Date.now();
      const ctx = this.getUIContext().getHostContext();
      if (ctx !== undefined) {
        await FavoritesStore.init(ctx);
        await WrongBookStore.init(ctx);
        await StudyRecordStore.init(ctx);
      }
      this.refreshStar();
    }
  }

  // 当前题是否已判定
  private judged(): boolean {
    return this.isLaw && this.picks[this.cur] !== undefined && this.picks[this.cur] !== '';
  }

  private isLast(): boolean {
    return this.cur === LAW_DEMO.length - 1;
  }

  // 本轮答对题数
  private correctCount(): number {
    let n = 0;
    for (let i = 0; i < LAW_DEMO.length; i++) {
      if (this.picks[i] === LAW_DEMO[i].answer) {
        n++;
      }
    }
    return n;
  }

  private pick(key: string): void {
    if (this.judged() || this.done) {
      return;
    }
    this.picks[this.cur] = key;
  }

  private async onNext(): Promise<void> {
    if (this.picks[this.cur] === undefined || this.picks[this.cur] === '') {
      this.toast('请先选择答案');
      return;
    }
    // 离开本题前终判：最终答案错误 → 静默写入错题本（await 保证落库后再离开）
    if (this.picks[this.cur] !== LAW_DEMO[this.cur].answer) {
      await WrongBookStore.markWrong(this.qid(this.cur), LAW_DEMO[this.cur].stem,
        LAW_DEMO[this.cur].options.slice(), KEYS.indexOf(LAW_DEMO[this.cur].answer),
        '相关法律法规及其它试题', 'practice');
    }
    if (this.isLast()) {
      this.done = true;
      await this.openReport();
    } else {
      this.cur++;
      this.refreshStar();
    }
  }

  // 完成后生成练习报告：先归档到学习数据，再用报告页替换当前页（返回直达首页）
  private async openReport(): Promise<void> {
    if (this.openingReport) {
      return;
    }
    this.openingReport = true;

    const answers: AnsweredQuestion[] = [];
    for (let i = 0; i < LAW_DEMO.length; i++) {
      const q: LawQ = LAW_DEMO[i];
      answers.push({
        questionId: this.qid(i),
        userAnswer: this.picks[i] === undefined ? '' : this.picks[i],
        correctOption: q.answer,
        knowledgePoint: '相关法律法规及其它试题'
      });
    }
    const itemName: string = this.pageTitle !== '' ? this.pageTitle : '相关法律法规及其它试题';
    const duration: number = Math.max(1, Math.floor((Date.now() - this.startTime) / 1000));
    const report: PracticeReport = buildPracticeReport('kp-basic-law', itemName,
      '基础知识 · 单选练习', answers, duration);

    try {
      await archiveKnowledgePractice(report);
    } catch (err) {
      // 学习数据归档失败不阻断报告展示
    }

    this.getUIContext().getRouter().replaceUrl({
      url: 'pages/PracticeReportPage',
      params: { itemId: report.itemId, itemName: report.itemName, report: report }
    });
  }

  // ===== 收藏星标 =====
  private refreshStar(): void {
    this.starred = this.isLaw && FavoritesStore.isFavorited(this.qid(this.cur));
  }

  private async toggleStar(): Promise<void> {
    const q = LAW_DEMO[this.cur];
    if (q === undefined) {
      return;
    }
    const id = this.qid(this.cur);
    if (this.starred) {
      await FavoritesStore.remove(id);
      this.starred = false;
      this.toast('已取消收藏');
    } else {
      const item: FavoriteItem = {
        questionId: id,
        stem: q.stem,
        options: q.options.slice(),
        answer: KEYS.indexOf(q.answer),
        knowledgePoint: '相关法律法规及其它试题',
        source: 'practice',
        favoritedAt: Date.now()
      };
      await FavoritesStore.add(item);
      this.starred = true;
      this.toast('已加入收藏');
    }
  }

  private prev(): void {
    if (this.done) {
      this.done = false;   // 完成页回退到最后一题
      return;
    }
    if (this.cur > 0) {
      this.cur--;
    }
  }

  // 进度条宽度：按真实题库总数计算（演示题号/358）
  private progressPct(): number {
    return (this.cur + 1) / LAW_TOTAL * 100;
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
  }

  build() {
    Column() {
      // 顶部返回栏
      Row() {
        Text('‹')
          .fontSize(34.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#55402F')
          .padding({ left: 16, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text(this.pageTitle)
          .fontSize(18.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.isLaw) {
          // 收藏星标
          Text(this.starred ? '★' : '☆')
            .fontSize(24.0)
            .fontColor(this.starred ? '#FBDE71' : '#B5A98D')
            .padding({ left: 2, right: 2 })
            .onClick(() => {
              this.toggleStar();
            })

          Text((this.cur + 1).toString() + '/' + LAW_TOTAL.toString())
            .fontSize(14.0)
            .fontColor('#9A8A6E')
            .padding({ right: 16 })
        } else {
          Blank().width(16)
        }
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F2ECD8' })

      if (this.isLaw) {
        this.QuizView()
      } else {
        this.PlaceholderView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDED')
  }

  // ==================== 演示答题视图（法律法规） ====================
  // 注意：Scroll 内容默认垂直居中，必须显式 .align(Alignment.Top) 顶对齐
  @Builder
  QuizView() {
    Column() {
      // 进度条（按真实题库总数 358 计算）
      Stack({ alignContent: Alignment.Start }) {
        Row().width('100%').height(4).borderRadius(2).backgroundColor('#FEF8E3')
        Row()
          .width(this.progressPct() + '%')
          .height(4)
          .borderRadius(2)
          .backgroundColor('#FBDE71')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })

      Scroll() {
        Column() {
          if (this.done) {
            this.DoneCard()
          } else {
            // 题干卡
            Column({ space: 10 }) {
              Text('相关法律法规及其它试题')
                .fontSize(12.0)
                .fontColor('#E4842A')
                .backgroundColor('#FEF8E3')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .borderRadius(6)

              Text(LAW_DEMO[this.cur].stem)
                .fontSize(17.5)
                .fontWeight(FontWeight.Medium)
                .fontColor('#55402F')
                .lineHeight(26)
            }
            .width('100%')
            .padding(16)
            .borderRadius(16)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#F2ECD8' })
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 12 })

            // 选项列表
            ForEach(LAW_DEMO[this.cur].options, (opt: string, i: number) => {
              this.OptionRow(opt, i)
            }, (opt: string, i: number) => this.cur.toString() + '-' + i.toString() + '-' + opt)

            // 解析（作答后出现）
            if (this.judged()) {
              this.AnalysisCard()
            }
          }
        }
        .padding({ left: 16, right: 16, bottom: 20 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)

      // 底部按钮：上一题 / 下一题 各占一半
      Row({ space: 12 }) {
        Button('上一题')
          .layoutWeight(1)
          .height(48)
          .fontSize(17.0)
          .type(ButtonType.Capsule)
          .backgroundColor(Color.White)
          .fontColor(this.cur === 0 && !this.done ? '#9A8A6E' : '#55402F')
          .border({ width: 1, color: '#F2ECD8' })
          .enabled(this.cur > 0 || this.done)
          .onClick(() => {
            this.prev();
          })

        Button(this.done ? '已完成' : (this.isLast() ? '完成练习' : '下一题'))
          .layoutWeight(1)
          .height(48)
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .type(ButtonType.Capsule)
          .backgroundColor(this.picks[this.cur] === undefined || this.picks[this.cur] === '' ? '#FEF8E3' : '#FBDE71')
          .fontColor(this.picks[this.cur] === undefined || this.picks[this.cur] === '' ? '#9A8A6E' : '#8A7A50')
          .enabled(!this.done)
          .onClick(() => {
            this.onNext();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#F2ECD8' })
    }
    .width('100%')
    .layoutWeight(1) // 占返回栏以外剩余高度；height('100%') 会把底栏挤出屏幕
  }

  @Builder
  OptionRow(opt: string, i: number) {
    Row({ space: 12 }) {
      // 圆圈字母（参考题库答题页样式）
      if (this.judged() && KEYS[i] === LAW_DEMO[this.cur].answer) {
        // 正确项：绿色圆圈白对勾
        Text('✓')
          .fontSize(16.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#8A7A50')
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor('#2E9E63')
      } else if (this.judged() && this.picks[this.cur] === KEYS[i]) {
        // 选错的项：红色圆圈白字母
        Text(KEYS[i])
          .fontSize(15.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#8A7A50')
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor('#D9534F')
      } else {
        Text(KEYS[i])
          .fontSize(15.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(!this.judged() && this.picks[this.cur] === KEYS[i] ? '#FFFFFF' : '#9A8A6E')
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor(!this.judged() && this.picks[this.cur] === KEYS[i] ? '#FBDE71' : '#FFFFFF')
          .border({ width: 1.5, color: !this.judged() && this.picks[this.cur] === KEYS[i] ? '#FBDE71' : '#FEF8E3' })
      }

      Text(opt)
        .fontSize(15.5)
        .fontColor('#55402F')
        .lineHeight(21)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(13)
    .borderRadius(14)
    .backgroundColor(this.judged() && KEYS[i] === LAW_DEMO[this.cur].answer ? '#F0F6EC'
      : (this.judged() && this.picks[this.cur] === KEYS[i] ? '#FDF3DC' : Color.White))
    .border({
      width: 1.5,
      color: this.judged() && KEYS[i] === LAW_DEMO[this.cur].answer ? '#F0F6EC'
        : (this.judged() && this.picks[this.cur] === KEYS[i] ? '#FEF8E3' : '#F2ECD8')
    })
    .margin({ bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.pick(KEYS[i]);
    })
  }

  // 单题解析卡：正确答案/我的作答 + 印章 + 解析文字
  @Builder
  AnalysisCard() {
    Column() {
      Row({ space: 6 }) {
        Text('正确答案：')
          .fontSize(15.0)
          .fontColor('#9A8A6E')

        Text(LAW_DEMO[this.cur].answer)
          .fontSize(19.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2E9E63')

        Text('你的答案：')
          .fontSize(15.0)
          .fontColor('#9A8A6E')
          .margin({ left: 14 })

        Text(this.picks[this.cur])
          .fontSize(19.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.picks[this.cur] === LAW_DEMO[this.cur].answer ? '#2E9E63' : '#D9534F')

        Blank()
      }
      .width('100%')
      .padding({ top: 14, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Divider().color('#F8F4E8').strokeWidth(1)

      Text('解析：' + LAW_DEMO[this.cur].tip)
        .fontSize(14.5)
        .fontColor('#55402F')
        .lineHeight(21)
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#F2ECD8' })
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 4 })
  }

  // 完成卡：演示题做完
  @Builder
  DoneCard() {
    Column({ space: 14 }) {
      Text('本轮练习完成')
        .fontSize(20.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#55402F')

      Text('答对 ' + this.correctCount().toString() + ' / ' + LAW_DEMO.length.toString() + ' 题')
        .fontSize(17.0)
        .fontWeight(FontWeight.Medium)
        .fontColor('#E4842A')

      Text('完成本知识点全部 ' + LAW_TOTAL.toString() + ' 题需继续练习，题目会按掌握度智能推送。')
        .fontSize(14.0)
        .fontColor('#9A8A6E')
        .lineHeight(21)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 32, bottom: 32 })
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#F2ECD8' })
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== 占位视图（其它知识点） ====================
  @Builder
  PlaceholderView() {
    Column() {
      Column() {
        Text('🚧')
          .fontSize(41.0)
      }
      .width(84)
      .height(84)
      .borderRadius(42)
      .backgroundColor('#FEF8E3')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 16 })

      Text('功能开发中')
        .fontSize(18.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#55402F')
        .margin({ bottom: 8 })

      Text('本页为占位页面，路由与入口都已接通，功能开发完成后替换此文件内容即可。')
        .fontSize(14.0)
        .fontColor('#9A8A6E')
        .lineHeight(21)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      Column() {
        Text('本页规划内容')
          .fontSize(14.5)
          .fontWeight(FontWeight.Bold)
          .fontColor('#55402F')
          .width('100%')
          .margin({ bottom: 12 })

        ForEach(this.plans, (item: string, i: number) => {
          Row() {
            Text('•')
              .fontSize(14.0)
              .fontColor('#E4842A')
              .margin({ right: 8 })
            Text(item)
              .fontSize(14.0)
              .fontColor('#55402F')
              .lineHeight(20)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .margin({ bottom: 9 })
        }, (item: string, i: number) => item + '_' + i)
      }
      .width('100%')
      .padding(16)
      .borderRadius(14)
      .backgroundColor(Color.White)
      .border({ width: 1, color: '#F2ECD8' })
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 14 })

      if (this.topicId > 0) {
        Text('已收到知识点 ID：' + this.topicId)
          .fontSize(13.0)
          .fontColor('#9A8A6E')
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 20, right: 20, top: 48 })
    .justifyContent(FlexAlign.Start)
  }
}
