// 专业知识补充题（每个知识点 5 题）。
// 同一知识点在初/中/高三个级别都出现时（清洁、消毒、组织盥洗如厕、配合教育活动等），
// 共用同一份题目，只按级别挂不同 kpId —— 保证每个入口都有题，后续按级别细化时再拆分。
import { BankChapter, BankQuestion } from './QuestionBankTypes';

// ===== 保管和使用物品（初级） =====
const STORAGE_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '幼儿个人物品的管理方式是（ ）',
    options: ['全班统一放置，用时再找', '专人专用并标记姓名', '每周更换一次', '由家长每天带回家'],
    answer: 'B',
    explanation: '水杯、毛巾、床铺等专人专用并做好标识，既卫生也便于幼儿建立物品归属意识。'
  },
  {
    no: 2,
    stem: '剪刀、药品等危险物品应（ ）',
    options: ['放在活动区随手可取', '放在窗台上', '放在幼儿拿不到的地方，专人保管', '交给幼儿轮流保管'],
    answer: 'C',
    explanation: '危险物品必须定点上锁、专人保管，取用登记，防止幼儿误用误服。'
  },
  {
    no: 3,
    stem: '玩具投入使用前，保育员应（ ）',
    options: ['检查有无破损、尖锐边角和松动小零件', '直接分发给幼儿', '用嘴吹掉灰尘', '只按颜色分类'],
    answer: 'A',
    explanation: '破损玩具的尖角、脱落小零件会造成划伤和误吞，使用前逐个检查是必要的安全步骤。'
  },
  {
    no: 4,
    stem: '幼儿药品的正确管理方式是（ ）',
    options: ['放在幼儿书包里', '和家长的药混放', '按经验自行喂药', '专人专柜、凭医嘱喂药并登记'],
    answer: 'D',
    explanation: '药品要专人专柜、标签清楚，严格按家长委托和医嘱喂药，并记录药名、剂量和时间。'
  },
  {
    no: 5,
    stem: '清洁工具（拖把、抹布等）应（ ）',
    options: ['和餐具一起存放', '与幼儿用品分开存放', '放在盥洗室地面', '用完直接收进柜子'],
    answer: 'B',
    explanation: '清洁工具分区专用、与幼儿餐具毛巾分开存放，用后清洗晾干，避免交叉污染。'
  }
];

// ===== 健康观察（初级/中级） =====
const HEALTH_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '晨间健康检查的规范方法是（ ）',
    options: ['一摸、二看、三问、四查', '只测体温', '只问家长', '看幼儿有没有哭'],
    answer: 'A',
    explanation: '一摸额头颈部、二看咽喉皮肤精神状态、三问饮食睡眠大小便、四查有无危险物品，缺一不可。'
  },
  {
    no: 2,
    stem: '发现幼儿面色苍白、精神萎靡，保育员应（ ）',
    options: ['让幼儿继续活动', '给幼儿喝热水即可', '及时测量体温并通知保健员和家长', '等午睡后再观察'],
    answer: 'C',
    explanation: '精神萎靡常是发热或疾病的早期信号，要及时测量体温、隔离观察并通知保健员和家长。'
  },
  {
    no: 3,
    stem: '全日健康观察的重点内容包括（ ）',
    options: ['只观察有没有哭闹', '饮食、睡眠、大小便、情绪与活动状态', '只记录身高体重', '只检查衣着是否整洁'],
    answer: 'B',
    explanation: '全日观察覆盖进餐、睡眠、排泄、情绪和活动，才能及时发现身体不适。'
  },
  {
    no: 4,
    stem: '幼儿诉说腹痛时，保育员的正确做法是（ ）',
    options: ['立即喂止痛药', '用力揉肚子', '让幼儿忍着继续活动', '不随意用药，及时通知家长和保健员'],
    answer: 'D',
    explanation: '腹痛原因不明时随意用药会掩盖病情，应让幼儿休息观察并立即通知家长和保健员。'
  },
  {
    no: 5,
    stem: '用水银体温计测量腋温，应夹紧测量（ ）',
    options: ['1 分钟', '5～10 分钟', '20 分钟', '30 分钟'],
    answer: 'B',
    explanation: '腋温测量需夹紧 5～10 分钟；用电子体温计时按说明书等待提示音即可。'
  }
];

