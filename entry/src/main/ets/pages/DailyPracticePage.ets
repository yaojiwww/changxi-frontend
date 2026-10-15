import { Http, ApiResponse, CODE_OK } from '../common/Http';
import { TokenStore } from '../common/TokenStore';
import { signalPendingTab } from '../common/NavSignal';
import { FavoritesStore, FavoriteItem } from '../common/FavoritesStore';
import { WrongBookStore } from '../common/WrongBookStore';
import { StudyRecordStore, StudyRecord } from '../common/StudyRecordStore';

// ====== 接口结构（与 docs/api_spec.md #18 / #19 一致） ======

// #18 GET /practice/daily 的 data
interface DailyData {
  date: string;
  practiceId: string;
  questions: DailyQuestionItem[];
}
interface DailyQuestionItem {
  questionId: string;
  stem: string;
  options: string[];
  knowledgePoint: string;
}

// #17/#19 练习报告 data（完整练习报告）
interface PracticeReportData {
  itemId: string;
  itemName: string;
  practiceType: string;
  submitTime: string;
  correctCount: number;
  total: number;
  accuracy: number | null;
  duration: number;
  compare: ReportCompare | null;
  answerCard: AnswerCardItem[];
  mastery: MasteryItem[];
}
interface ReportCompare {
  lastAccuracy: number | null;
  deltaVsLast: number | null;
  deltaVsPassLine: number | null;
}
interface AnswerCardItem {
  questionId: string;
  correct: boolean;
  userAnswer: string;
  correctOption: string;
}
interface MasteryItem {
  knowledgePoint: string;
  correct: number;
  total: number;
  accuracy: number;
}

// #19 请求体数组元素
interface AnswerItem {
  questionId: string;
  userAnswer: string;
}

