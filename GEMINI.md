# GEMINI.md

本文件为 Google Antigravity 在此代码库中工作时提供指导与项目开发进度记录。

## 项目概述

本项目是一款基于 **HarmonyOS NEXT (API 24)** 开发的职业考证与在线刷题备考系统——**“育见未来（保育师考证助手）”**。采用 MVVM 架构模式与 ArkUI 声明式 UI 体系开发，遵循 HarmonyOS V2 状态管理机制。

**应用基本信息：**
- **应用名称**：育见未来（保育师考证助手）
- **包名**：`com.yaojiwww.changxi`
- **目标 SDK**：HarmonyOS 6.1.1 (API Level 21) / HarmonyOS NEXT (API 24)
- **构建工具**：Hvigor (HarmonyOS 构建系统)
- **架构模式**：MVVM (Model-View-ViewModel)
- **状态管理**：V2 (`@ObservedV2`, `@Trace`, `@ComponentV2`, `@Local`, `@Param`, `@Event` 等)

---

## 项目架构与规范

### 技术栈
- **系统**: HarmonyOS NEXT (API 24)
- **语言**: ArkTS (TypeScript 扩展)
- **框架**: ArkUI (声明式 UI 框架)
- **状态管理**: V2 版本装饰器（内置全局装饰器，无需且禁止 import）
  - `@ObservedV2` - 观察者类装饰器
  - `@Trace` - 响应式属性追踪
  - `@ComponentV2` - V2 组件装饰器
  - `@Local` - 组件内本地状态
  - `@Param` - V2 组件入参
  - `@Event` - V2 事件回调
- **双向绑定**: 使用 `!!` 语法（严禁使用 `$$`）

### 页面文件目录结构
```text
entry/src/main/ets/
├── api/
│   └── AuthApi.ets                 # 鉴权与用户接口层
├── common/
│   ├── AppConfig.ets               # 全局应用配置
│   ├── Http.ets                    # HTTP 网络请求封装
│   └── TokenStore.ets              # 用户 Token 本地存储
├── entryability/
│   └── EntryAbility.ets            # 应用生命周期入口，加载 pages/LoginPage
└── pages/
    ├── LoginPage.ets               # 登录页（硬编码 13200000000 / 123456 免后端校验）
    ├── HomePage.ets                # 首页核心容器，搭载 Tabs 底部导航与首页完整 UI
    ├── AIChatPage.ets              # AI 伴学助手页（独立组件 AIView）
    └── MinePage.ets                # 个人中心页（独立组件 MineView）
```

## 常用命令与构建

```bash
# 编译打包 Debug HAP
hvigorw assembleHap

# 编译 Release 版本
hvigorw assembleHap --mode release

# 代码检查
hvigorw --sync
```

--- 

测试测试