// ===== 组织盥洗如厕（初级/中级/高级） =====
const TOILET_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '七步洗手法的正确顺序是（ ）',
    options: ['内、外、夹、弓、大、立、腕', '外、内、弓、夹、腕、立、大', '内、夹、外、立、弓、腕、大', '先洗手背再洗手心'],
    answer: 'A',
    explanation: '口诀“内、外、夹、弓、大、立、腕”，依次清洗掌心、手背、指缝、指背、拇指、指尖和手腕。'
  },
  {
    no: 2,
    stem: '组织幼儿如厕的间隔时间一般为（ ）',
    options: ['30 分钟', '1 小时', '1.5～2 小时', '半天一次'],
    answer: 'C',
    explanation: '每 1.5～2 小时提醒一次如厕，同时允许幼儿随时提出，避免憋尿憋便。'
  },
  {
    no: 3,
    stem: '女孩便后擦拭的正确方向是（ ）',
    options: ['从前向后', '从后向前', '来回擦拭', '不用擦拭'],
    answer: 'A',
    explanation: '从前向后擦拭可防止肛周细菌污染尿道口，降低泌尿系统感染风险。'
  },
  {
    no: 4,
    stem: '盥洗室地面的管理要求是（ ）',
    options: ['每天拖一次即可', '保持干燥防滑，及时清除积水', '铺上地毯吸水', '让幼儿自己处理'],
    answer: 'B',
    explanation: '盥洗室潮湿易滑倒，要随时清除积水、放置防滑垫，并提醒幼儿慢走。'
  },
  {
    no: 5,
    stem: '幼儿洗手后应（ ）',
    options: ['在衣服上擦干', '甩干即可', '用自己专用的毛巾擦干', '共用一条毛巾擦干'],
    answer: 'C',
    explanation: '洗手后用自己的专用毛巾擦干，毛巾一人一巾、每日清洗消毒，避免交叉感染。'
  }
];

// ===== 组织进餐（初级） =====
const MEAL_BEGINNER_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '进餐前，保育员首先应组织幼儿（ ）',
    options: ['排队取餐', '洗手', '看电视', '脱外套'],
    answer: 'B',
    explanation: '进餐前先洗手，再排队取餐、入座进餐，顺序不能颠倒。'
  },
  {
    no: 2,
    stem: '分餐时，相邻幼儿的餐具间距应不少于（ ）',
    options: ['5 厘米', '10 厘米', '20 厘米', '30 厘米'],
    answer: 'B',
    explanation: '餐具间距不少于 10 厘米，避免幼儿相互碰撞、碰洒热汤造成烫伤。'
  },
  {
    no: 3,
    stem: '判断饭菜温度是否适宜，正确的方法是（ ）',
    options: ['用嘴尝一口', '用手摸碗底', '滴在手腕内侧试温', '凭感觉估计'],
    answer: 'C',
    explanation: '手腕内侧皮肤敏感，是试温的标准部位；用嘴尝不卫生，摸碗底不能准确判断。'
  },
  {
    no: 4,
    stem: '每餐进餐时间以（ ）为宜',
    options: ['10 分钟以内', '20～30 分钟', '40～50 分钟', '越快越好'],
    answer: 'B',
    explanation: '20～30 分钟既能保证细嚼慢咽，又不会让饭菜变凉、影响后续环节。'
  },
  {
    no: 5,
    stem: '餐后保育员应组织幼儿（ ）',
    options: ['擦嘴、漱口，把餐具放到指定位置', '立即跑跳活动', '直接上床睡觉', '自己洗碗'],
    answer: 'A',
    explanation: '餐后擦嘴漱口、餐具归位，既清洁口腔也培养自理和整理习惯。'
  }
];

