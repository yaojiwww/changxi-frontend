import util from '@ohos.util';

/**
 * UTF-8 流式解码器。
 *
 * 为什么需要它：原来 SSE 用 String.fromCharCode 逐字节转换，
 * 而一个汉字在 UTF-8 里占 3 个字节，逐字节转出来必然是乱码。
 *
 * 为什么必须"流式"：网络分包不会对齐字符边界，一个汉字的 3 个字节
 * 完全可能被切在两个 ArrayBuffer 里。stream: true 会把结尾不完整的
 * 字节留在解码器内部，等下一包拼上再吐出来。
 */
export class Utf8Decoder {
  private decoder: util.TextDecoder;

  constructor() {
    this.decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
  }

  /** 解码一个数据块，尾部不完整的字节会被内部保留 */
  decode(buffer: ArrayBuffer): string {
    return this.decoder.decodeToString(new Uint8Array(buffer), { stream: true });
  }

  /** 流结束时调用，吐出内部残留的最后一点内容 */
  flush(): string {
    return this.decoder.decodeToString(new Uint8Array(0), { stream: false });
  }
}
