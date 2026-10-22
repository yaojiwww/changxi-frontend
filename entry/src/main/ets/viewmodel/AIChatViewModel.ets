// AI 伴学页的 ViewModel：持有聊天记录与提问编排，不碰 UI。
// 页面只做渲染；选图、提问、流式收字、多轮会话 ID 都在这里。
// 失败一律 throw Error，由页面 catch 后 toast。
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AppConfig } from '../common/AppConfig';
import { TokenStore } from '../common/TokenStore';
import {
  ChatMessage,
  PendingImage,
  MAX_CHAT_IMAGES,
  AI_MODE_SOLVE,
  AI_MODE_PLAN,
  AIAskContext,
  DEFAULT_KNOWLEDGE_QUESTION,
  askContextTitle,
  buildKnowledgePrompt
} from '../model/ChatModels';
import { AIChatApi, AIChatRequest, AIChatHandlers } from '../api/AIChatApi';

// 消息发送方，与页面渲染时的判断值一致
const FROM_USER: string = 'user';
const FROM_AI: string = 'ai';

// 只发图片、没写文字时补一句默认提问，保证后端/Dify 的 query 非空
const IMAGE_ONLY_QUERY: string = '请识别并解答图片中的题目';

@ObservedV2
export class AIChatViewModel {
  @Trace chatList: ChatMessage[] = [];
  @Trace inputText: string = '';
  // 已选、待发送的图片。选完立刻上传，上传完成前不允许发送
  @Trace pendingImages: PendingImage[] = [];
  @Trace selectedMode: number = 0;    // 0 = 题目解答，1 = 专属规划
  @Trace sending: boolean = false;    // 正在收回复，期间忽略重复发送
  // 从 AI 知识库带过来的知识点。为空表示普通提问；非空时每轮都带上这段背景
  @Trace askContext: AIAskContext | null = null;

  private token: string = '';
  private conversationId: string = '';   // 后端下发的会话 ID，下一轮带上即多轮记忆
  private imageSeq: number = 0;          // 给待发图片发号，删除/回填时按 id 定位
  // 留着 context 是为了发问前能再确认一次配置已加载：aboutToAppear 是异步的，
  // 用户手快（或者 init 曾经失败过）时，直接发问会撞上「AppConfig 未加载」。
  private context: common.Context | undefined = undefined;

  // 聊天记录非空时隐藏上部引导区，让位给聊天流
  get hasChat(): boolean {
    return this.chatList.length > 0;
  }

  // 是否有图片还在上传：上传没完成不能发消息
  get uploading(): boolean {
    for (let i = 0; i < this.pendingImages.length; i++) {
      if (this.pendingImages[i].uploading) {
        return true;
      }
    }
    return false;
  }

  // 发送按钮的可用态：有文字或有图、图片都传完了，且当前没有正在收的回复
  get canSend(): boolean {
    return !this.sending && !this.uploading &&
      (this.inputText.trim() !== '' || this.pendingImages.length > 0);
  }

  // 是否带着知识点提问：页面据此显示上下文胶囊
  get hasAskContext(): boolean {
    return this.askContext !== null;
  }

  // 上下文胶囊文案：中级 · 婴幼儿饮食照料 · 2.1 饮食照料
  askContextLabel(): string {
    return this.askContext !== null ? askContextTitle(this.askContext) : '';
  }

  // 从知识库进入时调用：记下知识点；输入框为空则预填默认问题，不自动发送
  applyAskContext(ctx: AIAskContext): void {
    this.askContext = ctx;
    if (this.inputText.trim() === '') {
      this.inputText = DEFAULT_KNOWLEDGE_QUESTION;
    }
  }

  // 用户关掉上下文胶囊：回到普通提问；只清理未被改过的默认问题
  clearAskContext(): void {
    if (this.inputText === DEFAULT_KNOWLEDGE_QUESTION) {
      this.inputText = '';
    }
    this.askContext = null;
  }

