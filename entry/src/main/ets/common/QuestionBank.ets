// 本地题库：原始《知识点练习题》4 章 20 题 + 补充题 30 章 100 题，
// 覆盖首页全部知识点，每章不少于 5 题，均含解析。
// 后端题库接口就绪前，PracticeApi 的 mock 分支用它兜底；后端接口失败时也退回这里。
// 题目 ID 用业务码（kp-basic-law-q01），与后端种子数据同码，将来切真接口不会串数据。
// 答案只存在本文件：页面拿到的对错与解析一律走 judge()，不在页面里比对答案。
import { PracticeQuestion, JudgeResult } from '../model/QuestionModels';
import { KpEntry, kpOf } from './KnowledgeCatalog';
import { BankQuestion, BankChapter } from './QuestionBankTypes';
import { BASIC_EXTRA_CHAPTERS } from './QuestionBankBasicExtra';
import { PRO_EXTRA_CHAPTERS } from './QuestionBankProExtra';

// 原始题库文档对应的四个章节
const CORE_CHAPTERS: BankChapter[] = [
  // ===== 基础知识 · 相关法律法规 =====
  {
    kpId: 'kp-basic-law',
    questions: [
      {
        no: 1,
        stem: '根据《托儿所幼儿园卫生保健管理办法》，婴幼儿入园（所）时应当查验的健康证明文件是（ ）',
        options: ['出生医学证明', '儿童入园（所）健康检查表', '预防接种完成证明原件', '体格发育评价报告'],
        answer: 'B',
        explanation: '管理办法规定儿童入园（所）前须经医疗卫生机构健康检查，合格后方可入园，查验的是“儿童入园（所）健康检查表”；预防接种证是入园时同步查验并督促补种的证件，但健康证明的核心是体检合格证明。'
      },
      {
        no: 2,
        stem: '依据《未成年人保护法》，未成年人是指未满（ ）周岁的公民。',
        options: ['14', '16', '18', '20'],
        answer: 'C',
        explanation: '《未成年人保护法》第二条：未成年人指未满十八周岁的公民。托育、幼儿园服务对象全部属于未成年人，高频送分题。'
      },
      {
        no: 3,
        stem: '根据《食品安全法》，托幼机构食堂制作的食品应当（ ）',
        options: [
          '每餐样品留存48小时以上，每样不少于125克',
          '每餐样品留存24小时以上，每样不少于100克',
          '每餐样品留存72小时以上，每样不少于150克',
          '无需留样，但需做好进货查验记录'
        ],
        answer: 'A',
        explanation: '依据《食品安全法》及《学校食品安全与营养健康管理规定》，每餐食品成品留样，每品种不少于125克、留存48小时以上并记录，目的是发生食源性疾病时可追溯。干扰项常改时间或克数。'
      },
      {
        no: 4,
        stem: '依据《托育机构保育指导大纲（试行）》，托育机构保育工作应遵循的基本原则中，不包括以下哪项？（ ）',
        options: ['尊重儿童', '安全健康', '积极回应', '提前教学'],
        answer: 'D',
        explanation: '《托育机构保育指导大纲（试行）》规定四项基本原则：尊重儿童、安全健康、积极回应、科学规范。“提前教学”违背婴幼儿成长规律，托育的定位是照护与早期发展支持，不是提前教小学知识。'
      },
      {
        no: 5,
        stem: '依据《幼儿园工作规程》，正常情况下幼儿园每日户外活动时间不得少于（ ）',
        options: ['1 小时', '2 小时', '3 小时', '4 小时'],
        answer: 'B',
        explanation: '《幼儿园工作规程》要求正常情况下每日户外活动不少于 2 小时，其中体育活动不少于 1 小时；寄宿制幼儿园户外活动不少于 3 小时。'
      },
      {
        no: 6,
        stem: '依据《托儿所幼儿园卫生保健工作规范》，3 岁以上幼儿每年健康检查的次数是（ ）',
        options: ['1 次', '2 次', '3 次', '4 次'],
        answer: 'A',
        explanation: '卫生保健工作规范实行“4-2-1”体检：0～1 岁每年 4 次、1～2 岁每年 2 次、3 岁以上每年 1 次。'
      }
    ]
  },
  // ===== 初级 · 生活管理：组织饮水 =====
  {
    kpId: 'kp-beginner-water',
    questions: [
      {
        no: 1,
        stem: '组织幼儿饮水时，最适宜的饮用水是（ ）',
        options: ['冰镇凉白开', '温开水', '碳酸饮料', '纯净水替代日常饮水'],
        answer: 'B',
        explanation: '温开水最接近体温、对胃肠刺激最小。冰水刺激肠胃易引起腹痛，饮料含糖高影响食欲和牙齿健康，长期用纯净水替代也不能替代白开水在日常饮水中的地位。'
      },
      {
        no: 2,
        stem: '幼儿每次饮水前，保育员应先组织幼儿（ ）',
        options: ['排队取杯', '洗手', '漱口', '做安静游戏'],
        answer: 'B',
        explanation: '饮水前洗手是第一顺序，防止手上的污染物沾到杯口。排队取杯是洗手之后的组织环节，出题时常用“取杯”做干扰项，注意先后顺序：洗手→排队→取杯→饮水。'
      },
      {
        no: 3,
        stem: '保育员为幼儿准备饮用水、判断水温是否适宜的正确方法是（ ）',
        options: ['用嘴直接抿一口试温', '将水滴在自己手腕内侧试温', '用手触摸杯壁外侧即可', '凭经验估计，无需试温'],
        answer: 'B',
        explanation: '手腕内侧皮肤娇嫩、敏感，是试温的标准部位。A项用嘴直接接触幼儿水杯不卫生，C项摸杯壁不能准确判断水温（尤其是保温杯），D项是失职行为。'
      },
      {
        no: 4,
        stem: '幼儿饮水杯的正确管理方式是（ ）',
        options: ['全班共用一只大水壶直接喝', '每人专用杯，每日清洗消毒', '每周清洗一次', '用一次性纸杯替代日常饮水'],
        answer: 'B',
        explanation: '水杯必须专人专用、标记姓名，每日清洗并消毒（常用煮沸或蒸汽消毒），防止交叉感染。共用壶、周清洗、长期一次性纸杯都不符合卫生要求。'
      },
      {
        no: 5,
        stem: '组织幼儿饮水时，正确的做法是（ ）',
        options: ['只在三餐时提供水', '限制饮水以防止尿床', '上下午各组织一次集体饮水，并允许随渴随喝', '让幼儿自己接水，保育员不作看护'],
        answer: 'C',
        explanation: '饮水要“定时与随时结合”：上下午各组织一次集体饮水，同时允许幼儿口渴时随时喝水。限制饮水会影响代谢、诱发便秘和尿路问题；幼儿接水时保育员必须在旁看护，防止烫伤和打翻。'
      }
    ]
  },
  // ===== 中级 · 生活管理：组织进餐 =====
  {
    kpId: 'kp-intermediate-meal',
    questions: [
      {
        no: 1,
        stem: '幼儿进餐前，保育员对餐桌进行消毒的正确顺序是（ ）',
        options: [
          '清水擦→消毒液擦→清水擦',
          '消毒液擦→清水擦→消毒液擦',
          '清水擦→消毒液擦，无需再清擦',
          '只需用清水擦一遍即可'
        ],
        answer: 'A',
        explanation: '标准桌面消毒流程是“清—消—清”：先清水擦去浮尘，再用消毒液擦拭并保留作用时间，最后清水擦去残留。这是中级实操的高频考点，顺序不能颠倒。'
      },
      {
        no: 2,
        stem: '幼儿进餐过程中，保育员的正确做法是（ ）',
        options: [
          '对吃得慢的幼儿进行批评，督促其快点吃',
          '随时添加饭菜，要求幼儿必须吃完',
          '观察幼儿进食情况，鼓励细嚼慢咽，不催食不训斥',
          '利用进餐时间教育挑食的幼儿，当场点名批评'
        ],
        answer: 'C',
        explanation: '中级考点核心是“回应性照料”态度：观察、鼓励、耐心，反对催食、强制、当众批评。A、B、D都是反面做法。'
      },
      {
        no: 3,
        stem: '组织进餐时培养幼儿独立性的做法是（ ）',
        options: [
          '全部由保育员代劳，幼儿只管吃',
          '鼓励幼儿力所能及地自取餐具、参与分发餐具，饭后自己清理餐具',
          '让幼儿互相喂饭，锻炼合作能力',
          '由吃得快的幼儿帮助吃得慢的幼儿喂饭'
        ],
        answer: 'B',
        explanation: '组织进餐不只是“喂饱”，更要培养自理能力：自取餐具、分发餐具、饭后参与收拾，都是适宜的独立性培养。C、D互相喂饭有卫生和安全问题，A剥夺锻炼机会。'
      },
      {
        no: 4,
        stem: '幼儿进餐时间一般控制在（ ）',
        options: ['10～15 分钟', '20～30 分钟', '40～50 分钟', '越快越好'],
        answer: 'B',
        explanation: '每餐进餐时间以 20～30 分钟为宜：过短来不及细嚼，过长饭菜变凉、影响下一环节。进餐中不催食、不拖堂，是生活管理的基本要求。'
      },
      {
        no: 5,
        stem: '幼儿进餐中发生轻度呛噎，正确的处理是（ ）',
        options: ['立即拍打后背', '鼓励幼儿咳嗽，同时密切观察', '立即喂水冲下', '让幼儿立刻平躺'],
        answer: 'B',
        explanation: '轻度呛噎时咳嗽是有效的自我保护，应鼓励咳嗽并密切观察，不要拍背或喂水（可能使异物移位或误吸）。若出现不能咳嗽、面色发绀等完全梗阻表现，立即使用海姆立克法并呼救。'
      }
    ]
  },
  // ===== 高级 · 生活管理：组织睡眠 =====
  {
    kpId: 'kp-advanced-sleep',
    questions: [
      {
        no: 1,
        stem: '组织幼儿睡眠前，保育员应首先安排幼儿（ ）',
        options: ['脱衣上床', '排尿', '听故事', '做安静游戏'],
        answer: 'B',
        explanation: '睡前先排尿，防止尿床和起夜干扰睡眠，这是睡眠照料的第一环节；安静活动、听故事等是排尿后帮助入眠的组织手段。'
      },
      {
        no: 2,
        stem: '对幼儿睡眠姿势的指导，正确的是（ ）',
        options: [
          '俯卧压着睡最安稳，不必干预',
          '仰卧或右侧卧位较好，发现蒙头睡要及时纠正',
          '左侧卧位最有利于消化',
          '睡姿由幼儿自由选择，蒙头睡也不用管'
        ],
        answer: 'B',
        explanation: '适宜睡姿是仰卧或右侧卧（右侧卧利于胃排空、不压迫心脏）；蒙头睡会导致缺氧，必须及时纠正。俯卧对婴幼儿有捂闷风险。高级考点常结合“睡眠安全”出题。'
      },
      {
        no: 3,
        stem: '幼儿睡眠期间，保育员巡视观察的重点不包括（ ）',
        options: ['睡眠姿势与盖被情况', '面色、呼吸是否正常', '是否有遗尿、身体不适等异常', '幼儿入睡的快慢排名并记录名次'],
        answer: 'D',
        explanation: '巡视观察的内容：睡姿、盖被、面色、呼吸、有无遗尿/异常出汗/发热惊厥等，发现异常及时处理并报告保健员。给入睡快慢排名既无照护价值，还会造成心理压力，不是巡视内容。'
      },
      {
        no: 4,
        stem: '幼儿午睡时，保育员巡视的间隔时间一般不超过（ ）',
        options: ['10 分钟', '20 分钟', '30 分钟', '1 小时'],
        answer: 'B',
        explanation: '午睡巡视应保持 10～20 分钟一次的频率，重点看睡姿、盖被、面色和呼吸。间隔过长，捂闷、发热惊厥等异常难以及时发现。'
      },
      {
        no: 5,
        stem: '幼儿床铺之间建议保持的间距是（ ）',
        options: ['20cm', '30cm', '50cm', '100cm'],
        answer: 'C',
        explanation: '床铺间距不小于 50cm，既能减少呼吸道疾病交叉感染，也保证巡视和紧急疏散有足够通道。间距过密还容易相互碰撞、影响入睡。'
      }
    ]
  }
];

