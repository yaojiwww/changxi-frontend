# ArkTS / HarmonyOS 开发约束

> 用途：下次让 AI 写这个项目的代码时，把本文件内容贴进 prompt。
> 每一条都来自本项目真实踩过的坑，不是通用建议。

## 一、语法与类型

### 1. 禁止导出不存在的类型（barrel 文件必须逐条核对）

写 `export { A, B } from './x'` 这类"统一出口"文件时，每一个名字都必须在 `./x`
里真实存在。ArkTS 不像 JS 那样能靠运行时兜底，导出一个不存在的名字会直接编译失败，
而且报错信息指向出口文件，不指向真正缺失的地方，很难排查。

**给 AI 的指令**：
> 生成或修改 barrel / index 导出文件时，先列出源文件里实际 export 的所有名字，
> 再逐一核对导出清单，不要凭记忆或凭命名推测写导出名。
> 如果某个类型还没定义，不要先写导出，而要先把类型定义补上。

**本项目案例**：`api/index.ets` 导出了 `ChatResponseData`，但 `apiTypes.ets` 里
从来没有这个类型，旁边还留着一句 AI 写的注释"把这里改为 ChatResponseData"——
这是 AI 在自我修正时改了导出名却没去建对应类型。

### 2. `export type` 只能放"编译后会消失"的东西

`interface` 是纯类型，编译后不存在，可以放进 `export type { }`。
`enum` / `class` / `function` 编译后是真实的运行时对象，必须用普通 `export`。
把 enum 误放进 `export type`，编译不报错，但运行时取值是 `undefined`，极难排查。

**给 AI 的指令**：
> 区分值导出和类型导出：interface 用 `export type { }`；enum、class、function、const
> 用普通 `export { }`。不要因为某个名字"看起来像类型"就放进 export type。

**本项目案例**：`HttpResponseCode` 是 enum，却被放在了 `export type` 清单里。

### 3. 禁止用 `Record<string, T>` / 裸 `string` 兜底已知的 key 集合

key 集合已知且固定时，必须用 enum 作为唯一事实来源。用 `Record<string, T>` 或把
参数类型写成 `string`，等于主动关闭编译期检查，key 拼写不一致的 bug 会沉默地进入运行期。

**给 AI 的指令**：
> 表示"某几个固定取值之一"时一律定义 enum，并让函数参数、数据结构的 key 都用该 enum。
> 禁止用裸 string 传递这类值。项目里已存在的 enum / interface 契约必须被实际使用，
> 不能定义完就晾在一边。

**本项目案例**：`types.ets` 里已经定义了正确的 `ScenarioType` 和 `QuestionBank`，
但题库实际写成了 `Record<string, TestQuestion[]>`，查询函数参数写成 `string`。
结果 `'choking_under_1'` 在题库里根本不存在（只有笼统的 `'choking'`），
选了这个场景一道题都查不到——如果类型写对，编译器当场就会报"缺少属性"。

## 二、编译与工程

### 4. 编译通过 ≠ 代码没问题

ArkTS 只编译从 `main_pages.json` 入口可达的文件。不被任何人 import 的文件
**完全不参与编译**，里面写什么错误都不会报。

**给 AI 的指令**：
> 不要以"build 通过"作为代码正确性的依据。review 时先确认目标文件是否在编译图内
> （从 main_pages.json 的入口沿 import 链能否走到）。
> 新建 page 必须同步登记到 `main_pages.json`；移动或重命名 page 文件/目录时也必须
> 同步更新它——漏改不会有任何编译错误，页面会静默失效。

**本项目案例**：`api/index.ets`、`view/ChatPage.ets`、`api/conversationStore.ets`
长期没有任何人 import，全是编译器看不见的孤儿文件，错误躺了很久没被发现。

### 5. 禁止凭记忆断言平台限制，必须查本地 SDK 或官方文档

AI 容易把 Android / iOS 的平台行为套到 HarmonyOS 上，说得非常确定，
但结论是反的，会让人白做一堆工作。

**给 AI 的指令**：
> 涉及平台限制、配置字段名、默认行为时，不要凭记忆回答。先查证：
> - `module.json5` 字段 → 查 SDK schema
>   `/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/modulecheck/module.json`
> - API 行为和错误码 → 查 DevEco 内置文档
>   `/Applications/DevEco-Studio.app/Contents/plugins/openharmony/ohos-info-center-view/static/hos/`
> 查不到就明说"不确定"，不要给一个听起来很确定的错答案。

**本项目案例**：AI 断言"HarmonyOS 默认拦截明文 HTTP，远程 http:// 地址几乎一定
连不上"，并让用户去 `module.json5` 配 `cleartextTraffic`。实际上：
1. `cleartextTraffic` 只存在于旧 FA 模型的 `config.json`，Stage 模型的
   `module.json5` schema 里根本没这个字段；
2. HarmonyOS **默认允许**明文 HTTP（`isCleartextPermitted` 默认返回 true），
   `network_config.json` 是用来收紧限制的，不是放开用的。
结论完全反了 —— 那是 Android 的行为被套了过来。

### 6. 报告问题必须分级

**给 AI 的指令**：
> 报告代码问题时必须标明是「编译期报错」「运行期出错」还是「仅代码风格」。
> 不要把风格问题说成语法错误——用户会据此决定要不要立刻停下来处理。

### 7. 用工具排查问题前，先做对照测试验证工具本身可信

AI 的运行环境可能有网络白名单、代理、沙箱限制，导致探测结果完全失真。
基于失真数据下结论，会让人去修根本没坏的东西。

