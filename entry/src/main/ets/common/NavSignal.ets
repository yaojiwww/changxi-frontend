import { AppStorageV2 } from '@kit.ArkUI';
import { AIAskContext } from '../model/ChatModels';

// 跨页跳转信号：某个页面想切到首页的指定底部页签时写入，
// 首页 onPageShow 读取后立即复位（-1 = 无待处理跳转）
@ObservedV2
export class NavSignal {
  @Trace pendingTab: number = -1;
  // 从 AI 知识库带过来的提问上下文。AI 伴学页读取后立即清空，只消费一次
  @Trace pendingAsk: AIAskContext | null = null;
}

// 写入待处理的页签跳转（1 = AI 伴学）
export function signalPendingTab(index: number): void {
  const s = AppStorageV2.connect(NavSignal, () => new NavSignal())!;
  s.pendingTab = index;
}

// 取出并复位待处理页签，返回 -1 表示没有跳转请求
export function takePendingTab(): number {
  const s = AppStorageV2.connect(NavSignal, () => new NavSignal())!;
  const v = s.pendingTab;
  s.pendingTab = -1;
  return v;
}

// 写入待处理的 AI 提问上下文。必须先写它、再切页签
export function signalPendingAsk(ctx: AIAskContext): void {
  const s = AppStorageV2.connect(NavSignal, () => new NavSignal())!;
  s.pendingAsk = ctx;
}

// 取出并复位提问上下文，返回 null 表示没有待处理的知识点
export function takePendingAsk(): AIAskContext | null {
  const s = AppStorageV2.connect(NavSignal, () => new NavSignal())!;
  const v: AIAskContext | null = s.pendingAsk;
  s.pendingAsk = null;
  return v;
}