// ===== 组织进餐（高级） =====
const MEAL_ADVANCED_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '对有食物过敏史的幼儿，正确的管理方式是（ ）',
    options: ['建立过敏档案，单独配餐并避开过敏原', '让幼儿自己注意', '少量尝试逐渐适应', '与其他幼儿同样配餐'],
    answer: 'A',
    explanation: '过敏幼儿要建档登记、与家长确认过敏原，分餐时严格避开，并告知班级教师共同防范。'
  },
  {
    no: 2,
    stem: '食品留样的正确要求是（ ）',
    options: ['每样不少于 50 克，留存 24 小时', '每样不少于 125 克，留存 48 小时', '每样不少于 125 克，留存 12 小时', '不需要留样'],
    answer: 'B',
    explanation: '每餐每品种留样不少于 125 克、冷藏留存 48 小时以上并记录，便于食源性疾病追溯。'
  },
  {
    no: 3,
    stem: '幼儿进餐时突然不能说话、面色发绀，应立即（ ）',
    options: ['拍背等待', '喂水冲下', '让幼儿平躺', '施行海姆立克急救法并呼救'],
    answer: 'D',
    explanation: '完全气道梗阻必须立即用海姆立克法排出异物，同时呼叫救援、拨打急救电话。'
  },
  {
    no: 4,
    stem: '培养幼儿进餐礼仪，正确的做法是（ ）',
    options: ['当众批评吃相不好的幼儿', '示范并鼓励，不在进餐时训斥', '要求幼儿必须吃完', '比赛谁吃得快'],
    answer: 'B',
    explanation: '进餐礼仪靠示范和正向鼓励养成；训斥、催食会影响食欲和情绪。'
  },
  {
    no: 5,
    stem: '对超重肥胖幼儿的进餐管理，适宜的做法是（ ）',
    options: ['限制饮水', '完全不给主食', '先喝汤、细嚼慢咽，减少高糖高脂食物', '单独关在一边吃'],
    answer: 'C',
    explanation: '控制进餐速度和能量密度、增加蔬菜、保证活动量，比简单节食更安全有效。'
  }
];

// ===== 组织睡眠（初级/中级） =====
const SLEEP_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '幼儿园午睡时间一般安排为（ ）',
    options: ['30 分钟', '2 小时左右', '3 小时', '不安排午睡'],
    answer: 'B',
    explanation: '午睡约 2 小时，既能补充夜间睡眠不足，又不影响晚间入睡。'
  },
  {
    no: 2,
    stem: '睡前应安排幼儿（ ）',
    options: ['安静活动，避免剧烈运动', '跑步游戏', '看动画片', '大量饮水'],
    answer: 'A',
    explanation: '睡前散步、听故事等安静活动有助于情绪平复；剧烈运动会让幼儿过度兴奋难以入睡。'
  },
  {
    no: 3,
    stem: '睡眠室的光线要求是（ ）',
    options: ['开大灯保持明亮', '阳光直射床铺', '柔和、避免强光直射', '完全不通风'],
    answer: 'C',
    explanation: '睡眠时光线柔和、拉上窗帘，同时保持适度通风，营造安静舒适的入睡环境。'
  },
  {
    no: 4,
    stem: '幼儿起床后，保育员应（ ）',
    options: ['马上叠好被子收起来', '开窗通风、整理床铺', '让幼儿继续躺着', '关闭所有窗户'],
    answer: 'B',
    explanation: '起床后开窗通风、晾晒被褥并整理床铺，可减少尘螨和湿气。'
  },
  {
    no: 5,
    stem: '对入睡困难的幼儿，保育员应（ ）',
    options: ['大声催促', '让其独自哭到睡着', '罚站', '轻拍安抚、安静陪伴，不训斥'],
    answer: 'D',
    explanation: '轻拍、陪伴、稳定的睡前程序能帮助幼儿放松；训斥和惩罚会加重紧张更难入睡。'
  }
];

