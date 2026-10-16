// =============================================================================
// 分块 UTF-8 解码器
//
// 为什么不用 util.TextDecoder：**预览器里整个 util 模块是 auto-mock**，
// decodeToString() 永远返回空串。DevEco 把 mock 实现编进了 libace_compatible，
// 调用一次就刷一条 "The decodeToString interface in the previewer is a mocked
// implementation"。流式响应是靠 dataReceive 一块块送过来的，解码这一步一废，
// 整轮就一个事件都收不到，最后只报一句"AI 没有返回任何内容"。
//
// 而 requestInStream / dataReceive 本身在预览器里是**真实现**——预览器日志里
// 能看到那些 mock 警告按时间戳陆续刷出（21:59:15.937 → 16.811），说明块确实是
// 分批到的。所以只要把"字节变文本"这一步换成纯 ArkTS，逐字上屏在预览器上就能跑，
// 真机上更没问题。纯计算，不依赖任何平台 API。
//
// 为什么要"分块"解：TCP 分块和 chunked 编码都不照顾字符边界，一个 chunk 很可能
// 正好切在汉字的三个字节中间。剩下半个序列必须留到下一块补上——既不能丢（丢了
// 这个字就没了），也不能当场解成一个乱码字符（那会多出一个不该有的字）。
// =============================================================================

// 遇到非法字节时吐出的替换字符：Unicode U+FFFD（文件里的字节是 EF BF BD）。
// 别改成直接敲那个符号，它是不可见度很高的一个字符，容易在换编码时自己先烂掉
const REPLACEMENT: string = '�';

// 一个请求配一个实例：carry 是"跨块状态"，两个流共用会把彼此的半截字符搅在一起
export class Utf8ChunkDecoder {
  // 上一块末尾没凑齐的那个字符的字节，正常 0~3 个
  private carry: number[] = [];

  // 解一块字节。返回值可能比实际收到的少最后半个字符——那是被切开的，
  // 已经存进 carry 等下一块了
  decode(chunk: Uint8Array): string {
    // 把上一块的零头接在前面，跨块的序列在这里自然就拼上了
    const bytes: number[] = this.carry;
    this.carry = [];
    for (let i = 0; i < chunk.length; i++) {
      bytes.push(chunk[i]);
    }

    let out: string = '';
    let i: number = 0;
    while (i < bytes.length) {
      const b0: number = bytes[i];

      // ASCII：一个字节一个字，绝大多数内容走这条
      if (b0 < 0x80) {
        out += String.fromCharCode(b0);
        i++;
        continue;
      }

      // 按首字节的高位定这个字符一共几个字节，顺便把已到手的低位装进 cp
      let len: number = 0;
      let cp: number = 0;
      if ((b0 & 0xE0) === 0xC0) {
        len = 2;
        cp = b0 & 0x1F;
      } else if ((b0 & 0xF0) === 0xE0) {
        len = 3;
        cp = b0 & 0x0F;
      } else if ((b0 & 0xF8) === 0xF0) {
        len = 4;
        cp = b0 & 0x07;
      } else {
        // 不是合法首字节（含 0x80~0xBF 那种游离的续字节）：吐替换符，前进一格重新同步
        out += REPLACEMENT;
        i++;
        continue;
      }

      // ★ 块尾被切开：整段留下来等下一块，这是"分块"二字的全部含意
      if (i + len > bytes.length) {
        this.carry = bytes.slice(i);
        return out;
      }

      let valid: boolean = true;
      for (let k = 1; k < len; k++) {
        const bk: number = bytes[i + k];
        if ((bk & 0xC0) !== 0x80) {
          valid = false;
          break;
        }
        cp = (cp << 6) | (bk & 0x3F);
      }
      if (!valid) {
        // 续字节不合法：这个字符整体作废，只前进一格，让后面还有机会重新对齐
        out += REPLACEMENT;
        i++;
        continue;
      }

      out += Utf8ChunkDecoder.toText(cp);
      i += len;
    }
    return out;
  }

  // 码点转字符串。超过 0xFFFF 的要拆成代理对。
  // 不用 String.fromCodePoint 是为了不依赖具体运行时有没有实现它
  private static toText(cp: number): string {
    // 代理区码点和超出 Unicode 上界的都是非法编码，直接替换掉，
    // 否则会拼出一个孤立的代理字符，后面 JSON.parse 会炸
    if (cp >= 0xD800 && cp <= 0xDFFF) {
      return REPLACEMENT;
    }
    if (cp > 0x10FFFF) {
      return REPLACEMENT;
    }
    if (cp < 0x10000) {
      return String.fromCharCode(cp);
    }
    const v: number = cp - 0x10000;
    return String.fromCharCode(0xD800 + (v >> 10), 0xDC00 + (v & 0x3FF));
  }
}
