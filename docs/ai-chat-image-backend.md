# AI 聊天图片发送 —— 后端改造说明

> 前端已按本文契约实现（`api/AIChatApi.ets`、`viewmodel/AIChatViewModel.ets`、`pages/AIChatPage.ets`）。
> 后端按下面的接口补齐后，前端无需再改即可跑通「文字 + 图片」提问。

## 一、前端调用链

```
选择图片（系统相册）
  → POST /api/v1/ai/upload        multipart/form-data，字段名 file
  ← { code: 0, message: "ok", data: { url: "https://.../chat.jpg" } }
  → POST /api/v1/ai/chat          JSON，带上 imageUrl
  ← 原有 SSE 流式事件（message / agent_message / message_end / error）
```

只发图片、不写文字时，前端会补默认 query：`请识别并解答图片中的题目`。

## 二、后端需要新增/修改的内容

### 1. 新增图片上传接口

- **路径**：`POST /api/v1/ai/upload`
- **鉴权**：`Authorization: Bearer <token>`（与 `/ai/chat` 一致）
- **Content-Type**：`multipart/form-data`
- **表单字段**：`file`（单文件，jpg / png / webp，建议 ≤ 10 MB）
- **成功响应**：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "url": "https://your-domain.com/uploads/ai/2026/10/xxxx.jpg"
  }
}
```

- **失败响应**（沿用统一信封，`data` 为 `null`）：

```json
{
  "code": 1001,
  "message": "图片格式不支持",
  "data": null
}
```

要求：

1. 校验登录态；未登录返回 `2001`。
2. 校验 MIME / 扩展名 / 文件大小，拒绝非图片。
3. 文件落对象存储或静态目录，返回**公网可访问**的 URL（Dify 需要能下载）。
4. 建议生成随机文件名，不要用用户原始文件名。
5. 可选：上传后做一次图片压缩/转码，降低 Dify 侧下载体积。

### 2. 修改聊天接口 `POST /api/v1/ai/chat`

请求体新增一个字段：

```json
{
  "query": "这道题怎么做",
  "conversationId": "上一轮返回的会话 ID，首轮空串",
  "mode": "solve",
  "imageUrl": "https://your-domain.com/uploads/ai/2026/10/xxxx.jpg"
}
```

- `imageUrl` 无图时为空串 `""`，后端需兼容该字段缺失或为空。
- 有 `imageUrl` 时，后端负责把图片转成 Dify 的文件参数，**不要**把 URL 拼进 `query`。

### 3. Dify 侧对接（关键）

Dify 的 `/chat-messages` 不支持直接传远程 URL，需要两步：

1. 调用 Dify 文件上传接口 `POST /files/upload`（`multipart/form-data`，字段 `file`，`user` 用当前用户 ID），拿到 `upload_file_id`。
2. 调用 `/chat-messages` 时传：

```json
{
  "inputs": { "mode": "solve" },
  "query": "这道题怎么做",
  "conversation_id": "xxx",
  "user": "user-id",
  "response_mode": "streaming",
  "files": [
    {
      "type": "image",
      "transfer_method": "local_file",
      "upload_file_id": "dify-file-id"
    }
  ]
}
```

注意：

- 同一个 `imageUrl` 建议做短时缓存（URL → Dify `upload_file_id`），避免多轮对话重复上传。
- 如果 Dify 应用未开启「视觉」能力，图片不会生效，需要在 Dify 控制台确认模型支持图片输入。
- 流式响应格式保持不变，前端仍按原有事件解析。

### 4. 错误与边界

| 场景 | 建议行为 |
|---|---|
| 未登录 / token 过期 | `code: 2001`，前端会清 token 并跳登录 |
| 文件为空、非图片、超限 | `code: 1001`，`message` 给出可直接展示的中文原因 |
| 存储失败 | `code: 5000`（或现有内部错误码），`message: "图片上传失败"` |
| Dify 上传失败 | 聊天接口在建立 SSE 之前返回统一错误信封，前端会 toast |
| 只传图不传字 | 后端照常处理，`query` 已由前端补默认文案 |

### 5. 安全建议

- 上传接口必须鉴权，禁止匿名上传。
- 限制单文件大小、像素尺寸与 MIME；服务端重新校验，不信任客户端 `Content-Type`。
- 文件名随机化，存储目录不可执行。
- 返回 URL 建议带域名白名单或 CDN，避免 SSRF。
- 定期清理未被聊天引用的孤儿图片。

## 三、给后端 AI 的提示词（可直接复制）

```text
你是一名熟悉 Spring Boot / Node.js（按项目现有技术栈选择）的后端工程师。
现在需要为「AI 伴学」聊天增加图片提问能力，前端契约已经固定，请不要改动字段名。

【现有接口】
POST /api/v1/ai/chat
请求体：{ "query": string, "conversationId": string, "mode": "solve" | "plan" }
响应：SSE 流式事件，事件字段保持 Dify 原样：
  message / agent_message -> answer 为增量文本
  message_end -> 本轮结束
  error -> message 为错误原因
每个事件都带 conversationId。
鉴权：Authorization: Bearer <token>。
统一响应信封：{ "code": number, "message": string, "data": any }，code=0 成功。

【需要新增】
1. POST /api/v1/ai/upload
   - multipart/form-data，单文件字段名必须是 file
   - 需要登录鉴权
   - 仅允许 jpg/jpeg/png/webp，建议最大 10MB
   - 保存到对象存储或静态目录，返回公网可访问 URL
   - 成功：{ "code": 0, "message": "ok", "data": { "url": "https://..." } }
   - 失败：{ "code": 1001, "message": "可直接展示给用户的中文原因", "data": null }

2. 修改 POST /api/v1/ai/chat
   - 请求体新增 imageUrl: string，无图时为空串
   - 有 imageUrl 时：
     a. 先调用 Dify 的 POST /files/upload 上传该图片，拿到 upload_file_id；
     b. 再调用 Dify /chat-messages，在 files 中传
        [{ "type": "image", "transfer_method": "local_file", "upload_file_id": "..." }]
   - 不要把图片 URL 拼进 query
   - 保持现有 SSE 输出格式和 conversationId 透传不变
   - 对同一个 imageUrl 做短时缓存，避免重复上传到 Dify

【要求】
- 复用项目现有的鉴权、统一响应、异常处理与日志组件，不要另起一套。
- 上传接口必须做服务端文件类型/大小校验，文件名随机化。
- 未登录返回业务码 2001；参数错误返回 1001。
- Dify 上传失败时，在建立 SSE 之前返回统一错误信封。
- 补充接口文档与至少一个上传成功、一个格式错误的测试用例。
- 给出完整改动文件清单和关键代码。
```