// ===== 清洁（初级/中级/高级） =====
const CLEAN_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '室内清洁的合理顺序是（ ）',
    options: ['从上到下、从里到外', '从下到上、从外到里', '先擦地再擦桌子', '随意进行'],
    answer: 'A',
    explanation: '先上后下、先里后外，灰尘和污水不会二次污染已清洁的区域。'
  },
  {
    no: 2,
    stem: '幼儿桌椅的日常清洁要求是（ ）',
    options: ['每周擦一次', '每日用清水擦拭，定期消毒', '只用干布掸灰', '脏了再擦'],
    answer: 'B',
    explanation: '桌椅每日清水擦拭，进餐前后按要求消毒，保持表面清洁无油污。'
  },
  {
    no: 3,
    stem: '清扫地面时应采用（ ）',
    options: ['干扫，扬起灰尘', '用鼓风机吹', '湿式清扫，避免扬尘', '只捡大块垃圾'],
    answer: 'C',
    explanation: '湿式清扫（湿拖、湿抹）能压住灰尘，减少幼儿吸入粉尘和病原体。'
  },
  {
    no: 4,
    stem: '幼儿被褥的清洁要求是（ ）',
    options: ['定期清洗晾晒，保持干爽', '一学期洗一次', '只在尿床后清洗', '从不晾晒'],
    answer: 'A',
    explanation: '被褥要定期清洗、经常晾晒，保持干爽，减少尘螨和霉菌滋生。'
  },
  {
    no: 5,
    stem: '清洁工具使用后应（ ）',
    options: ['随手放在墙角', '和玩具放一起', '直接收进柜子', '清洗干净、晾干并分区存放'],
    answer: 'D',
    explanation: '工具用后清洗晾干、按区域分开存放，避免细菌在潮湿环境中繁殖和交叉污染。'
  }
];

// ===== 消毒（初级/中级/高级） =====
const DISINFECT_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '日常擦拭桌椅使用的含氯消毒液，常用浓度是（ ）',
    options: ['50～100mg/L', '250～500mg/L', '1000～2000mg/L', '5000mg/L 以上'],
    answer: 'B',
    explanation: '一般物体表面消毒用 250～500mg/L 含氯消毒液，作用后再用清水擦净。'
  },
  {
    no: 2,
    stem: '不耐热的塑料玩具采用含氯消毒液浸泡，时间应为（ ）',
    options: ['5 分钟', '15 分钟', '30 分钟', '2 小时'],
    answer: 'C',
    explanation: '浸泡 30 分钟并确保完全浸没，捞出后用清水冲洗干净、晾干再使用。'
  },
  {
    no: 3,
    stem: '使用紫外线灯消毒时，正确的做法是（ ）',
    options: ['室内无人，照射约 30 分钟', '有人时开着消毒', '照射 1 分钟即可', '对着幼儿床铺直照'],
    answer: 'A',
    explanation: '紫外线对人眼和皮肤有伤害，必须室内无人时使用，照射约 30 分钟后通风。'
  },
  {
    no: 4,
    stem: '幼儿餐具的常用消毒方法是（ ）',
    options: ['用洗洁精洗后即可', '煮沸 15 分钟或蒸汽消毒', '用抹布擦干', '开水烫一下就行'],
    answer: 'B',
    explanation: '餐具清洗后煮沸 15 分钟或蒸汽消毒 10～15 分钟，消毒后存放在清洁柜内。'
  },
  {
    no: 5,
    stem: '每次消毒完成后，保育员应（ ）',
    options: ['口头告诉同事', '不用记录', '记录在脑子里', '登记消毒时间、浓度和操作人'],
    answer: 'D',
    explanation: '消毒记录是卫生保健检查的重要依据，也便于追溯问题和改进操作。'
  }
];

