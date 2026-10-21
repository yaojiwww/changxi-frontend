import { Utf8ChunkDecoder } from './Utf8ChunkDecoder';

// =============================================================================
// 从登录令牌里读账号标识
//
// 后端签的是标准 HS256 JWT，payload 里 sub 就是用户 id（见 changxi-backend/src/jwt.cj）。
// 前端只需要「按账号区分本地缓存」这一个用途，不验签、不看有效期——令牌是后端刚发的，
// 验签是后端每次请求都要做的事，客户端再做一遍没有意义。
//
// 为什么不用 util.Base64Helper：预览器里整个 util 模块是 auto-mock（同 Utf8ChunkDecoder
// 顶部注释），decodeToString 永远返回空串。所以这里自己解 base64url，纯 ArkTS 计算。
// =============================================================================

// JWT 的 payload 只用得到 sub；其余字段（iss/aud/ver/iat/exp）后端校验，前端不碰
interface TokenPayload {
  sub?: string;
}

const BASE64URL_CHARS: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

// base64url → 字节。遇到非法字符返回 null，不做"尽力猜"。
// 每 6 bit 进一次缓冲，凑满 8 bit 就吐一个字节，末尾不够 8 bit 的零头直接丢掉。
function base64UrlToBytes(text: string): Uint8Array | null {
  const out: number[] = [];
  let buffer: number = 0;
  let bits: number = 0;
  for (let i = 0; i < text.length; i++) {
    const ch: string = text.charAt(i);
    if (ch === '=') {
      continue;   // 允许带 padding，也允许不带
    }
    const value: number = BASE64URL_CHARS.indexOf(ch);
    if (value < 0) {
      return null;
    }
    buffer = (buffer << 6) | value;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      out.push((buffer >> bits) & 0xFF);
      buffer &= (1 << bits) - 1;   // 丢掉已消费的高位，缓冲只留零头
    }
  }
  const bytes: Uint8Array = new Uint8Array(out.length);
  for (let i = 0; i < out.length; i++) {
    bytes[i] = out[i];
  }
  return bytes;
}

export class TokenIdentity {
  // 取用户 id（JWT 的 sub）。解析失败返回空串，调用方自行兜底
  static userId(token: string): string {
    const parts: string[] = token.split('.');
    if (parts.length !== 3) {
      return '';
    }
    const bytes: Uint8Array | null = base64UrlToBytes(parts[1]);
    if (bytes === null) {
      return '';
    }
    try {
      const payload: TokenPayload = JSON.parse(new Utf8ChunkDecoder().decode(bytes)) as TokenPayload;
      const sub: string | undefined = payload.sub;
      return sub === undefined ? '' : sub;
    } catch (err) {
      return '';
    }
  }

  // 本地缓存的账号键：优先稳定 userId，令牌解不出来时退回手机号。
  // 前缀用下划线而不是冒号：这个字符串会拼进 preferences 的 key，字符集越保守越安全
  static accountKey(token: string, phone: string): string {
    const id: string = TokenIdentity.userId(token);
    return id === '' ? `phone_${phone}` : `id_${id}`;
  }
}