**给 AI 的指令**：
> 用 curl / nc 等工具排查外部服务前，必须先跑一个**已知正常的对照组**
> （例如访问一个公认可达的站点，或探测一个确定在运行的服务如 SSH 的 banner）。
> 对照组不通过，就说明工具链不可信，必须明确告诉用户"我无法从这里验证"，
> 而不是把失败归因到用户的服务上。
> 报告探测结论时要说明这是从哪个环境测的、该环境是否可信。

**本项目案例**：AI 连续多轮断言用户的后端"TCP 能连但无 HTTP 响应"，
让用户反复检查监听地址、防火墙、安全组。实际上后端一直是好的 ——
AI 所在环境对外网是白名单制，会伪造 TCP 握手成功但不转发数据。
决定性反证：探测 22 端口拿不到 SSH banner，而用户当时正通过 SSH 连着那台机器。

## 三、MVVM 架构

### 8. 分层职责

```
model/       纯数据结构：interface + enum，不含任何逻辑
repository/  数据来源：网络 / 本地 / 缓存，对上层屏蔽差异
network/     HTTP 客户端、SSE、Token、地址配置
viewmodel/   状态 + 业务逻辑，一个页面一个，@Observed 类
view/        只画 UI，只调 vm 的方法
utils/       无状态工具函数
```

**给 AI 的指令**：
> - View（`struct`）里只允许有 UI 代码和 `vm.xxx()` 调用，不允许写业务 if/switch，
>   不允许直接调用网络接口。
> - ViewModel 里禁止 import 任何 UI 相关的东西（router、promptAction 等）。
>   需要跳转时由 ViewModel 暴露状态，View 去跳。
> - 派生状态（"当前第几题""是不是最后一步"）写成 ViewModel 的 getter，
>   不要让 View 自己算。
> - 网络请求一律经过 repository 层，ViewModel 不直接碰 HttpClient。

### 9. `@Observed` 只观察属性赋值，不观察数组内部变动

`vm.list.push(x)` **不会**触发 UI 刷新，必须 `vm.list = [...vm.list, x]`。
同理修改数组里某个对象的字段也不会刷新，要整体替换该元素再替换数组。

**给 AI 的指令**：
> `@Observed` 类里所有数组/对象的修改都必须走"整体重新赋值"，禁止使用
> push / splice / 直接改元素字段。父组件持有 ViewModel 用 `@State`，
> 子组件接收同一个 ViewModel 必须用 `@ObjectLink`（不能用 `@Prop`，
> `@Prop` 是深拷贝，改了不会回传）。`@Entry` 组件内不能使用 `@ObjectLink`。

**本项目案例**：`conversationStore.ets` 用 `this.messages.push(userMsg)` 添加消息，
界面永远不会更新。

### 10. 配置项必须单点定义

**给 AI 的指令**：
> 后端地址、超时时间这类配置只允许存在一处（如 `network/AppConfig.ets`）。
> 禁止在具体请求函数里内联硬编码地址。

**本项目案例**：普通请求用 `http://your-backend-url.com/api/v1`（占位符从没改过），
SSE 用 `http://10.0.2.2:8080/api/v1/chat`，两套地址各写各的。

### 11. 不能用 HTTP 状态码判断业务成败

很多后端会给业务错误也带上非 200 的 HTTP 状态码，但响应体里才有真正的错误原因。
如果客户端一看到非 200 就抛"请求失败，状态码 XXX"，用户永远看不到有用的提示。

**给 AI 的指令**：
> 写 HTTP 客户端时，**先无条件尝试解析响应体**，再根据业务 code 判断成败；
> HTTP 状态码只用于识别 401 之类的传输层语义。
> 解析失败时才退回报状态码。不要假设"业务错误一定配 HTTP 200"。

**本项目案例**：登录失败时后端返回
`HTTP 400` + `{"code":2,"message":"手机号未注册","data":{}}`。
第一版 HttpClient 见到 400 就直接抛错、不解析响应体，
"手机号未注册"这句话被完全吞掉。另外注意失败时 `data` 是 `{}` 而不是文档写的 `null`，
不要依赖 data 为 null 来判断失败。

### 12. 长连接必须有取消出口

**给 AI 的指令**：
> SSE / WebSocket / setInterval 这类持续性资源，创建函数必须返回取消函数，
> 并在 `aboutToDisappear` 里调用。否则离开页面后连接和回调仍在运行。

## 四、ArkTS 运行时陷阱

### 13. UTF-8 解码不能逐字节转换

**给 AI 的指令**：
> 把 `ArrayBuffer` 转字符串一律用 `util.TextDecoder`，禁止用
> `String.fromCharCode` 逐字节拼接——一个汉字占 3 字节，逐字节转必然乱码。
> 流式场景必须用 `{ stream: true }`，因为网络分包不会对齐字符边界，
> 一个汉字的字节可能被切在两个数据包里。

**本项目案例**：`apiService.ets` 的 `arrayBufferToString` 逐字节转换，
注释还写着"避免兼容性问题"，但这个方案对所有非 ASCII 字符都是错的。

### 14. 需要显式初始化的单例必须在启动时初始化

**给 AI 的指令**：
> 依赖 `Context` 的单例（如 `dataPreferences`）必须在 `EntryAbility.onCreate`
> 里初始化。同时在未初始化时要大声 `console.error`，不要 `return` 静默失败。

**本项目案例**：`TokenManager.init()` 从来没被调用，`pref` 一直是 null，
`getToken()` 永远返回 null、`setToken()` 静默什么都不做，整条登录链路无声地断掉。