// 本地演示题（后端未连接时的兜底，正式联调后可删）
interface DemoQuestion {
  questionId: string;
  stem: string;
  options: string[];
  answer: string;           // 正确选项字母
  knowledgePoint: string;
}
const DEMO_QUESTIONS: DemoQuestion[] = [
  {
    questionId: 'd1',
    stem: '保育师在处理与婴幼儿的关系时，首先应做到（ ）。',
    options: ['尊重与爱护婴幼儿', '严格要求纪律', '以教学成绩为先', '一切听从家长安排'],
    answer: 'A',
    knowledgePoint: '保育员职业道德与职业守则'
  },
  {
    questionId: 'd2',
    stem: '婴幼儿鼻出血时，正确的处理方法是（ ）。',
    options: ['让幼儿仰起头', '低头前倾，捏住鼻翼压迫止血', '往鼻孔里塞纸团', '立即热敷鼻部'],
    answer: 'B',
    knowledgePoint: '婴幼儿安全知识'
  },
  {
    questionId: 'd3',
    stem: '婴幼儿进餐时，保育师正确的做法是（ ）。',
    options: ['催促幼儿加快速度', '允许幼儿边吃边玩', '营造安静愉快的进餐氛围', '先喂完再让幼儿自己吃'],
    answer: 'C',
    knowledgePoint: '婴幼儿卫生保健知识'
  },
  {
    questionId: 'd4',
    stem: '使用含氯消毒剂浸泡玩具后，正确的后续处理是（ ）。',
    options: ['直接捞出晾干', '用清水冲洗干净并晾干', '再用开水烫一遍即可', '擦拭后立即让幼儿使用'],
    answer: 'B',
    knowledgePoint: '相关环境知识'
  },
  {
    questionId: 'd5',
    stem: '婴幼儿耳道进入小昆虫时，正确的做法是（ ）。',
    options: ['用手指深掏耳道', '用灯光照射引出昆虫', '立即灌水淹死昆虫', '用力拍打另一侧耳朵'],
    answer: 'B',
    knowledgePoint: '婴幼儿安全知识'
  },
  {
    questionId: 'd6',
    stem: '婴幼儿发热时，正确的物理降温方法是（ ）。',
    options: ['用酒精擦洗全身', '温水擦浴', '多穿衣服捂汗', '自行喂退烧药'],
    answer: 'B',
    knowledgePoint: '婴幼儿常见病及常见传染病防治基础知识'
  },
  {
    questionId: 'd7',
    stem: '《中华人民共和国未成年人保护法》规定，保障未成年人合法权益的第一责任人是（ ）。',
    options: ['父母或其他监护人', '托幼机构', '社区', '政府部门'],
    answer: 'A',
    knowledgePoint: '相关法律法规及其它试题'
  },
  {
    questionId: 'd8',
    stem: '婴幼儿患急性传染病痊愈后，正确的做法是（ ）。',
    options: ['立即返园继续照护', '凭医疗机构证明，隔离期满后返园', '返园后与其他幼儿同班活动', '仅需家长口头说明即可返园'],
    answer: 'B',
    knowledgePoint: '婴幼儿常见病及常见传染病防治基础知识'
  },
  {
    questionId: 'd9',
    stem: '下列预防婴幼儿走失的措施中，错误的是（ ）。',
    options: ['外出时随时清点人数', '门卫严格管理出入', '让幼儿独自外出玩耍', '交接班时核对人数'],
    answer: 'C',
    knowledgePoint: '婴幼儿安全知识'
  },
  {
    questionId: 'd10',
    stem: '使用含氯消毒剂浸泡玩具后，正确的后续处理是（ ）。',
    options: ['直接捞出晾干', '用清水冲洗干净并晾干', '再用开水烫一遍即可', '擦拭后立即让幼儿使用'],
    answer: 'B',
    knowledgePoint: '相关环境知识'
  },
  {
    questionId: 'd11',
    stem: '保育师组织幼儿户外活动前，首要的工作是（ ）。',
    options: ['先让幼儿自由奔跑', '点名后各自活动', '检查活动场地与器械是否安全', '安排幼儿比赛奔跑速度'],
    answer: 'C',
    knowledgePoint: '婴幼儿安全知识'
  },
  {
    questionId: 'd12',
    stem: '幼儿发生轻微擦伤时，保育师正确的处理顺序是（ ）。',
    options: ['直接贴上创可贴', '先用清水冲洗伤口，再用碘伏消毒', '用手揉搓伤口', '涂牙膏止血'],
    answer: 'B',
    knowledgePoint: '婴幼儿卫生保健知识'
  },
  {
    questionId: 'd13',
    stem: '幼儿把小珠子塞进鼻孔后，保育师正确的做法是（ ）。',
    options: ['用手伸进去掏出来', '让幼儿仰头等待', '喂水把异物冲下去', '不要自行取出，立即送医处理'],
    answer: 'D',
    knowledgePoint: '婴幼儿安全知识'
  },
  {
    questionId: 'd14',
    stem: '幼儿午睡时出现发热、面色潮红，保育师首先应（ ）。',
    options: ['测量体温并及时通知保健医', '让他继续睡到起床', '自行喂服退烧药', '打开风扇对着直吹'],
    answer: 'A',
    knowledgePoint: '婴幼儿常见病及常见传染病防治基础知识'
  },
  {
    questionId: 'd15',
    stem: '配制含氯消毒液擦拭桌椅时，保育师应（ ）。',
    options: ['徒手直接擦拭以提高效率', '与洁厕灵混合使用增强效果', '戴手套并在通风处配好即用', '配好后放置一周再使用'],
    answer: 'C',
    knowledgePoint: '相关环境知识'
  },
  {
    questionId: 'd16',
    stem: '组织幼儿洗手时，正确的做法是（ ）。',
    options: ['用流动水按七步洗手法搓洗', '用一盆水轮流洗', '用湿巾擦手代替洗手', '洗完后集体共用一条毛巾擦手'],
    answer: 'A',
    knowledgePoint: '婴幼儿卫生保健知识'
  },
  {
    questionId: 'd17',
    stem: '园内出现手足口病病例时，保育师应（ ）。',
    options: ['继续正常开展集体活动', '配合做好隔离消毒并加强晨午检', '自行服用抗病毒药物预防', '暂不上报以免影响园所声誉'],
    answer: 'B',
    knowledgePoint: '婴幼儿常见病及常见传染病防治基础知识'
  },
  {
    questionId: 'd18',
    stem: '幼儿活动室每天通风换气的正确做法是（ ）。',
    options: ['只要开着空调就不必通风', '等幼儿全部离园后再全天关窗', '每天通风一次、每次 5 分钟', '每天开窗通风 2 次以上、每次不少于 30 分钟'],
    answer: 'D',
    knowledgePoint: '相关环境知识'
  },
  {
    questionId: 'd19',
    stem: '为预防幼儿烫伤，保育师分餐时应（ ）。',
    options: ['把热汤放在桌边靠幼儿一侧', '让幼儿自己端汤', '先盛热汤并放在远离幼儿处，再分餐具', '把热汤放在桌子中央让幼儿传递'],
    answer: 'C',
    knowledgePoint: '婴幼儿安全知识'
  },
  {
    questionId: 'd20',
    stem: '幼儿在园突然呕吐，保育师处理呕吐物时正确的是（ ）。',
    options: ['用拖把直接拖干净', '先疏散幼儿并开窗通风，再用含氯消毒液处理', '让幼儿自己清理干净', '用干抹布擦掉即可'],
    answer: 'B',
    knowledgePoint: '婴幼儿卫生保健知识'
  },
  {
    questionId: 'd21',
    stem: '保育师给幼儿喂药时，正确的做法是（ ）。',
    options: ['按自己的经验适当加量', '把药混在饭菜里一起喂', '让幼儿自己看着说明书服用', '凭家长书面委托，按医嘱核对后喂服'],
    answer: 'D',
    knowledgePoint: '婴幼儿卫生保健知识'
  },
  {
    questionId: 'd22',
    stem: '幼儿鼻腔进入异物时，最恰当的处理是（ ）。',
    options: ['不要自行取出，立即送医', '用镊子自行夹取', '用力按压鼻梁使之排出', '让幼儿大量喝水冲下去'],
    answer: 'A',
    knowledgePoint: '婴幼儿安全知识'
  },
  {
    questionId: 'd23',
    stem: '托幼机构发现幼儿患传染病时，正确的报告要求是（ ）。',
    options: ['等园长确认后再上报', '一周内汇总上报即可', '按当地规定及时上报，不得迟报、瞒报', '无需上报，仅通知家长即可'],
    answer: 'C',
    knowledgePoint: '相关法律法规及其它试题'
  },
  {
    questionId: 'd24',
    stem: '幼儿玩具、图书的消毒要求是（ ）。',
    options: ['只在学期末消毒一次', '按材质选择清洗、消毒或暴晒等适宜方式并定期进行', '有污渍时才需要消毒', '每周用清水冲洗一次即可'],
    answer: 'B',
    knowledgePoint: '相关环境知识'
  },
  {
    questionId: 'd25',
    stem: '入园晨检中的「三问」，主要了解的是（ ）。',
    options: ['幼儿在家的饮食、睡眠、大小便及健康状况', '幼儿的学习成绩', '家长的工作单位与职务', '幼儿的兴趣爱好'],
    answer: 'A',
    knowledgePoint: '婴幼儿卫生保健知识'
  },
  {
    questionId: 'd26',
    stem: '幼儿鼻出血按压 10 分钟后仍未止住，应（ ）。',
    options: ['继续按压半小时', '让幼儿平躺休息', '塞入卫生纸后继续观察', '立即送医处理'],
    answer: 'D',
    knowledgePoint: '婴幼儿安全知识'
  },
  {
    questionId: 'd27',
    stem: '保育师使用消毒柜、电热水壶等设备时，应（ ）。',
    options: ['边照看幼儿边操作设备', '严格按操作规程使用并做好幼儿防护', '让幼儿帮助插拔电源', '把设备放在幼儿随手可及处'],
    answer: 'B',
    knowledgePoint: '相关环境知识'
  },
  {
    questionId: 'd28',
    stem: '保育师保证幼儿一日饮水时，正确的做法是（ ）。',
    options: ['只在三餐时提供水', '限制饮水以防止尿床', '随渴随喝，上下午各组织一次集体饮水并允许随时饮水', '让幼儿自己接水，保育师不作看护'],
    answer: 'C',
    knowledgePoint: '婴幼儿卫生保健知识'
  },
  {
    questionId: 'd29',
    stem: '幼儿发生惊厥（抽风）时，保育师正确的处理是（ ）。',
    options: ['就地侧卧、松开衣领并及时送医', '用力按压四肢制止抽搐', '往口中塞筷子或手指', '抱起幼儿摇晃唤醒'],
    answer: 'A',
    knowledgePoint: '婴幼儿常见病及常见传染病防治基础知识'
  },
  {
    questionId: 'd30',
    stem: '依据《幼儿园工作规程》，保育师在班级中的职责是（ ）。',
    options: ['以教学为主、保育次之', '配合教师做好保育工作，关注幼儿个体差异', '只负责室内外清洁卫生', '对所有幼儿统一要求，不作区别对待'],
    answer: 'B',
    knowledgePoint: '相关法律法规及其它试题'
  }
];

// 每日一练：演示题库按每组 10 题切分，实现「每天一套 + 再来一组」
const DEMO_SET_SIZE: number = 10;
const DEMO_SET_COUNT: number = Math.floor(DEMO_QUESTIONS.length / DEMO_SET_SIZE);

// 取第 g 组演示题（越界自动取模，循环取组）
function demoGroupQuestions(g: number): DemoQuestion[] {
  if (DEMO_SET_COUNT <= 0) {
    return DEMO_QUESTIONS.slice();
  }
  const idx = ((g % DEMO_SET_COUNT) + DEMO_SET_COUNT) % DEMO_SET_COUNT;
  return DEMO_QUESTIONS.slice(idx * DEMO_SET_SIZE, idx * DEMO_SET_SIZE + DEMO_SET_SIZE);
}

