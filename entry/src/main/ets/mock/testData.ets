import { TestQuestion } from './types';

// ==================== 模拟题库数据库 ====================

const MOCK_DATABASE: Record<string, TestQuestion[]> = {
  // ---------- 溺水场景 ----------
  'drowning': [
    { id: 'd1', scenario: 'drowning', content: '发现有人溺水，救上岸后第一步做什么？', options: ['A. 立即控水', 'B. 判断意识和呼吸', 'C. 胸外按压', 'D. 大声呼救'], answer: 1 },
    { id: 'd2', scenario: 'drowning', content: '溺水者无呼吸心跳时，心肺复苏的正确顺序是？', options: ['A. 人工呼吸先于胸外按压', 'B. 胸外按压先于人工呼吸', 'C. 两者同时进行', 'D. 先拨打120再做操作'], answer: 1 },
    { id: 'd3', scenario: 'drowning', content: '如果溺水者还有呼吸，应该让他保持什么姿势？', options: ['A. 平躺', 'B. 俯卧', 'C. 侧卧位', 'D. 坐姿'], answer: 2 },
    { id: 'd4', scenario: 'drowning', content: '在施救过程中，如果溺水者发生呕吐，应该怎么做？', options: ['A. 继续按压', 'B. 把头偏向一侧清理口腔', 'C. 立即停止一切操作', 'D. 喂水稀释'], answer: 1 },
    { id: 'd5', scenario: 'drowning', content: '以下哪种情况绝对不应该尝试下水救人？', options: ['A. 会游泳', 'B. 有救生设备', 'C. 水流湍急且自己水性不好', 'D. 有人陪同'], answer: 2 },
    { id: 'd6', scenario: 'drowning', content: '如果现场没有AED，应该持续做心肺复苏直到？', options: ['A. 5分钟', 'B. 救护车到达或患者恢复自主呼吸', 'C. 10分钟', 'D. 自己累了'], answer: 1 },
    { id: 'd7', scenario: 'drowning', content: '溺水者被救上岸后即使看起来没事，是否应该就医？', options: ['A. 不需要，没事就不用管', 'B. 需要，可能存在继发性溺水风险', 'C. 回家休息就行', 'D. 喝口热水就好'], answer: 1 },
    { id: 'd8', scenario: 'drowning', content: '对溺水者进行人工呼吸前，首先要做什么？', options: ['A. 直接吹气', 'B. 开放气道（仰头抬颏法）', 'C. 先做胸外按压', 'D. 喂水'], answer: 1 },
    { id: 'd9', scenario: 'drowning', content: '儿童溺水后出现昏迷但仍有呼吸脉搏时，应如何处理？', options: ['A. 立即开始胸外按压', 'B. 保持侧卧位，密切观察呼吸，尽快送医', 'C. 倒挂控水', 'D. 喂热水'], answer: 1 },
    { id: 'd10', scenario: 'drowning', content: '以下关于溺水急救的说法，哪项是正确的？', options: ['A. 控水是溺水急救的第一步', 'B. 溺水急救核心是尽快恢复氧合，立即开始CPR', 'C. 溺水者吐出来的水说明已经抢救成功', 'D. 只要溺水者醒了就不需要就医'], answer: 1 },
  ],


  // ---------- 气道异物梗阻场景（未满1岁婴儿） ----------
  'choking_under_1': [
    { id: 'cu1', scenario: 'choking_under_1', content: '1岁以下婴儿发生气道异物梗阻，首先应该做什么？', options: ['A. 立即喂水冲下去', 'B. 5次背部叩击', 'C. 用手抠喉咙', 'D. 摇晃婴儿'], answer: 1 },
    { id: 'cu2', scenario: 'choking_under_1', content: '对1岁以下婴儿实施背部叩击时，应该将婴儿放在什么位置？', options: ['A. 仰卧在大人腿上', 'B. 俯卧在大人前臂上，头低脚高', 'C. 竖抱在肩上', 'D. 平躺在地板上'], answer: 1 },
    { id: 'cu3', scenario: 'choking_under_1', content: '婴儿背部叩击应该用多大力度？', options: ['A. 用最大力气猛击', 'B. 用力足够大但不至于造成损伤的坚定力量', 'C. 轻轻抚摸即可', 'D. 随便拍拍就行'], answer: 1 },
    { id: 'cu4', scenario: 'choking_under_1', content: '婴儿背部叩击5次后异物未排出，下一步应该做什么？', options: ['A. 继续拍背', 'B. 进行5次胸部冲击（胸骨下半部按压）', 'C. 喂水', 'D. 等待婴儿自己咳出'], answer: 1 },
    { id: 'cu5', scenario: 'choking_under_1', content: '对婴儿实施胸部冲击时，按压部位在哪里？', options: ['A. 肚脐位置', 'B. 两乳头连线中点下方的胸骨', 'C. 胸口最上面', 'D. 侧腹部'], answer: 1 },
    { id: 'cu6', scenario: 'choking_under_1', content: '如果婴儿在异物梗阻后失去意识，应该怎么做？', options: ['A. 继续拍背', 'B. 立即开始心肺复苏（CPR）并拨打120', 'C. 等它自己恢复', 'D. 喂糖水'], answer: 1 },
    { id: 'cu7', scenario: 'choking_under_1', content: '1岁以下婴儿气道异物梗阻时，为什么不能使用海姆立克腹部冲击法？', options: ['A. 婴儿太小腹部冲击可能造成内脏损伤', 'B. 婴儿不会梗阻', 'C. 腹部冲击对婴儿无效但安全', 'D. 应该用更大的力气'], answer: 0 },
    { id: 'cu8', scenario: 'choking_under_1', content: '预防1岁以下婴儿气道异物梗阻，以下哪种做法是正确的？', options: ['A. 给婴儿吃整颗葡萄和坚果', 'B. 将食物切成小块，避免给硬糖、坚果等小物件', 'C. 让婴儿边吃边玩', 'D. 不需要特别注意'], answer: 1 }
  ],

  // ---------- 气道异物梗阻场景（1岁以上儿童及成人） ----------
  'choking_over_1': [
    { id: 'co1', scenario: 'choking_over_1', content: '成年人发生气道异物梗阻，出现"V"字形手势（双手掐脖子）表示什么？', options: ['A. 他在打招呼', 'B. 他正在呼吸困难/气道梗阻', 'C. 他在做手势舞', 'D. 他肚子疼'], answer: 1 },
    { id: 'co2', scenario: 'choking_over_1', content: '对意识清醒的成年人实施海姆立克急救法时，施救者应该站在什么位置？', options: ['A. 站在患者正面', 'B. 站在患者身后', 'C. 站在患者侧面', 'D. 站在患者前面'], answer: 1 },
    { id: 'co3', scenario: 'choking_over_1', content: '海姆立克急救法的正确按压部位是哪里？', options: ['A. 肚脐正下方', 'B. 剑突与肚脐连线中点（肚脐上方两横指）', 'C. 胸口正中', 'D. 肋骨边缘'], answer: 1 },
    { id: 'co4', scenario: 'choking_over_1', content: '实施海姆立克急救法时，手的正确姿势是？', options: ['A. 手掌平拍背部', 'B. 握拳，拳眼对准腹部，另一手包住拳头', 'C. 用手指戳喉咙', 'D. 双手交叉按在胸口'], answer: 1 },
    { id: 'co5', scenario: 'choking_over_1', content: '海姆立克急救法的动作方向应该是？', options: ['A. 向下向内', 'B. 向上向内（快速冲击）', 'C. 向外拉', 'D. 向下压'], answer: 1 },
    { id: 'co6', scenario: 'choking_over_1', content: '如果气道梗阻患者在海姆立克急救后失去意识，应该怎么做？', options: ['A. 继续做海姆立克', 'B. 将患者平放，开始心肺复苏（CPR）', 'C. 喂水', 'D. 等待救护车'], answer: 1 },
    { id: 'co7', scenario: 'choking_over_1', content: '孕妇或肥胖者发生气道异物梗阻，海姆立克急救法的按压部位应该怎么做调整？', options: ['A. 仍然按在腹部', 'B. 改为胸部冲击法（按压胸骨中部）', 'C. 停止急救', 'D. 用力更大'], answer: 1 },
    { id: 'co8', scenario: 'choking_over_1', content: '以下哪种情况不适合使用海姆立克急救法？', options: ['A. 完全性气道梗阻', 'B. 患者已经失去意识', 'C. 部分性气道梗阻但能咳嗽说话', 'D. B和C都对'], answer: 3 },
    { id: 'co9', scenario: 'choking_over_1', content: '对1岁以上儿童实施海姆立克急救法时，力度应该如何控制？', options: ['A. 和成人一样用力', 'B. 根据儿童体型适当减小力度，但要保持快速冲击', 'C. 轻轻碰一下就行', 'D. 不需要管力度'], answer: 1 },
    { id: 'co10', scenario: 'choking_over_1', content: '即使海姆立克急救成功排出了异物，是否还需要去医院检查？', options: ['A. 不需要，排出了就没事了', 'B. 需要，可能有残留异物或内部损伤', 'C. 看心情', 'D. 等明天再说'], answer: 1 }
  ],

  'choking': [
    { id: 'cu1', scenario: 'choking_under_1', content: '1岁以下婴儿发生气道异物梗阻，首先应该做什么？', options: ['A. 立即喂水冲下去', 'B. 5次背部叩击', 'C. 用手抠喉咙', 'D. 摇晃婴儿'], answer: 1 },
    { id: 'cu2', scenario: 'choking_under_1', content: '对1岁以下婴儿实施背部叩击时，应该将婴儿放在什么位置？', options: ['A. 仰卧在大人腿上', 'B. 俯卧在大人前臂上，头低脚高', 'C. 竖抱在肩上', 'D. 平躺在地板上'], answer: 1 },
    { id: 'cu3', scenario: 'choking_under_1', content: '婴儿背部叩击应该用多大力度？', options: ['A. 用最大力气猛击', 'B. 用力足够大但不至于造成损伤的坚定力量', 'C. 轻轻抚摸即可', 'D. 随便拍拍就行'], answer: 1 },
    { id: 'cu4', scenario: 'choking_under_1', content: '婴儿背部叩击5次后异物未排出，下一步应该做什么？', options: ['A. 继续拍背', 'B. 进行5次胸部冲击（胸骨下半部按压）', 'C. 喂水', 'D. 等待婴儿自己咳出'], answer: 1 },
    { id: 'cu5', scenario: 'choking_under_1', content: '对婴儿实施胸部冲击时，按压部位在哪里？', options: ['A. 肚脐位置', 'B. 两乳头连线中点下方的胸骨', 'C. 胸口最上面', 'D. 侧腹部'], answer: 1 },
    { id: 'cu6', scenario: 'choking_under_1', content: '如果婴儿在异物梗阻后失去意识，应该怎么做？', options: ['A. 继续拍背', 'B. 立即开始心肺复苏（CPR）并拨打120', 'C. 等它自己恢复', 'D. 喂糖水'], answer: 1 },
    { id: 'cu7', scenario: 'choking_under_1', content: '1岁以下婴儿气道异物梗阻时，为什么不能使用海姆立克腹部冲击法？', options: ['A. 婴儿太小腹部冲击可能造成内脏损伤', 'B. 婴儿不会梗阻', 'C. 腹部冲击对婴儿无效但安全', 'D. 应该用更大的力气'], answer: 0 },
    { id: 'cu8', scenario: 'choking_under_1', content: '预防1岁以下婴儿气道异物梗阻，以下哪种做法是正确的？', options: ['A. 给婴儿吃整颗葡萄和坚果', 'B. 将食物切成小块，避免给硬糖、坚果等小物件', 'C. 让婴儿边吃边玩', 'D. 不需要特别注意'], answer: 1 },
    { id: 'co9', scenario: 'choking_over_1', content: '成年人发生气道异物梗阻，出现"V"字形手势（双手掐脖子）表示什么？', options: ['A. 他在打招呼', 'B. 他正在呼吸困难/气道梗阻', 'C. 他在做手势舞', 'D. 他肚子疼'], answer: 1 },
    { id: 'co10', scenario: 'choking_over_1', content: '对意识清醒的成年人实施海姆立克急救法时，施救者应该站在什么位置？', options: ['A. 站在患者正面', 'B. 站在患者身后', 'C. 站在患者侧面', 'D. 站在患者前面'], answer: 1 },
    { id: 'co11', scenario: 'choking_over_1', content: '海姆立克急救法的正确按压部位是哪里？', options: ['A. 肚脐正下方', 'B. 剑突与肚脐连线中点（肚脐上方两横指）', 'C. 胸口正中', 'D. 肋骨边缘'], answer: 1 },
    { id: 'co12', scenario: 'choking_over_1', content: '实施海姆立克急救法时，手的正确姿势是？', options: ['A. 手掌平拍背部', 'B. 握拳，拳眼对准腹部，另一手包住拳头', 'C. 用手指戳喉咙', 'D. 双手交叉按在胸口'], answer: 1 },
    { id: 'co13', scenario: 'choking_over_1', content: '海姆立克急救法的动作方向应该是？', options: ['A. 向下向内', 'B. 向上向内（快速冲击）', 'C. 向外拉', 'D. 向下压'], answer: 1 },
    { id: 'co14', scenario: 'choking_over_1', content: '如果气道梗阻患者在海姆立克急救后失去意识，应该怎么做？', options: ['A. 继续做海姆立克', 'B. 将患者平放，开始心肺复苏（CPR）', 'C. 喂水', 'D. 等待救护车'], answer: 1 },
    { id: 'co15', scenario: 'choking_over_1', content: '孕妇或肥胖者发生气道异物梗阻，海姆立克急救法的按压部位应该怎么做调整？', options: ['A. 仍然按在腹部', 'B. 改为胸部冲击法（按压胸骨中部）', 'C. 停止急救', 'D. 用力更大'], answer: 1 },
    { id: 'co16', scenario: 'choking_over_1', content: '以下哪种情况不适合使用海姆立克急救法？', options: ['A. 完全性气道梗阻', 'B. 患者已经失去意识', 'C. 部分性气道梗阻但能咳嗽说话', 'D. B和C都对'], answer: 3 },
    { id: 'co17', scenario: 'choking_over_1', content: '对1岁以上儿童实施海姆立克急救法时，力度应该如何控制？', options: ['A. 和成人一样用力', 'B. 根据儿童体型适当减小力度，但要保持快速冲击', 'C. 轻轻碰一下就行', 'D. 不需要管力度'], answer: 1 },
    { id: 'co18', scenario: 'choking_over_1', content: '即使海姆立克急救成功排出了异物，是否还需要去医院检查？', options: ['A. 不需要，排出了就没事了', 'B. 需要，可能有残留异物或内部损伤', 'C. 看心情', 'D. 等明天再说'], answer: 1 }
  ],

  // ---------- 心肺复苏场景 ----------
  'cpr': [
    { id: 'r1', scenario: 'cpr', content: '发现有人倒地，第一步应该做什么？', options: ['A. 立即开始胸外按压', 'B. 判断现场安全和患者意识', 'C. 拨打120等待', 'D. 给患者喂水'], answer: 1 },
    { id: 'r2', scenario: 'cpr', content: '心肺复苏的正确按压频率是？', options: ['A. 60-80次/分钟', 'B. 100-120次/分钟', 'C. 120-140次/分钟', 'D. 80-100次/分钟'], answer: 1 },
    { id: 'r3', scenario: 'cpr', content: '使用AED前需要做什么？', options: ['A. 直接贴电极片', 'B. 擦干患者胸部，开机后按语音提示操作', 'C. 先人工呼吸再贴电极片', 'D. 不需要做任何准备'], answer: 1 },
    { id: 'r4', scenario: 'cpr', content: '心肺复苏的按压与人工呼吸比例是？', options: ['A. 15:2', 'B. 30:2', 'C. 20:2', 'D. 30:5'], answer: 1 },
    { id: 'r5', scenario: 'cpr', content: '胸外按压的正确部位是？', options: ['A. 心尖部', 'B. 两乳头连线中点（胸骨中下部）', 'C. 剑突处', 'D. 左侧胸部'], answer: 1 },
    { id: 'r6', scenario: 'cpr', content: '进行胸外按压时，按压深度应该是多少？', options: ['A. 2-3厘米', 'B. 至少5厘米但不超过6厘米', 'C. 8-10厘米', 'D. 越深越好'], answer: 1 },
    { id: 'r7', scenario: 'cpr', content: '按压时手掌的正确位置是？', options: ['A. 双手交叉重叠，掌根置于按压部位', 'B. 单手手掌平拍', 'C. 用手指按压', 'D. 用拳头敲击'], answer: 0 },
    { id: 'r8', scenario: 'cpr', content: '对婴儿实施心肺复苏时，按压部位在哪里？', options: ['A. 肚脐位置', 'B. 两乳头连线中点下方的胸骨', 'C. 胸口最上面', 'D. 侧腹部'], answer: 1 },
    { id: 'r9', scenario: 'cpr', content: '单人施救时，人工呼吸每次吹气应该持续多长时间？', options: ['A. 不到1秒', 'B. 超过1秒，看到胸部起伏即可', 'C. 持续吹气5秒', 'D. 越快越好'], answer: 1 },
    { id: 'r10', scenario: 'cpr', content: '以下关于AED使用的说法，哪项是错误的？', options: ['A. AED开机后按照语音提示操作即可', 'B. 贴电极片前需要擦干患者胸部', 'C. 可以在患者还在运动时贴电极片分析心律', 'D. AED会自动判断是否需要电击'], answer: 2 },
  ],

  // ---------- 烫伤与烧伤场景 ----------
  'burn': [
    { id: 'b1', scenario: 'burn', content: '烫伤后第一步应该怎么做？', options: ['A. 涂抹药膏', 'B. 用冷水冲洗伤处15-30分钟', 'C. 挑破水泡', 'D. 用冰块直接敷'], answer: 1 },
    { id: 'b2', scenario: 'burn', content: '烫伤后是否可以自行挑破水泡？', options: ['A. 可以，有助于恢复', 'B. 不可以，容易感染', 'C. 视水泡大小而定', 'D. 用针消毒后挑破'], answer: 1 },
    { id: 'b3', scenario: 'burn', content: '烫伤后可以用冰块直接敷在伤处吗？', options: ['A. 可以，冰敷效果好', 'B. 不可以，会造成冻伤', 'C. 可以，但时间要短', 'D. 视烫伤程度而定'], answer: 1 },
    { id: 'b4', scenario: 'burn', content: '烫伤后脱去衣物时应该注意什么？', options: ['A. 用力快速撕脱', 'B. 在水中小心剪开，切勿强行撕扯粘连部分', 'C. 不管它，等医生来处理', 'D. 用热水泡软后撕脱'], answer: 1 },
    { id: 'b5', scenario: 'burn', content: '烫伤后应该用什么样的材料覆盖伤口？', options: ['A. 棉花', 'B. 干净的纱布或毛巾', 'C. 纸巾', 'D. 塑料袋'], answer: 1 },
    { id: 'b6', scenario: 'burn', content: '以下哪种烫伤需要立即送医？', options: ['A. 手指被开水烫红', 'B. 大面积烫伤或烫伤部位在面部、关节、生殖器等特殊部位', 'C. 小面积发红无水泡', 'D. 被蒸汽轻微烫到'], answer: 1 },
    { id: 'b7', scenario: 'burn', content: '化学烧伤（如强酸强碱溅到皮肤）第一步应该怎么做？', options: ['A. 用布擦干', 'B. 用大量流动清水持续冲洗至少20分钟', 'C. 涂抹中和药物', 'D. 用热水洗'], answer: 1 },
    { id: 'b8', scenario: 'burn', content: '电击烧伤与普通烫伤相比，有什么特殊之处？', options: ['A. 没有特殊之处', 'B. 表面伤口可能很小但内部组织损伤严重，需立即就医', 'C. 不需要就医', 'D. 自己涂药就好'], answer: 1 },
    { id: 'b9', scenario: 'burn', content: '烫伤后涂抹牙膏、酱油、香油等偏方是否正确？', options: ['A. 正确，这些都是传统有效方法', 'B. 不正确，可能引起感染并影响医生判断伤情', 'C. 视情况而定', 'D. 只可以涂牙膏'], answer: 1 },
    { id: 'b10', scenario: 'burn', content: '判断烫伤程度时，三度烫伤的特征是？', options: ['A. 皮肤发红、疼痛明显', 'B. 出现水泡', 'C. 皮肤呈焦黑色或苍白，痛觉可能减退', 'D. 皮肤轻微发红'], answer: 2 },
  ],

  // ---------- 跌倒与头部外伤场景 ----------
  'fall': [
    { id: 'f1', scenario: 'fall', content: '发现有人跌倒后，第一步应该做什么？', options: ['A. 立即扶起患者', 'B. 判断患者意识和伤情', 'C. 拨打120等待', 'D. 给患者喂水'], answer: 1 },
    { id: 'f2', scenario: 'fall', content: '头部外伤出血时，应该怎么做？', options: ['A. 用脏布捂住', 'B. 用干净纱布加压包扎', 'C. 不处理等它自己好', 'D. 用嘴吸出血液'], answer: 1 },
    { id: 'f3', scenario: 'fall', content: '怀疑脊柱受伤时，是否可以随意搬动患者？', options: ['A. 可以，越快越好', 'B. 不可以，应等待专业医护人员', 'C. 可以，但动作要轻', 'D. 只可以移动头部'], answer: 1 },
    { id: 'f4', scenario: 'fall', content: '患者跌倒后出现剧烈头痛、呕吐，可能是什么情况？', options: ['A. 正常反应', 'B. 颅内出血', 'C. 低血糖', 'D. 中暑'], answer: 1 },
    { id: 'f5', scenario: 'fall', content: '老年人跌倒后即使看起来没事，是否应该就医检查？', options: ['A. 不需要', 'B. 需要，可能存在隐性损伤', 'C. 看心情', 'D. 休息一天再说'], answer: 1 },
    { id: 'f6', scenario: 'fall', content: '患者跌倒后出现腿部变形、剧烈疼痛，可能是什么伤情？', options: ['A. 软组织挫伤', 'B. 骨折', 'C. 肌肉拉伤', 'D. 正常反应'], answer: 1 },
    { id: 'f7', scenario: 'fall', content: '发现有人跌倒后出现意识丧失但有正常呼吸，应该采取什么体位？', options: ['A. 仰卧位', 'B. 侧卧位（恢复体位）', 'C. 俯卧位', 'D. 坐位'], answer: 1 },
    { id: 'f8', scenario: 'fall', content: '以下哪种跌倒后的情况需要立即拨打120？', options: ['A. 膝盖轻微擦伤', 'B. 意识模糊、言语不清、一侧肢体无力', 'C. 手臂轻微淤青', 'D. 轻微头痛'], answer: 1 },
    { id: 'f9', scenario: 'fall', content: '为预防老年人跌倒，以下哪项措施是最有效的？', options: ['A. 少出门', 'B. 居家环境改造（防滑、安装扶手、改善照明）+ 适度锻炼增强肌力', 'C. 一直卧床休息', 'D. 只吃钙片'], answer: 1 },
    { id: 'f10', scenario: 'fall', content: '患者跌倒后头部着地，即使当时没事，后续应该注意什么？', options: ['A. 完全不用担心', 'B. 观察24-48小时，如出现头痛加剧、呕吐、嗜睡等症状应立即就医', 'C. 睡一觉就好了', 'D. 吃止痛药就行'], answer: 1 },
  ],

  // ---------- 误服与异物摄入场景 ----------
  'ingestion': [
    { id: 'i1', scenario: 'ingestion', content: '发现有人误服物品，首先应该做什么？', options: ['A. 立即催吐', 'B. 确认误服了什么物品、剂量和时间', 'C. 喂牛奶稀释', 'D. 不管它'], answer: 1 },
    { id: 'i2', scenario: 'ingestion', content: '误服腐蚀性物品（如洁厕灵）时，是否可以催吐？', options: ['A. 可以，必须催吐', 'B. 不可以，会加重食道损伤', 'C. 可以，但要用清水催吐', 'D. 视情况而定'], answer: 1 },
    { id: 'i3', scenario: 'ingestion', content: '误服药物后应该保留什么证据带往医院？', options: ['A. 不需要保留', 'B. 误服物品的包装或容器', 'C. 患者的身份证', 'D. 病历本'], answer: 1 },
    { id: 'i4', scenario: 'ingestion', content: '误服异物后应该拨打什么电话？', options: ['A. 110', 'B. 120或联系中毒控制中心', 'C. 物业电话', 'D. 不需要打电话'], answer: 1 },
    { id: 'i5', scenario: 'ingestion', content: '儿童误服硬币等异物，是否应该自行处理？', options: ['A. 可以，多喝水就行', 'B. 不可以，应立即就医', 'C. 可以，等它自己排出来', 'D. 可以，拍背就行'], answer: 1 },
    { id: 'i6', scenario: 'ingestion', content: '以下哪种误服情况绝对禁止催吐？', options: ['A. 误服了一片维生素', 'B. 误服了强酸、强碱或石油类产品', 'C. 误服了少量果汁', 'D. 误服了糖果'], answer: 1 },
    { id: 'i7', scenario: 'ingestion', content: '发现家人误服过量药物但意识清醒时，以下做法正确的是？', options: ['A. 立即大量催吐并观察', 'B. 立即拨打120，携带药物包装送医，在医生指导下处理', 'C. 喝大量牛奶催吐', 'D. 等患者自己吐出来'], answer: 1 },
    { id: 'i8', scenario: 'ingestion', content: '儿童误服药物后，即使没有明显症状是否也需要就医？', options: ['A. 没有症状就不用管', 'B. 需要，某些药物有延迟毒性反应', 'C. 喝口水就行', 'D. 睡一觉就好'], answer: 1 },
    { id: 'i9', scenario: 'ingestion', content: '预防儿童误服药物，以下哪种做法是最正确的？', options: ['A. 把药放在儿童看不到但拿不到的地方', 'B. 把药放在儿童可以拿到的抽屉里', 'C. 当着儿童面吃药让他们模仿', 'D. 用糖果盒子装药'], answer: 0 },
    { id: 'i10', scenario: 'ingestion', content: '误服药物后，以下哪种做法可能会加重中毒？', options: ['A. 立即就医', 'B. 大量饮水', 'C. 盲目催吐（尤其是意识不清或误服腐蚀性物质时）', 'D. 携带药物包装'], answer: 2 },
  ],

  // ---------- 发热惊厥（未满3月龄）场景 ----------
  'fever_under_3': [
    { id: 'fu1', scenario: 'fever_under_3', content: '3月龄以下婴儿出现惊厥，首先应该做什么？', options: ['A. 自行给药降温', 'B. 保持镇定，将孩子放在平坦柔软的地方', 'C. 摇晃孩子唤醒', 'D. 往孩子嘴里塞东西'], answer: 1 },
    { id: 'fu2', scenario: 'fever_under_3', content: '婴儿惊厥时应保持什么体位？', options: ['A. 仰卧位', 'B. 侧卧位，防止呕吐物堵塞气道', 'C. 俯卧位', 'D. 坐位'], answer: 1 },
    { id: 'fu3', scenario: 'fever_under_3', content: '3月龄以下婴儿惊厥是否应该立即就医？', options: ['A. 不需要', 'B. 必须立即送医，切勿自行处理', 'C. 观察半小时再说', 'D. 自行服药即可'], answer: 1 },
    { id: 'fu4', scenario: 'fever_under_3', content: '婴儿惊厥发作时，能否往孩子嘴里塞东西？', options: ['A. 可以，防止咬舌', 'B. 不可以，可能导致窒息', 'C. 可以，但要用纱布包着', 'D. 视情况而定'], answer: 1 },
    { id: 'fu5', scenario: 'fever_under_3', content: '婴儿惊厥持续多长时间必须叫救护车？', options: ['A. 超过1分钟', 'B. 超过5分钟', 'C. 超过10分钟', 'D. 不管多久都不用'], answer: 1 },
    { id: 'fu6', scenario: 'fever_under_3', content: '3月龄以下婴儿体温超过多少度应视为需要紧急就医的高热？', options: ['A. 37.5℃', 'B. 38℃', 'C. 39℃', 'D. 40℃'], answer: 1 },
    { id: 'fu7', scenario: 'fever_under_3', content: '婴儿惊厥发作时，家长不应该做什么？', options: ['A. 保持镇定', 'B. 记录惊厥开始时间和持续时间', 'C. 强行按压婴儿肢体制止抽搐', 'D. 将婴儿放在安全地方防止二次伤害'], answer: 2 },
    { id: 'fu8', scenario: 'fever_under_3', content: '以下关于婴儿发热的说法，哪项是正确的？', options: ['A. 婴儿发热很正常，不用在意', 'B. 3月龄以下婴儿发热可能是严重感染的信号，必须及时就医', 'C. 婴儿发热只需要物理降温', 'D. 婴儿不会发热'], answer: 1 },
  ],

  // ---------- 发热惊厥（3月龄及以上）场景 ----------
  'fever_over_3': [
    { id: 'fo1', scenario: 'fever_over_3', content: '孩子惊厥发作时，家长首先应该做什么？', options: ['A. 摇晃孩子', 'B. 保持镇定，移开周围硬物确保安全', 'C. 往嘴里塞东西', 'D. 立即喂水'], answer: 1 },
    { id: 'fo2', scenario: 'fever_over_3', content: '惊厥发作时，能否往孩子嘴里塞东西？', options: ['A. 可以，防止咬舌', 'B. 不可以，可能导致窒息或牙齿损伤', 'C. 可以，但要用勺子', 'D. 视情况而定'], answer: 1 },
    { id: 'fo3', scenario: 'fever_over_3', content: '物理降温时，推荐使用的擦拭水温是？', options: ['A. 冰水', 'B. 温水（32-34℃）', 'C. 热水', 'D. 酒精'], answer: 1 },
    { id: 'fo4', scenario: 'fever_over_3', content: '惊厥持续超过多少分钟必须叫救护车？', options: ['A. 超过1分钟', 'B. 超过5分钟', 'C. 超过10分钟', 'D. 超过30分钟'], answer: 1 },
    { id: 'fo5', scenario: 'fever_over_3', content: '惊厥停止后，孩子的体位应该是？', options: ['A. 仰卧位', 'B. 侧卧位', 'C. 俯卧位', 'D. 坐位'], answer: 1 },
    { id: 'fo6', scenario: 'fever_over_3', content: '热性惊厥多见于哪个年龄段的儿童？', options: ['A. 新生儿', 'B. 6个月至5岁', 'C. 青少年', 'D. 成年人'], answer: 1 },
    { id: 'fo7', scenario: 'fever_over_3', content: '孩子惊厥发作时，以下哪种做法是正确的？', options: ['A. 给孩子喂退烧药', 'B. 记录惊厥持续时间，松开衣物保持呼吸道通畅', 'C. 强行按住孩子不让动', 'D. 用扇子猛扇降温'], answer: 1 },
    { id: 'fo8', scenario: 'fever_over_3', content: '热性惊厥后，以下哪种说法是正确的？', options: ['A. 不会复发，不用担心', 'B. 部分孩子可能复发，但仍以良性为主，需就医排查原因', 'C. 一定会变成癫痫', 'D. 不需要就医'], answer: 1 },
    { id: 'fo9', scenario: 'fever_over_3', content: '给孩子使用退烧药时，以下哪种做法是正确的？', options: ['A. 两种退烧药交替使用效果更好', 'B. 按照体重计算剂量，不超量使用，必要时就医', 'C. 退烧药可以随便用', 'D. 酒精擦浴是最安全的退烧方式'], answer: 1 },
    { id: 'fo10', scenario: 'fever_over_3', content: '以下哪种发热情况需要立即就医而不是在家观察？', options: ['A. 体温38.5℃精神好', 'B. 3月龄以下婴儿体温≥38℃', 'C. 体温39℃吃了退烧药后下降', 'D. 轻微发热活动正常'], answer: 1 },
  ],

  'fever': [
    { id: 'fu1', scenario: 'fever_under_3', content: '3月龄以下婴儿出现惊厥，首先应该做什么？', options: ['A. 自行给药降温', 'B. 保持镇定，将孩子放在平坦柔软的地方', 'C. 摇晃孩子唤醒', 'D. 往孩子嘴里塞东西'], answer: 1 },
    { id: 'fu2', scenario: 'fever_under_3', content: '婴儿惊厥时应保持什么体位？', options: ['A. 仰卧位', 'B. 侧卧位，防止呕吐物堵塞气道', 'C. 俯卧位', 'D. 坐位'], answer: 1 },
    { id: 'fu3', scenario: 'fever_under_3', content: '3月龄以下婴儿惊厥是否应该立即就医？', options: ['A. 不需要', 'B. 必须立即送医，切勿自行处理', 'C. 观察半小时再说', 'D. 自行服药即可'], answer: 1 },
    { id: 'fu4', scenario: 'fever_under_3', content: '婴儿惊厥发作时，能否往孩子嘴里塞东西？', options: ['A. 可以，防止咬舌', 'B. 不可以，可能导致窒息', 'C. 可以，但要用纱布包着', 'D. 视情况而定'], answer: 1 },
    { id: 'fu5', scenario: 'fever_under_3', content: '婴儿惊厥持续多长时间必须叫救护车？', options: ['A. 超过1分钟', 'B. 超过5分钟', 'C. 超过10分钟', 'D. 不管多久都不用'], answer: 1 },
    { id: 'fu6', scenario: 'fever_under_3', content: '3月龄以下婴儿体温超过多少度应视为需要紧急就医的高热？', options: ['A. 37.5℃', 'B. 38℃', 'C. 39℃', 'D. 40℃'], answer: 1 },
    { id: 'fu7', scenario: 'fever_under_3', content: '婴儿惊厥发作时，家长不应该做什么？', options: ['A. 保持镇定', 'B. 记录惊厥开始时间和持续时间', 'C. 强行按压婴儿肢体制止抽搐', 'D. 将婴儿放在安全地方防止二次伤害'], answer: 2 },
    { id: 'fu8', scenario: 'fever_under_3', content: '以下关于婴儿发热的说法，哪项是正确的？', options: ['A. 婴儿发热很正常，不用在意', 'B. 3月龄以下婴儿发热可能是严重感染的信号，必须及时就医', 'C. 婴儿发热只需要物理降温', 'D. 婴儿不会发热'], answer: 1 },
    { id: 'fo9', scenario: 'fever_over_3', content: '孩子惊厥发作时，家长首先应该做什么？', options: ['A. 摇晃孩子', 'B. 保持镇定，移开周围硬物确保安全', 'C. 往嘴里塞东西', 'D. 立即喂水'], answer: 1 },
    { id: 'fo10', scenario: 'fever_over_3', content: '惊厥发作时，能否往孩子嘴里塞东西？', options: ['A. 可以，防止咬舌', 'B. 不可以，可能导致窒息或牙齿损伤', 'C. 可以，但要用勺子', 'D. 视情况而定'], answer: 1 },
    { id: 'fo11', scenario: 'fever_over_3', content: '物理降温时，推荐使用的擦拭水温是？', options: ['A. 冰水', 'B. 温水（32-34℃）', 'C. 热水', 'D. 酒精'], answer: 1 },
    { id: 'fo12', scenario: 'fever_over_3', content: '惊厥持续超过多少分钟必须叫救护车？', options: ['A. 超过1分钟', 'B. 超过5分钟', 'C. 超过10分钟', 'D. 超过30分钟'], answer: 1 },
    { id: 'fo13', scenario: 'fever_over_3', content: '惊厥停止后，孩子的体位应该是？', options: ['A. 仰卧位', 'B. 侧卧位', 'C. 俯卧位', 'D. 坐位'], answer: 1 },
    { id: 'fo14', scenario: 'fever_over_3', content: '热性惊厥多见于哪个年龄段的儿童？', options: ['A. 新生儿', 'B. 6个月至5岁', 'C. 青少年', 'D. 成年人'], answer: 1 },
    { id: 'fo15', scenario: 'fever_over_3', content: '孩子惊厥发作时，以下哪种做法是正确的？', options: ['A. 给孩子喂退烧药', 'B. 记录惊厥持续时间，松开衣物保持呼吸道通畅', 'C. 强行按住孩子不让动', 'D. 用扇子猛扇降温'], answer: 1 },
    { id: 'fo16', scenario: 'fever_over_3', content: '热性惊厥后，以下哪种说法是正确的？', options: ['A. 不会复发，不用担心', 'B. 部分孩子可能复发，但仍以良性为主，需就医排查原因', 'C. 一定会变成癫痫', 'D. 不需要就医'], answer: 1 },
    { id: 'fo17', scenario: 'fever_over_3', content: '给孩子使用退烧药时，以下哪种做法是正确的？', options: ['A. 两种退烧药交替使用效果更好', 'B. 按照体重计算剂量，不超量使用，必要时就医', 'C. 退烧药可以随便用', 'D. 酒精擦浴是最安全的退烧方式'], answer: 1 },
    { id: 'fo18', scenario: 'fever_over_3', content: '以下哪种发热情况需要立即就医而不是在家观察？', options: ['A. 体温38.5℃精神好', 'B. 3月龄以下婴儿体温≥38℃', 'C. 体温39℃吃了退烧药后下降', 'D. 轻微发热活动正常'], answer: 1 },
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