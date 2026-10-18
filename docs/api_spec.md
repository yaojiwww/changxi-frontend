# 畅溪鸿蒙APP 接口文档

> 建议按域组织：认证域、各业务域，每个接口包含路径、方法、请求体、响应示例、错误码。

<!-- 接口文档内容从这里开始 -->

## 业务码表

响应体里的 `code` 是**业务码**，全后端共用一套编号，与请求的 URL 无关。
APP 端只需看 `code` 即可判断错误类型（例如收到 `2001` 就清本地 token 并跳登录页）。

| code | 含义 | 备注 |
|---|---|---|
| 0    | 成功 | `message` 固定为 `ok` |
| 1001 | 参数为空或格式错误 | 所有接口共用 |
| 1002 | 手机号未注册 | |
| 1003 | 密码错误 | |
| 1004 | 短信验证码错误 | |
| 1005 | 短信验证码已过期 | |
| 1006 | 验证码请求过于频繁 | |
| 2001 | token 无效或已过期 | 任何需登录的接口都可能返回 |

> ⚠️ 注意区分两个 `code`：**请求体**里的 `code` 是短信验证码（字符串），
> **响应体**里的 `code` 是上表的业务码（数字），同名不同义。
>
> 约定：失败时 HTTP 状态码仍为 4xx，同时 `data` 固定为 `null`。

---

1. 注册接口 POST /api/v1/auth/register
* 手机号验证请求体
```
{
  "number": "string",
  "code": "string",
  "password": "string"
}
```
* 响应体
```
{
  "code":number,
  "message":string,
  "data":string // 成功返回 token，失败统一返回 null
}
```
2. 获取验证码接口 POST /api/v1/auth/send-code
* 请求体
```
{
  "number": "string",
  "purpose": "string" // "register" 注册 / "reset_password" 找回密码
}
```
   * 响应体

   {
  "code":number,
  "message":string,
  "data":null // 验证码不通过接口返回，仅通过短信发送
}
   * 错误码
     - 1001 手机号或 purpose 为空
     - 1002 手机号未注册（purpose 为 reset_password 时）

3. 登录接口 POST /api/v1/auth/login
   * 请求体

   {
   "number":string,
   "password":string
}
   * 响应体

   {
  "code":number,
  "message":string,
  "data":string // 成功返回token，失败统一返回 null
}
   * 错误码
     - 1001 手机号或密码为空
     - 1002 手机号未注册
     - 1003 密码错误

4. 登出接口 POST /api/v1/auth/logout
   * 请求体

   {
  "number":string
}
   * 响应体

   {
  "code":number,
  "message":string,
  "data":string // 失败统一返回 null
}
5. 聊天接口 POST /api/v1/chat
   * 请求体

   // Authorization: Bearer <登录拿到的 token>
{
  "message":string,
  "conversationId": string, // 首轮传 ""，续聊传上一轮返回的 conversationId
  "stream":boolean, // 流式输出
  "mode":string // agent工作流模式选择
}
   * 响应体

   {
  "type":string,
  "conversationId":string,
  "content":string
}

/*
举例
data: {"type": "message", "content": "急救"} // message 正在推送中间内容
data: {"type": "message", "content": "的第一步是"}
data: {"type": "end", "conversationId":"11111", "content": ""} // end 推送结束
data: {"type": "error", "content": "出错了"} // error 中途出错了
*/
6. 大模型接口 POST /v1/chat-messages
   * 请求体

   Authorization: Bearer <你的Dify API Key>
{
  "inputs": {},
  "query": "用户发的消息内容",
  "response_mode": "streaming",
  "conversation_id": "",
  "user": "user123"
}
   * 响应体

原始 dify 输出格式转成聊天接口的响应体即可输出
7. 考试时间接口 GET /api/v1/user/exam-date
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 响应体

   {
  "code":number,
  "message":string,
  "data":string // 考试日期字符串，如 "2026-05-16"；未设置返回 null
}
8. 版本更新接口 GET /api/v1/app/version
   * 请求头（可选）

   Authorization: Bearer <登录拿到的 token>
   * 响应体

   {
  "code":number,
  "message":string,
  "data":{
    "version":string, // 最新版本号
    "force":boolean,  // 是否强制更新
    "note":string     // 更新说明
  } // 失败统一返回 null
}
9. 注销账号接口 POST /api/v1/account/delete
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 请求体

   {}
   * 响应体

   {
  "code":number,
  "message":string,
  "data":string // 失败统一返回 null
}
10. 获取个人信息接口 GET /api/v1/user/profile
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 响应体

   {
  "code":number,
  "message":string,
  "data":{
    "avatarUrl":string,
    "nickname":string,
    "phone":string,
    "userId":string,
    "wechatBound":boolean
  } // 失败统一返回 null
}
11. 更新头像接口 POST /api/v1/user/update/avatar
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 请求体

   {
  "avatarUri":string // 本地图片 uri
}
   * 响应体

   {
  "code":number,
  "message":string,
  "data":string // 失败统一返回 null
}
12. 更新昵称接口 POST /api/v1/user/update/nickname
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 请求体

   {
  "nickname":string
}
   * 响应体

   {
  "code":number,
  "message":string,
  "data":string // 失败统一返回 null
}
13. 发送手机号验证码接口 GET /api/v1/user/send-sms-code?phone=手机号
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 响应体

   {
  "code":number,
  "message":string,
  "data":string // 失败统一返回 null
}
14. 更换绑定手机号接口 POST /api/v1/user/update/phone
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 请求体

   {
  "phone":string,
  "code":string // 短信验证码
}
   * 响应体

   {
  "code":number,
  "message":string,
  "data":string // 失败统一返回 null
}
15. 绑定微信接口 POST /api/v1/user/bind/wechat
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 请求体

   {}
   * 响应体

   {
  "code":number,
  "message":string,
  "data":string // 失败统一返回 null
}
16. 学习数据统计接口 GET /api/v1/user/learning-stats
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 响应体

   {
  "code":number,
  "message":string,
  "data":{
    "studyDays":number,     // 连续学习天数；字段可为 null
    "totalAnswers":number,  // 累计答题数；字段可为 null
    "accuracy":number,      // 平均正确率百分比数值，如 76；字段可为 null
    "studyHours":number     // 学习时长小时数，如 26；字段可为 null
  } // 失败统一返回 null
}