// 全部题目 = 原始四节 + 基础知识补充 + 专业知识补充（每个知识点不少于 5 题）
const CHAPTERS: BankChapter[] = CORE_CHAPTERS.concat(BASIC_EXTRA_CHAPTERS).concat(PRO_EXTRA_CHAPTERS);

// 选项字母：与 options 数组下标一一对应
const OPTION_LETTERS: string[] = ['A', 'B', 'C', 'D'];

// 题目业务码：kpId + 两位序号，如 kp-basic-law-q01
function codeOf(kpId: string, no: number): string {
  return kpId + '-q' + (no < 10 ? '0' + no.toString() : no.toString());
}

function chapterOf(kpId: string): BankChapter | undefined {
  for (let i = 0; i < CHAPTERS.length; i++) {
    if (CHAPTERS[i].kpId === kpId) {
      return CHAPTERS[i];
    }
  }
  return undefined;
}

function bankQuestionOf(kpId: string, questionId: string): BankQuestion | undefined {
  const chapter: BankChapter | undefined = chapterOf(kpId);
  if (chapter === undefined) {
    return undefined;
  }
  for (let i = 0; i < chapter.questions.length; i++) {
    if (codeOf(kpId, chapter.questions[i].no) === questionId) {
      return chapter.questions[i];
    }
  }
  return undefined;
}