// 每题解析文字（演示模式即选即出；后端联调后由接口下发）
interface DemoTip {
  questionId: string;
  tip: string;
}
const DEMO_TIPS: DemoTip[] = [
  { questionId: 'd1', tip: '尊重与爱护婴幼儿是保育员职业道德的核心要求，是与婴幼儿建立良好关系的前提。' },
  { questionId: 'd2', tip: '鼻出血时应让幼儿低头前倾，捏住鼻翼压迫止血。仰头会让血液倒流呛入气道，塞纸团、热敷都不正确。' },
  { questionId: 'd3', tip: '进餐时营造安静愉快的氛围有利于婴幼儿消化吸收；催促、边吃边玩都会影响进食和消化。' },
  { questionId: 'd4', tip: '含氯消毒剂浸泡后必须用清水彻底冲洗干净，残留消毒剂会刺激婴幼儿皮肤和口腔黏膜。' },
  { questionId: 'd5', tip: '可利用昆虫的趋光性，用手电筒照射外耳道将其引出；掏挖、灌水都容易损伤鼓膜。' },
  { questionId: 'd6', tip: '温水擦浴是安全有效的物理降温方法；酒精擦浴易经皮肤吸收中毒，捂汗会使体温进一步升高。' },
  { questionId: 'd7', tip: '《未成年人保护法》明确：父母或者其他监护人是保障未成年人合法权益的第一责任人。' },
  { questionId: 'd8', tip: '患传染病痊愈后应凭医疗机构证明、隔离期满方可返园，避免疫情在托幼机构内传播。' },
  { questionId: 'd9', tip: '任何情况下都不能让幼儿独自外出玩耍，必须专人看护并随时清点人数。' },
  { questionId: 'd10', tip: '含氯消毒剂浸泡玩具后须用清水冲洗干净并晾干，避免消毒剂残留刺激婴幼儿皮肤。' }
];

// 答题页内的题目模型：@Trace 驱动选中态刷新
@ObservedV2
class DailyQuestion {
  questionId: string;
  stem: string;
  options: string[];
  knowledgePoint: string;
  @Trace selected: string = '';

  constructor(questionId: string, stem: string, options: string[], knowledgePoint: string) {
    this.questionId = questionId;
    this.stem = stem;
    this.options = options;
    this.knowledgePoint = knowledgePoint;
  }
}