17. 练习批量提交接口 POST /api/v1/practice/batch-submit
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 查询参数

   itemId=string // 知识条目 ID，如 basic-001
   * 请求体（作答数组）

   [
  {"questionId":string,"userAnswer":string},  // userAnswer 为选项字母 A/B/C/D
  {"questionId":string,"userAnswer":string}
]
   * 响应体（一次性返回完整练习报告）

   {
  "code":number,
  "message":string,
  "data":{
    "itemId":string,          // 知识条目 ID
    "itemName":string,        // 知识条目名
    "practiceType":string,    // 练习类型，如 基础知识·单选练习
    "submitTime":string,      // 交卷时间 YYYY-MM-DD HH:mm:ss
    "correctCount":number,    // 答对题数
    "total":number,           // 总题数
    "accuracy":number,        // 正确率百分比数值；未计算时为 null
    "duration":number,        // 练习时长秒数
    "compare":{
      "lastAccuracy":number,        // 上次正确率；可为 null
      "deltaVsLast":number,         // 较上次变化百分点，可为负；可为 null
      "deltaVsPassLine":number      // 较合格线(60)变化百分点，可为负；可为 null
    },
    "answerCard":[{"questionId":string,"correct":boolean,"userAnswer":string,"correctOption":string}],  // 每题对错状态
    "mastery":[{"knowledgePoint":string,"correct":number,"total":number,"accuracy":number}]  // 知识点掌握
  } // 失败统一返回 null
}

18. 每日一练题目接口 GET /api/v1/practice/daily
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 响应体

   {
  "code":number,
  "message":string,
  "data":{
    "date":string,       // 今日日期 YYYY-MM-DD
    "practiceId":string, // 本次练习 ID，提交时回传
    "questions":[{"questionId":string,"stem":string,"options":[string],"knowledgePoint":string}]
  } // 失败统一返回 null
}
19. 每日一练批量提交接口 POST /api/v1/practice/daily/submit
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 查询参数

   practiceId=string
   * 请求体（作答数组）

   [
  {"questionId":string,"userAnswer":string}  // userAnswer 为选项字母 A/B/C/D
]
   * 响应体

   与 #17 练习批量提交接口的 data 结构一致（完整练习报告），仅 practiceType 为每日一练
20. 收藏列表接口 GET /api/v1/favorites/list
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 查询参数

   category=string   // 知识点分类，空串=全部
   timeRange=string  // all / today / week
   * 响应体

   {
  "code":number,
  "message":string,
  "data":{
    "total":number,   // 收藏总题数
    "categories":[{"category":string,"count":number,"items":[{"questionId":string,"stem":string,"options":[string],"answer":number,"knowledgePoint":string,"source":string,"favoritedAt":number}]}]
  } // 失败统一返回 null
}
21. 取消收藏接口 POST /api/v1/favorites/cancel
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 请求体

   {"questionId":string}
   * 响应体

   {"code":number,"message":string,"data":{}} // 失败统一返回 null
22. 错题本列表接口 GET /api/v1/wrong/list
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 查询参数

   category=string   // 知识点分类，空串=全部
   timeRange=string  // all / today / week / stubborn（顽固错题）
   * 响应体

   {
  "code":number,
  "message":string,
  "data":{
    "total":number,   // 错题总题数
    "categories":[{"category":string,"count":number,"items":[{"questionId":string,"stem":string,"options":[string],"answer":number,"knowledgePoint":string,"source":string,"lastWrongAt":number,"wrongCount":number,"correctCount":number}]}]  // correctCount 为重练答对进度 0-3
  } // 失败统一返回 null
}
23. 错题重练批量提交接口 POST /api/v1/wrong/repractice
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 请求体（作答数组）

   [
  {"questionId":string,"userAnswer":string}
]
   * 响应体（三次答对消除逻辑由后端判定，前端仅展示进度）

   {
  "code":number,
  "message":string,
  "data":[{"questionId":string,"correctCount":number,"eliminated":boolean}] // correctCount: 当前答对次数 0-3；eliminated: 是否已消除
} // 失败统一返回 null

24. AI 实操分析接口 POST /api/v1/ai-practice/analyze
   * 请求头

   Authorization: Bearer <登录拿到的 token>
   * 请求体

   {
  "sceneId":string,   // 场景 ID：meal 进餐环节 / nap 午睡环境 / toy 玩具消毒 / temp 恒温检测
  "imageUri":string   // 上传图片的本地 URI
}
   * 响应体

   {
  "code":number,
  "message":string,
  "data":{
    "sceneId":string,
    "sceneTitle":string,   // 场景标题，如 幼儿进餐环节
    "score":number,        // 总分
    "comment":string,      // 综合评价
    "suggests":[{"title":string,"detail":string}],  // 改进建议列表
    "bases":[string]       // 判断依据：规范名称列表
  } // 失败统一返回 null
}