  // 页面 aboutToAppear 调一次：准备配置与令牌（两步都幂等，可以多页重复调用）
  async init(context: common.Context): Promise<void> {
    this.context = context;
    await AppConfig.load(context);
    await TokenStore.init(context);
    this.token = await TokenStore.read();
  }

  // 加号：调起系统相册选图（最多补到 4 张），选完立刻上传换取 fileId。
  // 上传失败的单张会被移除，原因汇总成一句 throw 给页面 toast。
  async pickImage(): Promise<void> {
    const remaining: number = MAX_CHAT_IMAGES - this.pendingImages.length;
    if (remaining <= 0) {
      throw new Error(`一条消息最多发送 ${MAX_CHAT_IMAGES} 张图片`);
    }
    // 上传要用令牌和 baseUrl，先确保都就绪，别让用户选完图才失败
    await this.ensureReady();

    let uris: string[] = [];
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: remaining,
        isPhotoTakingSupported: true
      };
      const result = await picker.select(options);
      const picked: string[] | undefined = result.photoUris;
      if (picked !== undefined) {
        uris = picked;
      }
    } catch (e) {
      const err = e as BusinessError;
      const code: number = err.code !== undefined ? err.code : 0;
      // 13900006 = 用户主动取消，保持原状态，不打扰
      if (code === 13900006) {
        return;
      }
      throw new Error(code !== 0 ? `打开相册失败（错误码 ${code}）` : '打开相册失败');
    }
    if (uris.length === 0) {
      return;
    }

    // 先全部挂上缩略图并标记上传中，用户能马上看到选了什么
    const added: PendingImage[] = [];
    for (let i = 0; i < uris.length && i < remaining; i++) {
      this.imageSeq++;
      added.push({
        id: `img_${this.imageSeq}`,
        uri: uris[i],
        fileId: '',
        uploading: true
      });
    }
    this.pendingImages = this.pendingImages.concat(added);

    // 逐张上传：并发会把 4 张 8MB 同时压上去，收益不大还容易撞超时
    const failures: string[] = [];
    for (let i = 0; i < added.length; i++) {
      const item: PendingImage = added[i];
      try {
        const fileId: string = await AIChatApi.uploadImage(item.uri, this.token);
        this.patchPendingImage(item.id, fileId);
      } catch (err) {
        this.removePendingImage(item.id);
        failures.push((err as Error).message);
      }
    }
    if (failures.length > 0) {
      throw new Error(failures.join('；'));
    }
  }

  // 移除单张待发图片（按 id，避免删错）
  removePendingImage(id: string): void {
    const next: PendingImage[] = [];
    for (let i = 0; i < this.pendingImages.length; i++) {
      if (this.pendingImages[i].id !== id) {
        next.push(this.pendingImages[i]);
      }
    }
    this.pendingImages = next;
  }

  // 上传成功：回填 fileId 并灭掉上传中标记。
  // 上传期间用户可能已经把这张删了，这里找不到就当无事发生。
  private patchPendingImage(id: string, fileId: string): void {
    const next: PendingImage[] = [];
    for (let i = 0; i < this.pendingImages.length; i++) {
      const item: PendingImage = this.pendingImages[i];
      if (item.id === id) {
        next.push({ id: item.id, uri: item.uri, fileId: fileId, uploading: false });
      } else {
        next.push(item);
      }
    }
    this.pendingImages = next;
  }

  // 配置与令牌准备（两步都幂等）。页面刚起来就操作时 init() 可能还没跑完，
  // 这里补一次：配置没加载 → 取 baseUrl 直接抛；令牌没读到 → 白白吃 401。
  private async ensureReady(): Promise<void> {
    if (this.context === undefined) {
      throw new Error('页面还没准备好（拿不到应用上下文），请重新进入本页');
    }
    await AppConfig.load(this.context);
    if (this.token === '') {
      await TokenStore.init(this.context);
      this.token = await TokenStore.read();
    }
  }

  // 提问：先把用户消息压进列表，再发起流式请求，边收边把增量写进 AI 气泡。
  // 失败 throw，页面 toast；失败原因同时会落进气泡，方便回看。
  async send(): Promise<void> {
    if (this.sending) {
      return;   // 上一轮还在收，忽略重复点按
    }
    if (this.uploading) {
      throw new Error('图片还在上传，请稍候再发送');
    }
    const text: string = this.inputText.trim();
    if (text === '' && this.pendingImages.length === 0) {
      return;   // 没内容，等同没点
    }

    const imageUris: string[] = [];
    const fileIds: string[] = [];
    for (let i = 0; i < this.pendingImages.length; i++) {
      const item: PendingImage = this.pendingImages[i];
      imageUris.push(item.uri);
      if (item.fileId !== '') {
        fileIds.push(item.fileId);
      }
    }
    if (fileIds.length !== imageUris.length) {
      // 正常走不到：上传中已在上面拦掉了。留作兜底，别把没换到 ID 的图悄悄发出去
      throw new Error('有图片还没上传完成，请稍候再发送');
    }

    const ask: AIAskContext | null = this.askContext;
    const userMsg: ChatMessage = {
      from: FROM_USER,
      type: imageUris.length > 0 ? 'image' : 'text',
      content: text,
      imageUris: imageUris
    };
    this.chatList.push(userMsg);
    this.inputText = '';
    this.pendingImages = [];
    this.sending = true;

    // AI 气泡延迟到第一个字到达时才建：Dify 的智能体首字要等好几秒，
    // 但先塞一个空气泡会凭空多出一个空白框。用户消息已经上屏，不算没反馈。
    let replyIndex: number = -1;
    let failReason: string = '';

    // 增量写回。这里必须整条替换（splice）而不是改 content 字段：
    // @Trace 只观察到数组这一层，改元素内部的字段不会触发刷新。
    // 每次只重建正在流的那一条，其余消息的 key 没变，不会跟着重绘。
    const flush = (delta: string): void => {
      if (replyIndex < 0) {
        const blank: ChatMessage = { from: FROM_AI, type: 'text', content: '', imageUris: [] };
        this.chatList.push(blank);
        replyIndex = this.chatList.length - 1;
      }
      const prev: ChatMessage = this.chatList[replyIndex];
      const merged: ChatMessage = {
        from: FROM_AI,
        type: 'text',
        content: prev.content + delta,
        imageUris: []
      };
      this.chatList.splice(replyIndex, 1, merged);
    };

    const handlers: AIChatHandlers = {
      onDelta: (delta: string): void => {
        flush(delta);
      },
      onConversationId: (id: string): void => {
        this.conversationId = id;   // 存下来，下一轮带上就是多轮记忆
      },
      onFail: (message: string): void => {
        failReason = message;
      }
    };

    try {
      // 页面刚起来就发问的话，init() 可能还没跑完，这里补一次
      await this.ensureReady();
      const baseQuery: string = text !== ''
        ? text
        : (imageUris.length > 0 ? IMAGE_ONLY_QUERY : DEFAULT_KNOWLEDGE_QUESTION);
      const body: AIChatRequest = {
        query: ask !== null ? buildKnowledgePrompt(ask, baseQuery) : baseQuery,
        conversationId: this.conversationId,
        mode: this.selectedMode === 1 ? AI_MODE_PLAN : AI_MODE_SOLVE,
        fileIds: fileIds
      };
      await AIChatApi.stream(body, this.token, handlers);

      if (failReason !== '') {
        // 流里的错误：当成 AI 的回答写进气泡，比 toast 一闪而过更容易回看
        throw new Error(failReason);
      }
      if (replyIndex < 0) {
        throw new Error('AI 没有返回内容，请稍后再试');
      }
    } catch (err) {
      const msg: string = (err as Error).message;
      if (replyIndex < 0) {
        // 一个字都没收到：把原因也写进气泡
        const failure: ChatMessage = { from: FROM_AI, type: 'text', content: msg, imageUris: [] };
        this.chatList.push(failure);
      }
      // ArkTS 不允许 throw 任意类型，catch 变量必须显式当成 Error 再抛
      throw err as Error;
    } finally {
      this.sending = false;
    }
  }
}