@Entry
@ComponentV2
struct DailyPractice {
  @Local questions: DailyQuestion[] = [];
  @Local cur: number = 0;
  @Local loading: boolean = true;
  @Local submitting: boolean = false;
  @Local finished: boolean = false;
  @Local practiceId: string = '';
  @Local report: PracticeReportData | null = null;
  @Local reviewIndex: number = -1;             // 报告页点答题卡回看的题号，-1=收起
  @Local startTime: number = 0;
  @Local sheetOpen: boolean = false;           // 答题卡底部面板开关
  @Local starred: boolean = false;             // 当前题收藏状态
  @Local groupIndex: number = 0;               // 当前所在演示题组（每日一练每组 10 题）
  private demoMode: boolean = false;           // 演示模式：本地判题

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx !== undefined) {
      await FavoritesStore.init(ctx);
      await WrongBookStore.init(ctx);
      await StudyRecordStore.init(ctx);
    }
    await this.loadDaily();
  }

  // ===== 拉题：GET /practice/daily，失败降级演示题 =====
  private async loadDaily(): Promise<void> {
    this.loading = true;
    this.finished = false;
    this.report = null;
    this.reviewIndex = -1;
    this.cur = 0;
    this.sheetOpen = false;
    this.startTime = Date.now();
    this.starred = false;
    try {
      const token = await TokenStore.read();
      const res: ApiResponse<DailyData> = await Http.get<DailyData>('/practice/daily', token);
      if (res.code === CODE_OK && res.data !== null && res.data.questions.length > 0) {
        this.practiceId = res.data.practiceId;
        this.questions = res.data.questions.map((it: DailyQuestionItem): DailyQuestion => {
          return new DailyQuestion(it.questionId, it.stem, it.options, it.knowledgePoint);
        });
        this.demoMode = false;
        this.loading = false;
        this.refreshStar();
        return;
      }
    } catch (err) {
      // 网络异常走兜底
    }
      // 兜底：后端未连接 → 本地演示题（静默降级，界面不提示，演示效果与真实后端一致）
      this.demoMode = true;
    // 每天一套：当天已完成过 → 直接回看当天的学习报告，不再重复做题
    const todayReport: PracticeReportData | null = this.todayLatestReport();
    if (todayReport !== null) {
      this.groupIndex = this.groupOfReport(todayReport);
      this.questions = this.buildDemoQuestions(this.groupIndex);
      this.report = todayReport;
      this.finished = true;
      this.loading = false;
      return;
    }
    // 未完成：按当天日期取组，保证同一天进来看到的是同一套题
    this.groupIndex = this.dayGroupIndex();
    this.questions = this.buildDemoQuestions(this.groupIndex);
    this.loading = false;
    this.refreshStar();
  }

  // ===== 演示模式「每天一套」相关 =====

  // 今天日期串 YYYY-MM-DD
  private todayStr(): string {
    const d = new Date();
    const p = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    return d.getFullYear().toString() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
  }

  // 当天最新一条每日一练报告（学习记录已按时间倒序）
  private todayLatestReport(): PracticeReportData | null {
    const list: StudyRecord[] = StudyRecordStore.getAll();
    const today = this.todayStr();
    for (let i = 0; i < list.length; i++) {
      const r: StudyRecord = list[i];
      if (r.type === 'daily' && r.date.substring(0, 10) === today) {
        try {
          return JSON.parse(r.detailData) as PracticeReportData;
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  // 报告属于哪一题组：用首题 ID 在演示题库中反查（保证回看时题干与答题卡对得上）
  private groupOfReport(r: PracticeReportData): number {
    if (r.answerCard.length > 0) {
      const firstId: string = r.answerCard[0].questionId;
      for (let g = 0; g < DEMO_SET_COUNT; g++) {
        const pool: DemoQuestion[] = demoGroupQuestions(g);
        if (pool.length > 0 && pool[0].questionId === firstId) {
          return g;
        }
      }
    }
    return this.dayGroupIndex();
  }

  // 当天默认题组：按年内天数取模，同一天固定同一组，不同天自然轮换
  private dayGroupIndex(): number {
    const d = new Date();
    const start = new Date(d.getFullYear(), 0, 0);
    const dayNo: number = Math.floor((Date.now() - start.getTime()) / 86400000);
    return DEMO_SET_COUNT > 0 ? dayNo % DEMO_SET_COUNT : 0;
  }

  // 把演示题转成页面题目对象（复制选项数组，避免多组间串改）
  private buildDemoQuestions(g: number): DailyQuestion[] {
    return demoGroupQuestions(g).map((d: DemoQuestion): DailyQuestion =>
      new DailyQuestion(d.questionId, d.stem, d.options.slice(), d.knowledgePoint));
  }

  // 「再来一组」：切到下一组题（循环），清空作答、计时与报告，直接开始新的十题
  private startGroup(g: number): void {
    this.demoMode = true;
    this.questions = this.buildDemoQuestions(g);
    this.groupIndex = DEMO_SET_COUNT > 0 ? ((g % DEMO_SET_COUNT) + DEMO_SET_COUNT) % DEMO_SET_COUNT : 0;
    this.finished = false;
    this.report = null;
    this.reviewIndex = -1;
    this.cur = 0;
    this.sheetOpen = false;
    this.starred = false;
    this.startTime = Date.now();
    this.refreshStar();
  }

  private optKey(i: number): string {
    const keys: string[] = ['A', 'B', 'C', 'D'];
    return keys[i];
  }

  // ===== 选择选项（每日一练为整卷模式：只记录，不逐题判） =====
  private pick(key: string): void {
    if (this.submitting || this.finished) {
      return;
    }
    const q = this.questions[this.cur];
    if (q === undefined) {
      return;
    }
    q.selected = key;
  }

  private isLast(): boolean {
    return this.cur === this.questions.length - 1;
  }

  // 当前题是否已作答（用于底部主按钮的可用态）
  private answeredCurrent(): boolean {
    const q = this.questions[this.cur];
    return q !== undefined && q.selected !== '';
  }

  // ===== 即时解析（演示模式即选即判；后端联调后按契约交卷统一判题，届时解析在报告页回看） =====
  // 当前题正确选项字母（演示题库内查得；后端模式返回 '' 不判）
  private currentCorrectKey(): string {
    if (!this.demoMode) {
      return '';
    }
    const q = this.questions[this.cur];
    const d = DEMO_QUESTIONS.find((x: DemoQuestion): boolean => x.questionId === q.questionId);
    return d !== undefined ? d.answer : '';
  }

  // 当前题是否已出解析：可判 + 已作答
  private judged(): boolean {
    return this.demoMode && this.questions[this.cur] !== undefined
      && this.currentCorrectKey() !== '' && this.questions[this.cur].selected !== '';
  }

  // 印章颜色：答对绿 / 答错红
  private stampColor(): string {
    return this.questions[this.cur].selected === this.currentCorrectKey() ? '#0E9F6E' : '#E5484D';
  }

  // 当前题的演示统计值：同一题每次进入固定，不同题之间有差异
  private demoIdNum(): number {
    const q = this.questions[this.cur];
    const m = /\d+/.exec(q.questionId);
    return m !== null ? parseInt(m[0]) : 0;
  }

  // 统计演示值：正确率跟随用户本题作答结果（做对=100%，做错=0%）
  private statRate(): string {
    return this.questions[this.cur].selected === this.currentCorrectKey() ? '100%' : '0%';
  }

  // 当前题解析文字
  private currentTip(): string {
    const q = this.questions[this.cur];
    if (q === undefined) {
      return '';
    }
    const t = DEMO_TIPS.find((x: DemoTip): boolean => x.questionId === q.questionId);
    return t !== undefined ? t.tip : '';
  }

  private statErrorProne(): string {
    const keys: string[] = ['A', 'B', 'C', 'D'];
    let idx = (keys.indexOf(this.currentCorrectKey()) + 1 + this.demoIdNum() % 3) % 4;
    if (keys[idx] === this.currentCorrectKey()) {
      idx = (idx + 1) % 4;
    }
    return keys[idx];
  }

  // ===== 收藏星标：加入/取消收藏，实时同步「我的收藏」 =====
  // 演示模式知道正确答案（存下标）；后端模式前端不持答案，存 -1
  private correctIndexFor(q: DailyQuestion): number {
    if (!this.demoMode) {
      return -1;
    }
    const d = DEMO_QUESTIONS.find((x: DemoQuestion): boolean => x.questionId === q.questionId);
    return d !== undefined ? ['A', 'B', 'C', 'D'].indexOf(d.answer) : -1;
  }

  private refreshStar(): void {
    if (this.questions.length === 0) {
      this.starred = false;
      return;
    }
    const q = this.questions[this.cur];
    this.starred = q !== undefined && FavoritesStore.isFavorited(q.questionId);
  }

  private async toggleStar(): Promise<void> {
    const q = this.questions[this.cur];
    if (q === undefined) {
      return;
    }
    if (this.starred) {
      await FavoritesStore.remove(q.questionId);
      this.starred = false;
      this.toast('已取消收藏');
    } else {
      const item: FavoriteItem = {
        questionId: q.questionId,
        stem: q.stem,
        options: q.options.slice(),
        answer: this.correctIndexFor(q),
        knowledgePoint: q.knowledgePoint === '' ? '综合' : q.knowledgePoint,
        source: 'daily',
        favoritedAt: Date.now()
      };
      await FavoritesStore.add(item);
      this.starred = true;
      this.toast('已加入收藏');
    }
  }

  // ===== 错题本：本题最终答案错误 → 静默写入错题本（演示模式逐题判） =====
  private async recordWrongIfAny(): Promise<void> {
    if (!this.demoMode) {
      return;
    }
    const q = this.questions[this.cur];
    if (q === undefined || q.selected === '') {
      return;
    }
    const correctKey = this.currentCorrectKey();
    if (correctKey !== '' && q.selected !== correctKey) {
      await WrongBookStore.markWrong(q.questionId, q.stem, q.options.slice(),
        ['A', 'B', 'C', 'D'].indexOf(correctKey),
        q.knowledgePoint === '' ? '综合' : q.knowledgePoint, 'daily');
    }
  }

  // 后端判题后：按答题卡把错题写入错题本
  private async recordWrongFromCard(r: PracticeReportData): Promise<void> {
    for (let i = 0; i < r.answerCard.length; i++) {
      const cell = r.answerCard[i];
      if (cell.correct) {
        continue;
      }
      const q = this.questions.find((x: DailyQuestion): boolean => x.questionId === cell.questionId);
      if (q === undefined) {
        continue;
      }
      await WrongBookStore.markWrong(cell.questionId, q.stem, q.options.slice(),
        ['A', 'B', 'C', 'D'].indexOf(cell.correctOption),
        q.knowledgePoint === '' ? '综合' : q.knowledgePoint, 'daily');
    }
  }

  // ===== 学习数据归档：报告写入 StudyRecordStore，学习数据页可回看 =====
  private async archiveReport(r: PracticeReportData): Promise<void> {
    try {
      await StudyRecordStore.add({
        id: StudyRecordStore.newId(),
        type: 'daily',
        title: '每日一练',
        score: r.accuracy !== null ? `${r.accuracy}%` : `${r.correctCount}/${r.total}`,
        date: r.submitTime,
        timestamp: Date.now(),
        detailData: JSON.stringify(r)
      } as StudyRecord);
    } catch (e) {
      // 归档失败不影响报告展示
    }
  }

  private async onNext(): Promise<void> {
    const q = this.questions[this.cur];
    if (q !== undefined && q.selected === '') {
      this.toast('请先选择答案');
      return;
    }
    if (this.isLast()) {
      await this.submit();
    } else {
      await this.recordWrongIfAny();   // 离开本题前终判：最终答案错误则入错题本
      this.cur++;
      this.refreshStar();
    }
  }

  // ===== 交卷：POST /practice/daily/submit?practiceId=xxx，一次拿回完整报告 =====
  private async submit(): Promise<void> {
    this.submitting = true;
    try {
      const answers: AnswerItem[] = [];
      for (const q of this.questions) {
        const item: AnswerItem = { questionId: q.questionId, userAnswer: q.selected };
        answers.push(item);
      }

      if (this.demoMode) {
        this.report = this.buildDemoReport(answers);
        await this.archiveReport(this.report);
        this.finished = true;
        this.submitting = false;
        return;
      }

      const token = await TokenStore.read();
      const path = `/practice/daily/submit?practiceId=${this.practiceId}`;
      const res: ApiResponse<PracticeReportData> = await Http.post<PracticeReportData>(path, answers, token);
      if (res.code === CODE_OK && res.data !== null) {
        this.report = res.data;
        await this.archiveReport(this.report);
        await this.recordWrongFromCard(this.report);
        this.finished = true;
      } else {
        this.toast('提交失败：' + res.message);
      }
    } catch (err) {
      this.toast('网络异常，提交失败');
    }
    this.submitting = false;
  }

  // 演示模式本地判题并组装报告（结构与后端 #19 一致）
  private buildDemoReport(answers: AnswerItem[]): PracticeReportData {
    const card: AnswerCardItem[] = [];
    const masteryMap: Map<string, MasteryItem> = new Map<string, MasteryItem>();
    let correctCount = 0;
    const now = new Date();
    const submitTime = now.getFullYear() + '-' + this.pad(now.getMonth() + 1) + '-' + this.pad(now.getDate())
      + ' ' + this.pad(now.getHours()) + ':' + this.pad(now.getMinutes()) + ':' + this.pad(now.getSeconds());
    const duration = Math.max(1, Math.floor((Date.now() - this.startTime) / 1000));

    for (let i = 0; i < this.questions.length; i++) {
      const q = this.questions[i];
      const d = DEMO_QUESTIONS.find((x: DemoQuestion): boolean => x.questionId === q.questionId);
      const correctOpt = d !== undefined ? d.answer : '';
      const correct = q.selected === correctOpt;
      if (correct) {
        correctCount++;
      }
      const cardItem: AnswerCardItem = {
        questionId: q.questionId, correct: correct, userAnswer: q.selected, correctOption: correctOpt
      };
      card.push(cardItem);

      // 按知识点累计掌握度
      const kp = q.knowledgePoint === '' ? '综合' : q.knowledgePoint;
      let m = masteryMap.get(kp);
      if (m === undefined) {
        m = { knowledgePoint: kp, correct: 0, total: 0, accuracy: 0 };
        masteryMap.set(kp, m);
      }
      m.total++;
      if (correct) {
        m.correct++;
      }
    }
    const mastery: MasteryItem[] = [];
    masteryMap.forEach((m: MasteryItem) => {
      const acc = Math.round(m.correct / m.total * 100);
      mastery.push({ knowledgePoint: m.knowledgePoint, correct: m.correct, total: m.total, accuracy: acc });
    });

    const report: PracticeReportData = {
      itemId: '', itemName: '每日一练', practiceType: '每日一练', submitTime: submitTime,
      correctCount: correctCount, total: this.questions.length,
      accuracy: Math.round(correctCount / this.questions.length * 100),
      duration: duration, compare: null, answerCard: card, mastery: mastery
    };
    return report;
  }

  private pad(n: number): string {
    return n < 10 ? '0' + n.toString() : n.toString();
  }

  // 报告里的时长：后端给秒，前端格式化
  private durationText(): string {
    const r = this.report;
    if (r === null) {
      return '--';
    }
    const s = r.duration;
    return Math.floor(s / 60).toString() + '分' + this.pad(s % 60) + '秒';
  }

  private accuracyText(): string {
    const r = this.report;
    if (r === null || r.total <= 0) {
      return '--%';
    }
    const pct = Math.round(r.correctCount / r.total * 1000) / 10;
    return (Math.floor(pct) === pct ? pct.toFixed(0) : pct.toFixed(1)) + '%';
  }

  private deltaText(v: number | null): string {
    if (v === null) {
      return '--';
    }
    return (v > 0 ? '+' : '') + v.toString();
  }

  // 答题卡格子：按 questionId 找作答记录
  private findCard(questionId: string): AnswerCardItem | undefined {
    const r = this.report;
    if (r === null) {
      return undefined;
    }
    return r.answerCard.find((x: AnswerCardItem): boolean => x.questionId === questionId);
  }

  private cardTextColor(questionId: string): string {
    const item = this.findCard(questionId);
    if (item === undefined) {
      return '#8A94A6';   // 未答
    }
    return item.correct ? '#0E9F6E' : '#E5484D';
  }

  private cardBgColor(questionId: string): string {
    const item = this.findCard(questionId);
    if (item === undefined) {
      return '#F1F4F9';   // 未答
    }
    return item.correct ? '#E8F7F1' : '#FDECEC';
  }

  // 回看某题（报告页点答题卡）
  private toggleReview(i: number): void {
    this.reviewIndex = this.reviewIndex === i ? -1 : i;
  }

  // 回看中：选项行配色（正确=绿；用户选错=红）
  private reviewOptColor(optKey: string): string {
    const r = this.report;
    const q = this.questions[this.reviewIndex];
    if (r === null || q === undefined) {
      return '#5A6B85';
    }
    const item = r.answerCard.find((x: AnswerCardItem): boolean => x.questionId === q.questionId);
    if (item === undefined) {
      return '#5A6B85';
    }
    if (optKey === item.correctOption) {
      return '#0E9F6E';
    }
    if (optKey === item.userAnswer && !item.correct) {
      return '#E5484D';
    }
    return '#5A6B85';
  }

  private reviewOptBg(optKey: string): string {
    const r = this.report;
    const q = this.questions[this.reviewIndex];
    if (r === null || q === undefined) {
      return '#FFFFFF';
    }
    const item = r.answerCard.find((x: AnswerCardItem): boolean => x.questionId === q.questionId);
    if (item === undefined) {
      return '#FFFFFF';
    }
    if (optKey === item.correctOption) {
      return '#F2FBF7';
    }
    if (optKey === item.userAnswer && !item.correct) {
      return '#FFF6F6';
    }
    return '#FFFFFF';
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
  }

  build() {
    Column() {
      // ===== 顶部返回栏 =====
      Row() {
        Text('‹')
          .fontSize(34.0)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A202C')
          .padding({ left: 16, right: 12, top: 4, bottom: 4 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text(this.finished ? '练习报告' : '每日一练')
          .fontSize(18.0)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .layoutWeight(1)

        if (!this.finished && this.questions.length > 0) {
          // 收藏星标：加入/取消收藏，同步「我的收藏」
          Text(this.starred ? '★' : '☆')
            .fontSize(24.0)
            .fontColor(this.starred ? '#F5A623' : '#B9C2D0')
            .padding({ left: 2, right: 2 })
            .onClick(() => {
              this.toggleStar();
            })

          Text((this.cur + 1).toString() + '/' + this.questions.length.toString())
            .fontSize(14.0)
            .fontColor('#8A94A6')

          // 答题卡入口：右上角胶囊按钮
          Text('答题卡')
            .fontSize(13.5)
            .fontWeight(FontWeight.Medium)
            .fontColor('#3B6BF6')
            .backgroundColor('#EAF0FF')
            .padding({ left: 11, right: 11, top: 6, bottom: 6 })
            .borderRadius(14)
            .margin({ left: 12, right: 16 })
            .onClick(() => {
              this.sheetOpen = true;
            })
        } else {
          Blank().width(16)
        }
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#F1F4F9' })

      // ===== 主体 =====
      if (this.loading) {
        Column({ space: 12 }) {
          LoadingProgress().width(36).height(36).color('#3B6BF6')
          Text('正在获取今日题目...')
            .fontSize(14.0)
            .fontColor('#8A94A6')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.finished && this.report !== null) {
        this.ReportView()
      } else if (this.questions.length > 0) {
        this.QuestionView()
      } else {
        Column() {
          Text('暂无题目')
            .fontSize(15.0)
            .fontColor('#8A94A6')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  // ==================== 答题视图 ====================
  // 说明：Scroll 的内容默认在滚动区域内垂直居中（题目不足一屏时题干卡会浮在屏幕中间，
  // 与进度条之间出现大片空白），必须显式 .align(Alignment.Top) 顶对齐
  @Builder
  QuestionView() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 进度条
        Stack({ alignContent: Alignment.Start }) {
          Row().width('100%').height(4).borderRadius(2).backgroundColor('#E8EDF5')
          Row()
            .width((this.cur + 1) / this.questions.length * 100 + '%')
            .height(4)
            .borderRadius(2)
            .backgroundColor('#3B6BF6')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 10 })

        Scroll() {
          Column() {
            // 题干卡
            Column({ space: 10 }) {
              Text(this.questions[this.cur].knowledgePoint === '' ? '单选题' : this.questions[this.cur].knowledgePoint)
                .fontSize(12.0)
                .fontColor('#3B6BF6')
                .backgroundColor('#EAF0FF')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .borderRadius(6)

              Text(this.questions[this.cur].stem)
                .fontSize(17.5)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A202C')
                .lineHeight(26)
            }
            .width('100%')
            .padding(16)
            .borderRadius(16)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#EEF2F6' })
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 12 })

            // 选项列表
            ForEach(this.questions[this.cur].options, (opt: string, i: number) => {
              this.OptionRow(opt, i)
            }, (opt: string, i: number) => this.cur.toString() + '-' + i.toString() + '-' + opt)

            // 即时解析卡（作答后出现）
            if (this.judged()) {
              this.AnalysisCard()
            }
          }
          .padding({ left: 16, right: 16, bottom: 20 })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .align(Alignment.Top)

        // 底部按钮：上一题 / 下一题（末题=提交答案），两个按钮同尺寸同圆角；
        // 不可用态用「浅灰底 + 中灰字」的平面样式，不再用发蓝的灰，避免看着像坏掉
        Row({ space: 12 }) {
          Button('上一题')
            .layoutWeight(1)
            .height(48)
            .fontSize(17.0)
            .fontWeight(FontWeight.Medium)
            .type(ButtonType.Capsule)
            .backgroundColor(this.cur > 0 && !this.submitting ? Color.White : '#EFF2F7')
            .fontColor(this.cur > 0 && !this.submitting ? '#3A4556' : '#8A94A6')
            .border({
              width: 1.2,
              color: this.cur > 0 && !this.submitting ? '#DCE3EE' : '#DFE5EE'
            })
            .enabled(this.cur > 0 && !this.submitting)
            .onClick(() => {
              if (this.cur > 0) {
                this.cur--;
              }
            })

          Button(this.isLast() ? (this.submitting ? '提交中…' : '提交答案') : '下一题')
            .layoutWeight(1)
            .height(48)
            .fontSize(17.0)
            .fontWeight(FontWeight.Bold)
            .type(ButtonType.Capsule)
            .backgroundColor(this.answeredCurrent() ? '#3B6BF6' : '#E7ECF4')
            .fontColor(this.answeredCurrent() ? Color.White : '#8A94A6')
            .shadow(this.answeredCurrent() ?
              { radius: 8, color: '#2E3B6BF6', offsetY: 3 } :
              { radius: 0, color: Color.Transparent, offsetY: 0 })
            .enabled(!this.submitting)
            .onClick(() => {
              this.onNext();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .backgroundColor(Color.White)
        .border({ width: { top: 1 }, color: '#EEF2F6' })
      }
      .width('100%')
      .height('100%')

      // 答题卡底部面板（含遮罩）
      if (this.sheetOpen) {
        this.AnswerSheet()
      }
    }
    .width('100%')
    .layoutWeight(1) // 占返回栏以外的剩余高度；用 height('100%') 会整屏算高，把底栏挤出屏幕
  }

  // 已答题数
  private answeredCount(): number {
    let n = 0;
    for (const q of this.questions) {
      if (q.selected !== '') {
        n++;
      }
    }
    return n;
  }

  // 答题卡格子配色：当前题=蓝底白字，已作答=浅蓝底蓝字，未作答=灰底灰字
  private sheetCellBg(i: number): string {
    if (i === this.cur) {
      return '#3B6BF6';
    }
    return this.questions[i].selected !== '' ? '#EAF0FF' : '#F1F4F9';
  }

  private sheetCellFg(i: number): string {
    if (i === this.cur) {
      return '#FFFFFF';
    }
    return this.questions[i].selected !== '' ? '#3B6BF6' : '#5A6B85';
  }

  // 答题卡底部面板：点题号直接跳到该题，点遮罩关闭
  @Builder
  AnswerSheet() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#29000000')
        .onClick(() => {
          this.sheetOpen = false;
        })

      // 面板
      Column() {
        Row() {
          Text('答题卡')
            .fontSize(17.0)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A202C')

          Blank()

          Text('已答 ' + this.answeredCount().toString() + '/' + this.questions.length.toString())
            .fontSize(14.0)
            .fontColor('#3B6BF6')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.questions, (q: DailyQuestion, i: number) => {
            Text((i + 1).toString())
              .fontSize(16.0)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.sheetCellFg(i))
              .width(42)
              .height(42)
              .textAlign(TextAlign.Center)
              .borderRadius(21)
              .backgroundColor(this.sheetCellBg(i))
              .margin({ right: 10, top: 12 })
              .onClick(() => {
                this.cur = i;
                this.sheetOpen = false;
                this.refreshStar();
              })
          }, (q: DailyQuestion, i: number) => 'sheet' + i.toString())
        }
        .width('100%')

        // 图例
        Row({ space: 6 }) {
          Circle().width(8).height(8).fill('#3B6BF6')
          Text('当前题').fontSize(12.0).fontColor('#8A94A6')
          Circle().width(8).height(8).fill('#A9C2FB').margin({ left: 12 })
          Text('已作答').fontSize(12.0).fontColor('#8A94A6')
          Circle().width(8).height(8).fill('#DDE3EE').margin({ left: 12 })
          Text('未作答').fontSize(12.0).fontColor('#8A94A6')
        }
        .width('100%')
        .margin({ top: 16 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 26 })
      .borderRadius({ topLeft: 20, topRight: 20 })
      .backgroundColor(Color.White)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  OptionRow(opt: string, i: number) {
    Row({ space: 12 }) {
      // 判定后：正确选项显示绿色对勾圆标
      if (this.judged() && this.optKey(i) === this.currentCorrectKey()) {
        Text('✓')
          .fontSize(16.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor('#0E9F6E')
      } else {
        Text(this.optKey(i))
          .fontSize(15.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.questions[this.cur].selected === this.optKey(i) ? '#3B6BF6' : '#5A6B85')
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor(this.questions[this.cur].selected === this.optKey(i) ? '#EAF0FF' : '#F1F4F9')
      }

      Text(opt)
        .fontSize(15.5)
        .fontColor('#1A202C')
        .lineHeight(21)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(13)
    .borderRadius(14)
    .backgroundColor(this.judged() && this.optKey(i) === this.currentCorrectKey() ? '#F0FAF5'
      : (this.judged() && this.questions[this.cur].selected === this.optKey(i) ? '#FFF6F6' : Color.White))
    .border({
      width: 1.5,
      color: this.judged() && this.optKey(i) === this.currentCorrectKey() ? '#BFE8D2'
        : (this.judged() && this.questions[this.cur].selected === this.optKey(i) ? '#F2C1C1' : '#EEF2F6')
    })
    .margin({ bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.pick(this.optKey(i));
    })
  }

  // ===== 单题解析卡（参考聚题库版式：正确答案/我的作答对比 + 统计条 + AI解答入口 + 知识点） =====
  @Builder
  AnalysisCard() {
    Column() {
      // 答案对比 + 印章
      Stack({ alignContent: Alignment.TopEnd }) {
        Row() {
          Column({ space: 5 }) {
            Text(this.currentCorrectKey())
              .fontSize(21.0)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0E9F6E')
            Text('正确答案')
              .fontSize(13.0)
              .fontColor('#8A94A6')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Divider()
            .vertical(true)
            .height(34)
            .color('#EEF2F6')

          Column({ space: 5 }) {
            Text(this.questions[this.cur].selected)
              .fontSize(21.0)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.stampColor())
            Text('我的作答')
              .fontSize(13.0)
              .fontColor('#8A94A6')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ top: 14, bottom: 12 })

        // 斜盖章：答对 / 答错
        Text(this.questions[this.cur].selected === this.currentCorrectKey() ? '答对' : '答错')
          .fontSize(14.0)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.stampColor())
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(6)
          .border({ width: 1.2, color: this.stampColor() })
          .rotate({ x: 0, y: 0, z: 1, angle: -14 })
          .margin({ right: 12, top: 12 })
          .opacity(0.85)
      }
      .width('100%')

      Divider().color('#F1F4F9').strokeWidth(1)

      // 解析
      Column({ space: 7 }) {
        Text('解析')
          .fontSize(14.5)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')

        Text(this.currentTip())
          .fontSize(14.5)
          .fontColor('#3A4552')
          .lineHeight(21)
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .alignItems(HorizontalAlign.Start)

      Divider().color('#F1F4F9').strokeWidth(1)

      // 统计条：答题时间 / 全站正确率 / 易错项
      Row() {
        this.StatCell('-', '答题时间')
        this.StatCell(this.statRate(), '全站正确率')
        this.StatCell(this.statErrorProne(), '易错项')
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      Divider().color('#F1F4F9').strokeWidth(1)

      // AI 解答入口：回到首页 AI 伴学页签
      Row() {
        Text('对这道题还有疑问？AI 来问你解答')
          .fontSize(14.5)
          .fontWeight(FontWeight.Medium)
          .fontColor('#3B6BF6')
          .layoutWeight(1)

        Text('›')
          .fontSize(19.0)
          .fontColor('#3B6BF6')
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .borderRadius(12)
      .backgroundColor('#EAF1FF')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        signalPendingTab(1);   // 返回首页并切到 AI 伴学页签
        this.getUIContext().getRouter().back();
      })

      // 知识点
      Row({ space: 10 }) {
        Text('知识点')
          .fontSize(14.0)
          .fontColor('#8A94A6')

        Text(this.questions[this.cur].knowledgePoint === '' ? '综合' : this.questions[this.cur].knowledgePoint)
          .fontSize(13.0)
          .fontColor('#3B6BF6')
          .backgroundColor('#EAF0FF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(6)
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#EEF2F6' })
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 4 })
  }

  @Builder
  StatCell(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(16.0)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
      Text(label)
        .fontSize(12.0)
        .fontColor('#8A94A6')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== 练习报告 ====================
  @Builder
  ReportView() {
    Column() {
      Scroll() {
        Column() {
          // ===== 报告头卡 =====
          Column() {
            Row() {
              Column({ space: 12 }) {
                this.ReportLine('练习类型', this.report!.practiceType)
                this.ReportLine('交卷时间', this.report!.submitTime)
                this.ReportLine('正确率', this.accuracyText())
                this.ReportLine('练习时长', this.durationText())
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Stack({ alignContent: Alignment.Center }) {
                Progress({
                  value: this.report!.correctCount,
                  total: this.report!.total,
                  type: ProgressType.Ring
                })
                  .width(92)
                  .height(92)
                  .color('#3B6BF6')
                  .backgroundColor('#E4EBF8')
                  .style({ strokeWidth: 8 })

                Column({ space: 1 }) {
                  Text() {
                    Span(this.report!.correctCount.toString())
                      .fontSize(25.0)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1A202C')
                    Span('/' + this.report!.total.toString())
                      .fontSize(14.0)
                      .fontColor('#8A94A6')
                  }
                  Text('答对')
                    .fontSize(12.0)
                    .fontColor('#8A94A6')
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              }
              .margin({ left: 10 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 与上次 / 合格线对比（字段可为 null）
            if (this.report!.compare !== null) {
                  Divider().color('#F1F4F9').strokeWidth(1).margin({ top: 14, bottom: 10 })

              Row() {
                Text('上次正确率 ' + (this.report!.compare!.lastAccuracy === null
                  ? '--' : this.report!.compare!.lastAccuracy.toString() + '%'))
                  .fontSize(13.0)
                  .fontColor('#8A94A6')
                Text('较上次 ' + this.deltaText(this.report!.compare!.deltaVsLast))
                  .fontSize(13.0)
                  .fontColor(this.report!.compare!.deltaVsLast !== null && this.report!.compare!.deltaVsLast < 0
                    ? '#E5484D' : '#0E9F6E')
                  .margin({ left: 14 })
                Text('较合格线 ' + this.deltaText(this.report!.compare!.deltaVsPassLine))
                  .fontSize(13.0)
                  .fontColor(this.report!.compare!.deltaVsPassLine !== null
                    && this.report!.compare!.deltaVsPassLine < 0 ? '#E5484D' : '#0E9F6E')
                  .margin({ left: 14 })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
            }

            // IP 鼓励语：兜兜点赞（IP 放进浅蓝圆角容器，避免"贴纸"悬浮感）
            Row({ space: 12 }) {
              Stack({ alignContent: Alignment.Center }) {
                Column()
                  .width(56)
                  .height(72)
                  .borderRadius(16)
                  .backgroundColor('#EAF1FF')

                Image($r('app.media.ip_good'))
                  .width(44)
                  .height(60)
                  .objectFit(ImageFit.Contain)
              }

              Column({ space: 3 }) {
                Text('做得真棒，继续保持！')
                  .fontSize(15.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A202C')
                Text('每天 10 道题，考试更稳妥')
                  .fontSize(13.0)
                  .fontColor('#8A94A6')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .margin({ top: 14 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#EEF2F6' })
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16, right: 16, top: 12 })

          // ===== 答题卡 =====
          Column() {
            Row() {
              Text('答题卡')
                .fontSize(16.5)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A202C')
              Blank()
              Row({ space: 4 }) {
                Circle().width(8).height(8).fill('#0E9F6E')
                Text('答对').fontSize(12.0).fontColor('#8A94A6')
                Circle().width(8).height(8).fill('#E5484D').margin({ left: 10 })
                Text('答错').fontSize(12.0).fontColor('#8A94A6')
                Circle().width(8).height(8).fill('#C9D4E5').margin({ left: 10 })
                Text('未答').fontSize(12.0).fontColor('#8A94A6')
              }
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')

            Text('单选题 · 共' + this.report!.total.toString() + '题')
              .fontSize(13.0)
              .fontColor('#8A94A6')
              .width('100%')
              .margin({ top: 10 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.questions, (q: DailyQuestion, i: number) => {
                Column() {
                  Text((i + 1).toString())
                    .fontSize(16.0)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.cardTextColor(q.questionId))
                    .width(42)
                    .height(42)
                    .textAlign(TextAlign.Center)
                    .borderRadius(21)
                    .backgroundColor(this.cardBgColor(q.questionId))
                }
                .width('20%')
                .padding({ top: 8, bottom: 8 })
                .onClick(() => {
                  this.toggleReview(i);
                })
              }, (q: DailyQuestion, i: number) => 'card' + i.toString())
            }
            .width('100%')
            .margin({ top: 4 })

            Text('点题号可回看该题')
              .fontSize(12.0)
              .fontColor('#A8B3C5')
              .width('100%')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#EEF2F6' })
          .margin({ top: 12, left: 16, right: 16 })

          // ===== 回看单题 =====
          if (this.reviewIndex >= 0 && this.questions[this.reviewIndex] !== undefined) {
            Column() {
              Row() {
                Text('第 ' + (this.reviewIndex + 1).toString() + ' 题')
                  .fontSize(15.0)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#3B6BF6')
                Blank()
                Text('收起')
                  .fontSize(13.0)
                  .fontColor('#8A94A6')
                  .onClick(() => {
                    this.reviewIndex = -1;
                  })
              }
              .width('100%')

              Text(this.questions[this.reviewIndex].stem)
                .fontSize(15.5)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A202C')
                .lineHeight(23)
                .width('100%')
                .margin({ top: 10 })

              ForEach(this.questions[this.reviewIndex].options, (opt: string, i: number) => {
                Row({ space: 10 }) {
                  Text(this.optKey(i))
                    .fontSize(13.5)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.reviewOptColor(this.optKey(i)))
                    .width(26)
                    .height(26)
                    .textAlign(TextAlign.Center)
                    .borderRadius(13)
                    .backgroundColor(this.reviewOptBg(this.optKey(i)))

                  Text(opt)
                    .fontSize(14.5)
                    .fontColor('#1A202C')
                    .lineHeight(20)
                    .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
                .alignItems(VerticalAlign.Center)
              }, (opt: string, i: number) => 'rv' + this.reviewIndex.toString() + '-' + i.toString() + '-' + opt)

              Text('知识点：' + (this.questions[this.reviewIndex].knowledgePoint === ''
                ? '综合' : this.questions[this.reviewIndex].knowledgePoint))
                .fontSize(12.5)
                .fontColor('#8A94A6')
                .width('100%')
                .margin({ top: 6 })
            }
            .width('100%')
            .padding(16)
            .borderRadius(16)
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#EAF0FF' })
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 12, left: 16, right: 16 })
          }

          // ===== 知识点掌握 =====
          Column() {
            Text('知识点掌握')
              .fontSize(16.5)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A202C')
              .width('100%')

            ForEach(this.report!.mastery, (m: MasteryItem) => {
              Row() {
                Column({ space: 6 }) {
                  Text(m.knowledgePoint)
                    .fontSize(15.0)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1A202C')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text('共' + m.total.toString() + '题，答对' + m.correct.toString() + '题')
                    .fontSize(13.0)
                    .fontColor('#8A94A6')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Stack({ alignContent: Alignment.Center }) {
                  Progress({ value: m.accuracy, total: 100, type: ProgressType.Ring })
                    .width(62)
                    .height(62)
                    .color('#3B6BF6')
                    .backgroundColor('#EDF1F8')
                    .style({ strokeWidth: 6 })

                  Column() {
                    Text(m.accuracy.toString() + '%')
                      .fontSize(12.5)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(m.accuracy >= 60 ? '#0E9F6E' : '#E5484D')
                    Text('正确率')
                      .fontSize(10.0)
                      .fontColor('#8A94A6')
                  }
                  .alignItems(HorizontalAlign.Center)
                }
                .margin({ left: 10 })
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .alignItems(VerticalAlign.Center)
            }, (m: MasteryItem) => m.knowledgePoint)
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#EEF2F6' })
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 12, left: 16, right: 16, bottom: 20 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)

      // 底部按钮：再来一组（换一套新的十题）/ 返回
      Row({ space: 12 }) {
        Button('再来一组')
          .layoutWeight(1)
          .height(48)
          .fontSize(17.0)
          .fontWeight(FontWeight.Bold)
          .type(ButtonType.Capsule)
          .backgroundColor(this.demoMode ? '#3B6BF6' : '#E7ECF4')
          .fontColor(this.demoMode ? Color.White : '#8A94A6')
          .shadow(this.demoMode ?
            { radius: 8, color: '#2E3B6BF6', offsetY: 3 } :
            { radius: 0, color: Color.Transparent, offsetY: 0 })
          .enabled(this.demoMode)
          .onClick(() => {
            this.startGroup(this.groupIndex + 1);
          })

        Button('返回')
          .layoutWeight(1)
          .height(48)
          .fontSize(17.0)
          .fontWeight(FontWeight.Medium)
          .type(ButtonType.Capsule)
          .backgroundColor(Color.White)
          .fontColor('#3A4556')
          .border({ width: 1.2, color: '#DCE3EE' })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 16 })
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#EEF2F6' })
    }
    .width('100%')
    .layoutWeight(1) // 同答题视图：占剩余高度，避免报告底栏被挤出屏幕
  }

  @Builder
  ReportLine(label: string, value: string) {
    Row({ space: 10 }) {
      Text(label)
        .fontSize(14.0)
        .fontColor('#8A94A6')
        .width(64)
      Text(value)
        .fontSize(14.5)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A202C')
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}
