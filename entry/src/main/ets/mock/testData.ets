import { TestQuestion } from './types';

// ==================== 模拟题库数据库 ====================

const MOCK_DATABASE: Record<string, TestQuestion[]> = {
  // ---------- 溺水场景 ----------
  'drowning': [
    { id: 'd1', scenario: 'drowning', content: '发现有人溺水，救上岸后第一步做什么？', options: ['A. 立即控水', 'B. 判断意识和呼吸', 'C. 胸外按压', 'D. 大声呼救'], answer: 1 },
    { id: 'd2', scenario: 'drowning', content: '溺水者无呼吸心跳时，应先人工呼吸还是胸外按压？', options: ['A. 人工呼吸', 'B. 先胸外按压', 'C. 两者交替', 'D. 先拨打120'], answer: 1 },
    { id: 'd3', scenario: 'drowning', content: '如果溺水者还有呼吸，应该让他保持什么姿势？', options: ['A. 平躺', 'B. 俯卧', 'C. 侧卧', 'D. 坐姿'], answer: 2 },
    { id: 'd4', scenario: 'drowning', content: '在施救过程中，如果溺水者发生呕吐，应该怎么做？', options: ['A. 继续按压', 'B. 把头偏向一侧清理口腔', 'C. 立即停止一切操作', 'D. 喂水稀释'], answer: 1 },
    { id: 'd5', scenario: 'drowning', content: '以下哪种情况绝对不应该尝试下水救人？', options: ['A. 会游泳', 'B. 有救生设备', 'C. 水流湍急且自己水性不好', 'D. 有人陪同'], answer: 2 },
    { id: 'd6', scenario: 'drowning', content: '如果现场没有AED，应该持续做心肺复苏直到？', options: ['A. 5分钟', 'B. 救护车到达', 'C. 10分钟', 'D. 自己累了'], answer: 1 }
  ],

  // ---------- 气道异物梗阻场景 ----------
  'choking': [
    { id: 'c1', scenario: 'choking', content: '成年人发生气道异物梗阻，应使用哪种方法急救？', options: ['A. 海姆立克急救法', 'B. 人工呼吸', 'C. 喝水', 'D. 拍背'], answer: 0 },
    { id: 'c2', scenario: 'choking', content: '1岁以下婴儿发生气道异物梗阻，正确的做法是？', options: ['A. 海姆立克法', 'B. 拍背法', 'C. 抠喉咙', 'D. 让他自己咳'], answer: 1 },
    { id: 'c3', scenario: 'choking', content: '实施腹部冲击法时，按压部位在哪里？', options: ['A. 肚脐下方', 'B. 肚脐上方两横指处', 'C. 胸口正中', 'D. 胃部'], answer: 1 },
    { id: 'c4', scenario: 'choking', content: '如果气道梗阻患者失去意识，接下来该做什么？', options: ['A. 继续冲击', 'B. 开始心肺复苏', 'C. 喂水', 'D. 等待自行恢复'], answer: 1 },
    { id: 'c5', scenario: 'choking', content: '对婴儿实施背部叩击时，婴儿的体位应该是？', options: ['A. 仰卧位', 'B. 俯卧位，头低于躯干', 'C. 侧卧位', 'D. 坐位'], answer: 1 }
  ],

  // ---------- 心肺复苏场景 ----------
  'cpr': [
    { id: 'r1', scenario: 'cpr', content: '发现有人倒地，第一步应该做什么？', options: ['A. 立即开始胸外按压', 'B. 判断现场安全和患者意识', 'C. 拨打120等待', 'D. 给患者喂水'], answer: 1 },
    { id: 'r2', scenario: 'cpr', content: '心肺复苏的正确按压频率是？', options: ['A. 60-80次/分钟', 'B. 100-120次/分钟', 'C. 120-140次/分钟', 'D. 80-100次/分钟'], answer: 1 },
    { id: 'r3', scenario: 'cpr', content: '使用AED前需要做什么？', options: ['A. 直接贴电极片', 'B. 擦干患者胸部，开机后按语音提示操作', 'C. 先人工呼吸再贴电极片', 'D. 不需要做任何准备'], answer: 1 },
    { id: 'r4', scenario: 'cpr', content: '心肺复苏的按压与人工呼吸比例是？', options: ['A. 15:2', 'B. 30:2', 'C. 20:2', 'D. 30:5'], answer: 1 },
    { id: 'r5', scenario: 'cpr', content: '胸外按压的正确部位是？', options: ['A. 心尖部', 'B. 两乳头连线中点（胸骨中下部）', 'C. 剑突处', 'D. 左侧胸部'], answer: 1 }
  ],

  // ---------- 烫伤与烧伤场景 ----------
  'burn': [
    { id: 'b1', scenario: 'burn', content: '烫伤后第一步应该怎么做？', options: ['A. 涂抹药膏', 'B. 用冷水冲洗伤处15-30分钟', 'C. 挑破水泡', 'D. 用冰块直接敷'], answer: 1 },
    { id: 'b2', scenario: 'burn', content: '烫伤后是否可以自行挑破水泡？', options: ['A. 可以，有助于恢复', 'B. 不可以，容易感染', 'C. 视水泡大小而定', 'D. 用针消毒后挑破'], answer: 1 },
    { id: 'b3', scenario: 'burn', content: '烫伤后可以用冰块直接敷在伤处吗？', options: ['A. 可以，冰敷效果好', 'B. 不可以，会造成冻伤', 'C. 可以，但时间要短', 'D. 视烫伤程度而定'], answer: 1 },
    { id: 'b4', scenario: 'burn', content: '烫伤后脱去衣物时应该注意什么？', options: ['A. 用力快速撕脱', 'B. 在水中小心剪开，切勿强行撕扯粘连部分', 'C. 不管它，等医生来处理', 'D. 用热水泡软后撕脱'], answer: 1 },
    { id: 'b5', scenario: 'burn', content: '烫伤后应该用什么样的材料覆盖伤口？', options: ['A. 棉花', 'B. 干净的纱布或毛巾', 'C. 纸巾', 'D. 塑料袋'], answer: 1 }
  ],

  // ---------- 跌倒与头部外伤场景 ----------
  'fall': [
    { id: 'f1', scenario: 'fall', content: '发现有人跌倒后，第一步应该做什么？', options: ['A. 立即扶起患者', 'B. 判断患者意识和伤情', 'C. 拨打120等待', 'D. 给患者喂水'], answer: 1 },
    { id: 'f2', scenario: 'fall', content: '头部外伤出血时，应该怎么做？', options: ['A. 用脏布捂住', 'B. 用干净纱布加压包扎', 'C. 不处理等它自己好', 'D. 用嘴吸出血液'], answer: 1 },
    { id: 'f3', scenario: 'fall', content: '怀疑脊柱受伤时，是否可以随意搬动患者？', options: ['A. 可以，越快越好', 'B. 不可以，应等待专业医护人员', 'C. 可以，但动作要轻', 'D. 只可以移动头部'], answer: 1 },
    { id: 'f4', scenario: 'fall', content: '患者跌倒后出现剧烈头痛、呕吐，可能是什么情况？', options: ['A. 正常反应', 'B. 颅内出血', 'C. 低血糖', 'D. 中暑'], answer: 1 },
    { id: 'f5', scenario: 'fall', content: '老年人跌倒后即使看起来没事，是否应该就医检查？', options: ['A. 不需要', 'B. 需要，可能存在隐性损伤', 'C. 看心情', 'D. 休息一天再说'], answer: 1 }
  ],

  // ---------- 误服与异物摄入场景 ----------
  'ingestion': [
    { id: 'i1', scenario: 'ingestion', content: '发现有人误服物品，首先应该做什么？', options: ['A. 立即催吐', 'B. 确认误服了什么物品、剂量和时间', 'C. 喂牛奶稀释', 'D. 不管它'], answer: 1 },
    { id: 'i2', scenario: 'ingestion', content: '误服腐蚀性物品（如洁厕灵）时，是否可以催吐？', options: ['A. 可以，必须催吐', 'B. 不可以，会加重食道损伤', 'C. 可以，但要用清水催吐', 'D. 视情况而定'], answer: 1 },
    { id: 'i3', scenario: 'ingestion', content: '误服药物后应该保留什么证据带往医院？', options: ['A. 不需要保留', 'B. 误服物品的包装或容器', 'C. 患者的身份证', 'D. 病历本'], answer: 1 },
    { id: 'i4', scenario: 'ingestion', content: '误服异物后应该拨打什么电话？', options: ['A. 110', 'B. 120或联系中毒控制中心', 'C. 物业电话', 'D. 不需要打电话'], answer: 1 },
    { id: 'i5', scenario: 'ingestion', content: '儿童误服硬币等异物，是否应该自行处理？', options: ['A. 可以，多喝水就行', 'B. 不可以，应立即就医', 'C. 可以，等它自己排出来', 'D. 可以，拍背就行'], answer: 1 }
  ],

  // ---------- 发热惊厥（未满3月龄）场景 ----------
  'fever_under_3': [
    { id: 'fu1', scenario: 'fever_under_3', content: '3月龄以下婴儿出现惊厥，首先应该做什么？', options: ['A. 自行给药降温', 'B. 保持镇定，将孩子放在平坦柔软的地方', 'C. 摇晃孩子唤醒', 'D. 往孩子嘴里塞东西'], answer: 1 },
    { id: 'fu2', scenario: 'fever_under_3', content: '婴儿惊厥时应保持什么体位？', options: ['A. 仰卧位', 'B. 侧卧位，防止呕吐物堵塞气道', 'C. 俯卧位', 'D. 坐位'], answer: 1 },
    { id: 'fu3', scenario: 'fever_under_3', content: '3月龄以下婴儿惊厥是否应该立即就医？', options: ['A. 不需要', 'B. 必须立即送医，切勿自行处理', 'C. 观察半小时再说', 'D. 自行服药即可'], answer: 1 },
    { id: 'fu4', scenario: 'fever_under_3', content: '婴儿惊厥发作时，能否往孩子嘴里塞东西？', options: ['A. 可以，防止咬舌', 'B. 不可以，可能导致窒息', 'C. 可以，但要用纱布包着', 'D. 视情况而定'], answer: 1 },
    { id: 'fu5', scenario: 'fever_under_3', content: '婴儿惊厥持续多长时间必须叫救护车？', options: ['A. 超过1分钟', 'B. 超过5分钟', 'C. 超过10分钟', 'D. 不管多久都不用'], answer: 1 }
  ],

  // ---------- 发热惊厥（3月龄及以上）场景 ----------
  'fever_over_3': [
    { id: 'fo1', scenario: 'fever_over_3', content: '孩子惊厥发作时，家长首先应该做什么？', options: ['A. 摇晃孩子', 'B. 保持镇定，移开周围硬物确保安全', 'C. 往嘴里塞东西', 'D. 立即喂水'], answer: 1 },
    { id: 'fo2', scenario: 'fever_over_3', content: '惊厥发作时，能否往孩子嘴里塞东西？', options: ['A. 可以，防止咬舌', 'B. 不可以，可能导致窒息或牙齿损伤', 'C. 可以，但要用勺子', 'D. 视情况而定'], answer: 1 },
    { id: 'fo3', scenario: 'fever_over_3', content: '物理降温时，推荐使用的擦拭水温是？', options: ['A. 冰水', 'B. 温水（32-34℃）', 'C. 热水', 'D. 酒精'], answer: 1 },
    { id: 'fo4', scenario: 'fever_over_3', content: '惊厥持续超过多少分钟必须叫救护车？', options: ['A. 超过1分钟', 'B. 超过5分钟', 'C. 超过10分钟', 'D. 超过30分钟'], answer: 1 },
    { id: 'fo5', scenario: 'fever_over_3', content: '惊厥停止后，孩子的体位应该是？', options: ['A. 仰卧位', 'B. 侧卧位', 'C. 俯卧位', 'D. 坐位'], answer: 1 }
  ]
};

// ==================== Fisher-Yates 洗牌算法 ====================

function shuffleArray(array: TestQuestion[]): void {
  for (let i = array.length - 1; i > 0; i--) {

    const j = Math.floor(Math.random() * (i + 1));

    const temp = array[i];
    array[i] = array[j];
    array[j] = temp;
  }
}

// ==================== 核心函数：获取随机题目 ====================

export function fetchRandomQuestions(scenario: string): TestQuestion[] {
  // 获取对应场景的题目，如果没有就使用空数组
  const questions: TestQuestion[] = MOCK_DATABASE[scenario] || [];
  if (questions.length >= 5) {
    const copy = [...questions];  // 复制一份，避免修改原数据
    shuffleArray(copy);           // 打乱顺序
    return copy;
  }

  // 如果题目大于5道，截取并打乱前5道
  const copy = [...questions];
  shuffleArray(copy);
  return copy.slice(0, 5);
}