// ===== 配合教育活动（初级/中级/高级） =====
const ACTIVITY_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '教育活动开始前，保育员应（ ）',
    options: ['准备好场地、材料和教具', '等教师安排再说', '先打扫其他房间', '让幼儿自己准备'],
    answer: 'A',
    explanation: '提前检查场地安全、备齐材料和教具，活动才能顺利开展。'
  },
  {
    no: 2,
    stem: '教育活动进行中，保育员的主要职责是（ ）',
    options: ['代替教师讲课', '坐在一旁休息', '配合教师维持秩序，关注幼儿安全', '批改作业'],
    answer: 'C',
    explanation: '保育员在活动中配合组织、巡视安全、照顾个别幼儿，与教师形成保教合力。'
  },
  {
    no: 3,
    stem: '活动中发现幼儿注意力分散，保育员应（ ）',
    options: ['大声点名批评', '用眼神或轻声提醒，不打断教学', '直接拉出教室', '装作没看见'],
    answer: 'B',
    explanation: '轻声提醒、走近关注既能收回注意力，又不影响集体活动的节奏。'
  },
  {
    no: 4,
    stem: '教育活动结束后，保育员应（ ）',
    options: ['组织收拾材料、清洁场地', '马上离开', '让幼儿直接回班', '把材料堆在角落'],
    answer: 'A',
    explanation: '活动后及时整理材料、清洁场地，既保持环境整洁，也为下一次活动做准备。'
  },
  {
    no: 5,
    stem: '户外活动时，保育员的站位要求是（ ）',
    options: ['站在门口聊天', '只盯住一个幼儿', '站在阴凉处休息', '合理站位，视线覆盖全体幼儿'],
    answer: 'D',
    explanation: '站位要能观察到所有幼儿，重点区域（滑梯、攀爬架）加强看护，避免视线盲区。'
  }
];

// ===== 防范意外伤害（高级） =====
const INJURY_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '幼儿发生烫伤后，现场急救的正确顺序是（ ）',
    options: ['冲、脱、泡、盖、送', '涂牙膏、包扎', '先挑破水泡', '立即冰敷 1 小时'],
    answer: 'A',
    explanation: '先用流动冷水冲、小心脱去衣物、继续冷水浸泡、干净敷料覆盖、及时送医；不要涂牙膏酱油。'
  },
  {
    no: 2,
    stem: '幼儿跌倒造成表皮擦伤，正确的处理是（ ）',
    options: ['直接贴创可贴', '清水冲洗后碘伏消毒', '用手揉搓', '涂牙膏止血'],
    answer: 'B',
    explanation: '先用流动清水冲掉泥沙，再用碘伏消毒，必要时覆盖敷料；伤口深或污染重要及时就医。'
  },
  {
    no: 3,
    stem: '幼儿发生惊厥（抽风）时，保育员应（ ）',
    options: ['强行按压四肢', '往嘴里塞毛巾', '侧卧、保持呼吸道通畅，不强行按压', '立即喂水'],
    answer: 'C',
    explanation: '侧卧防止误吸、松开衣领保持通畅、记录发作时间并呼叫急救；强行按压或塞东西会造成伤害。'
  },
  {
    no: 4,
    stem: '发现幼儿误服药物或不明物品，正确的做法是（ ）',
    options: ['大量喝水催吐', '等待观察', '责问幼儿', '立即送医，并带上误服物品或包装'],
    answer: 'D',
    explanation: '不要盲目催吐，立即送医并带上剩余药物或包装，便于医生判断和处理。'
  },
  {
    no: 5,
    stem: '组织外出活动预防走失，最关键的做法是（ ）',
    options: ['出发前后和途中反复清点人数', '让幼儿手拉手就足够', '只在返回时清点', '由家长各自看管'],
    answer: 'A',
    explanation: '外出前、途中和返回时多次清点人数，明确集合点和看护分工，才能及时发现走失。'
  }
];

