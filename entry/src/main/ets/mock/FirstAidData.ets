// 9个急救场景的步骤数据
import { FirstAidStep, ActionType } from './types';

// ==================== 1. 心肺复苏数据 (CPR) ====================
export const cprData: FirstAidStep[] = [
  { id: '1', title: '判断现场安全', description: '观察四周，确保施救环境对您和伤者都是安全的。', actionType: ActionType.TAP },
  { id: '2', title: '判断患者意识', description: '轻拍患者双肩，并在其耳边大声呼喊，观察有无反应。', actionType: ActionType.LONG_PRESS },
  { id: '3', title: '呼救并取AED', description: '指定现场一人拨打120，并让另一人去取最近的AED（自动体外除颤器）。', actionType: ActionType.TAP },
  { id: '4', title: '检查呼吸', description: '俯身观察患者胸腹部起伏5-10秒，判断有无正常呼吸。', actionType: ActionType.LONG_PRESS },
  { id: '5', title: '胸外按压', description: '双手交叠，掌根置于两乳头连线中点，垂直向下用力按压。', actionType: ActionType.LONG_PRESS },
  { id: '6', title: '开放气道', description: '一手压额，另一手抬起下颏，使头部后仰，打开气道。', actionType: ActionType.TAP },
  { id: '7', title: '人工呼吸', description: '捏住患者鼻子，口对口包住，平稳吹气2次，每次1秒，看到胸廓起伏即可。', actionType: ActionType.TAP }
];

// ==================== 2. 气道异物梗阻 - 未满1岁 (婴儿) ====================
export const chokingUnder1Data: FirstAidStep[] = [
  { id: '1', title: '评估与呼救', description: '判断婴儿是否无法哭、咳嗽或呼吸，立即大声呼救并让他人拨打120。', actionType: ActionType.TAP },
  { id: '2', title: '背部叩击', description: '将婴儿俯卧于前臂，头低于躯干，用手掌根部在婴儿背部肩胛骨之间用力叩击5次。', actionType: ActionType.LONG_PRESS },
  { id: '3', title: '胸部冲击', description: '将婴儿翻转仰卧，用两指在胸部正中（乳头连线下方）快速按压5次。', actionType: ActionType.LONG_PRESS },
  { id: '4', title: '循环操作', description: '重复"5次背部叩击"和"5次胸部冲击"，直到异物排出或婴儿失去意识。', actionType: ActionType.TAP }
];

// ==================== 3. 气道异物梗阻 - 满1岁至6岁 (儿童) ====================
export const chokingOver1Data: FirstAidStep[] = [
  { id: '1', title: '评估与鼓励', description: '询问"你被噎住了吗？"，如果儿童能咳嗽，鼓励其用力咳嗽。', actionType: ActionType.TAP },
  { id: '2', title: '准备实施海姆立克', description: '如果儿童无法咳嗽或发声，立即站到其身后，准备实施腹部冲击。', actionType: ActionType.TAP },
  { id: '3', title: '腹部冲击', description: '一手握拳，拳眼对准肚脐上方两横指处，另一手包住拳头，快速向内、向上冲击。', actionType: ActionType.LONG_PRESS },
  { id: '4', title: '循环操作', description: '重复进行腹部冲击，直到异物排出或儿童失去意识。', actionType: ActionType.TAP }
];

// ==================== 4. 溺水数据 ====================
export const drowningData: FirstAidStep[] = [
  { id: '1', title: '安全评估与呼救', description: '确保自身安全，大声呼救并拨打120。', actionType: ActionType.TAP },
  { id: '2', title: '清理口鼻异物', description: '将溺水者头部侧向一边，清理口鼻中的泥沙和水草。', actionType: ActionType.LONG_PRESS },
  { id: '3', title: '开放气道', description: '使用仰头举颏法，打开溺水者的气道。', actionType: ActionType.TAP }
];

// ==================== 5. 烫伤与烧伤数据 ====================
export const burnData: FirstAidStep[] = [
  { id: '1', title: '冲', description: '立即用流动的冷水冲洗伤处15-30分钟，直到疼痛缓解。', actionType: ActionType.LONG_PRESS },
  { id: '2', title: '脱', description: '在水中小心剪开并脱去衣物，切勿强行撕扯粘连部分。', actionType: ActionType.TAP },
  { id: '3', title: '盖', description: '用干净的纱布或毛巾覆盖伤口，避免感染。', actionType: ActionType.TAP }
];

// ==================== 6. 跌倒与头部外伤数据 ====================
export const fallData: FirstAidStep[] = [
  { id: '1', title: '判断意识', description: '轻拍双肩，大声呼唤，判断伤者是否有意识。', actionType: ActionType.LONG_PRESS },
  { id: '2', title: '检查伤情', description: '检查头部是否有明显外伤、出血或凹陷。', actionType: ActionType.TAP },
  { id: '3', title: '保持静止', description: '不要随意搬动伤者，等待专业医护人员到来。', actionType: ActionType.TAP }
];

// ==================== 7. 误服与异物摄入数据 ====================
export const ingestionData: FirstAidStep[] = [
  { id: '1', title: '确认误服物', description: '迅速确认误服的是什么物品、剂量和时间。', actionType: ActionType.TAP },
  { id: '2', title: '保留证据', description: '保留好误服物品的包装或容器，带往医院。', actionType: ActionType.TAP },
  { id: '3', title: '联系急救', description: '立即拨打120或联系中毒控制中心，切勿自行催吐。', actionType: ActionType.LONG_PRESS }
];

// ==================== 8. 发热惊厥 (未满3月龄) 数据 ====================
export const feverUnder3Data: FirstAidStep[] = [
  { id: '1', title: '保持镇定', description: '将孩子放在平坦、柔软的地方，解开衣领。', actionType: ActionType.TAP },
  { id: '2', title: '侧卧防窒息', description: '让孩子保持侧卧位，防止呕吐物堵塞气道。', actionType: ActionType.TAP },
  { id: '3', title: '立即就医', description: '3月龄以下婴儿惊厥，必须立即送医，切勿自行处理。', actionType: ActionType.LONG_PRESS }
];

// ==================== 9. 发热惊厥 (3月龄及以上) 数据 ====================
export const feverOver3Data: FirstAidStep[] = [
  { id: '1', title: '确保安全', description: '移开周围的硬物，防止孩子在抽搐时受伤。', actionType: ActionType.TAP },
  { id: '2', title: '记录时间', description: '记录惊厥开始和持续的时间，观察抽搐形式。', actionType: ActionType.LONG_PRESS },
  { id: '3', title: '降温处理', description: '惊厥停止后，可采用物理降温，并及时就医。', actionType: ActionType.TAP }
];