// 某知识点的题目（下发时不含答案）
export function questionsOf(kpId: string): PracticeQuestion[] {
  const chapter: BankChapter | undefined = chapterOf(kpId);
  const kp: KpEntry | undefined = kpOf(kpId);
  if (chapter === undefined || kp === undefined) {
    return [];
  }
  const out: PracticeQuestion[] = [];
  for (let i = 0; i < chapter.questions.length; i++) {
    const q: BankQuestion = chapter.questions[i];
    out.push({
      questionId: codeOf(kpId, q.no),
      stem: q.stem,
      options: q.options.slice(),
      knowledgePoint: kp.label,
      kpId: kpId,
      type: 'single'
    });
  }
  return out;
}

// 本地判题：即选即判 + 解析。题目不在本地题库时返回 undefined
export function judge(kpId: string, questionId: string, userAnswer: string): JudgeResult | undefined {
  const q: BankQuestion | undefined = bankQuestionOf(kpId, questionId);
  if (q === undefined) {
    return undefined;
  }
  return {
    questionId: questionId,
    correct: q.answer === userAnswer,
    correctOption: q.answer,
    explanation: q.explanation
  };
}

// 正确选项下标 0-3（收藏 / 错题本存的是下标）。题目不在本地题库时返回 -1
export function answerIndexOf(kpId: string, questionId: string): number {
  const q: BankQuestion | undefined = bankQuestionOf(kpId, questionId);
  if (q === undefined) {
    return -1;
  }
  return OPTION_LETTERS.indexOf(q.answer);
}