// ===== 培训与指导（高级） =====
const TRAINING_QUESTIONS: BankQuestion[] = [
  {
    no: 1,
    stem: '指导新入职保育员最有效的方式是（ ）',
    options: ['只发一份规章制度', '示范、讲解与实操相结合', '让其自己摸索', '只在出错时批评'],
    answer: 'B',
    explanation: '先示范正确操作、再讲清要点、最后让其在指导下动手做，技能才能落到实处。'
  },
  {
    no: 2,
    stem: '制定保育员培训计划的主要依据是（ ）',
    options: ['岗位需求和保育员的能力短板', '网上的热门课程', '个人兴趣', '别人的培训计划'],
    answer: 'A',
    explanation: '培训要围绕岗位职责和实际薄弱环节设计内容，才有针对性。'
  },
  {
    no: 3,
    stem: '带教中发现初级保育员操作有误，正确的做法是（ ）',
    options: ['当众批评', '视而不见', '及时指出并示范正确做法', '记录下来年底再说'],
    answer: 'C',
    explanation: '当场温和指出、演示正确操作并让其练习，纠错效果最好，也能保护其积极性。'
  },
  {
    no: 4,
    stem: '检验培训效果最可靠的方式是（ ）',
    options: ['看签到表', '让学员自评', '只听口头汇报', '实操考核结合日常观察'],
    answer: 'D',
    explanation: '实际操作是否规范、日常工作中是否落实，才是培训效果的真实体现。'
  },
  {
    no: 5,
    stem: '组织保育员经验交流，适宜的做法是（ ）',
    options: ['只念文件', '用真实案例研讨，鼓励分享做法', '让大家互相打分排名', '取消交流节约时间'],
    answer: 'B',
    explanation: '围绕真实场景讨论“遇到什么问题、怎么处理、效果如何”，比单向讲授更能提升能力。'
  }
];

// 专业知识补充章节：同一份题目按级别挂不同 kpId
export const PRO_EXTRA_CHAPTERS: BankChapter[] = [
  // 初级
  { kpId: 'kp-beginner-storage', questions: STORAGE_QUESTIONS },
  { kpId: 'kp-beginner-health', questions: HEALTH_QUESTIONS },
  { kpId: 'kp-beginner-toilet', questions: TOILET_QUESTIONS },
  { kpId: 'kp-beginner-meal', questions: MEAL_BEGINNER_QUESTIONS },
  { kpId: 'kp-beginner-sleep', questions: SLEEP_QUESTIONS },
  { kpId: 'kp-beginner-clean', questions: CLEAN_QUESTIONS },
  { kpId: 'kp-beginner-disinfect', questions: DISINFECT_QUESTIONS },
  { kpId: 'kp-beginner-activity', questions: ACTIVITY_QUESTIONS },
  // 中级
  { kpId: 'kp-intermediate-health', questions: HEALTH_QUESTIONS },
  { kpId: 'kp-intermediate-toilet', questions: TOILET_QUESTIONS },
  { kpId: 'kp-intermediate-sleep', questions: SLEEP_QUESTIONS },
  { kpId: 'kp-intermediate-clean', questions: CLEAN_QUESTIONS },
  { kpId: 'kp-intermediate-disinfect', questions: DISINFECT_QUESTIONS },
  { kpId: 'kp-intermediate-activity', questions: ACTIVITY_QUESTIONS },
  // 高级
  { kpId: 'kp-advanced-injury', questions: INJURY_QUESTIONS },
  { kpId: 'kp-advanced-toilet', questions: TOILET_QUESTIONS },
  { kpId: 'kp-advanced-meal', questions: MEAL_ADVANCED_QUESTIONS },
  { kpId: 'kp-advanced-clean', questions: CLEAN_QUESTIONS },
  { kpId: 'kp-advanced-disinfect', questions: DISINFECT_QUESTIONS },
  { kpId: 'kp-advanced-training', questions: TRAINING_QUESTIONS },
  { kpId: 'kp-advanced-activity', questions: ACTIVITY_QUESTIONS }
];
