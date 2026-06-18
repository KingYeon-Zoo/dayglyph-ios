# DayGlyph v2 Stage 4 与 Stage 5 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 完成回声、通知、我的、首次引导与设置隐私闭环，并用本地优先、非医疗化的方式替换两个占位 Tab。

**架构：** 延续 SwiftData 本地模型，以 `ActionResponse` 补齐行动反馈，以纯函数聚合器生成个人发现、成就与统计。`NotificationScheduler` 把每日记录、行动回声和时间来信统一为可测试的通知描述，再由 `ReminderService` 对接 `UserNotifications`。SwiftUI 页面只查询模型并调用这些稳定接口，首次引导通过 `@AppStorage` 控制，不阻塞离线使用。

**技术栈：** SwiftUI、SwiftData、Swift Testing、UserNotifications、Charts、ImageRenderer、UserDefaults/AppStorage

---

### 任务 1：行动反馈模型与回声聚合

**文件：**
- 修改：`DayGlyph/Models/TodaySupportModels.swift`
- 新建：`DayGlyph/Models/EchoModels.swift`
- 新建：`DayGlyph/Services/EchoAggregator.swift`
- 新建：`DayGlyphTests/EchoAggregatorTests.swift`
- 修改：`DayGlyph/DayGlyphApp.swift`

- [ ] 先写失败测试，覆盖四种中性反馈、跳过反馈、到期判断，以及同类别至少三次才生成发现。
- [ ] 运行 `xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:DayGlyphTests/EchoAggregatorTests`，确认因类型缺失而失败。
- [ ] 增加 `ActionResponse` SwiftData 模型、`ActionResponseKind`、`EchoInsight` 与 `EchoAggregator`，并给 `ActionInstance` 增加稳定的行动标题与类别快照，避免目录文案变化破坏历史。
- [ ] 把 `ActionResponse` 注册到应用 Schema，重跑定向测试并确认通过。

### 任务 2：统一通知调度

**文件：**
- 新建：`DayGlyph/Models/NotificationModels.swift`
- 新建：`DayGlyph/Services/NotificationScheduler.swift`
- 修改：`DayGlyph/Services/ReminderService.swift`
- 新建：`DayGlyphTests/NotificationSchedulerTests.swift`

- [ ] 先写失败测试，验证三类稳定 identifier、关闭模块时的取消集合、行动/来信单次触达和每日重复提醒。
- [ ] 运行通知调度定向测试，确认缺少实现导致失败。
- [ ] 实现无框架依赖的通知描述构造器；让 `ReminderService` 统一提交与取消请求，并保留旧每日提醒入口兼容现有调用。
- [ ] 重跑定向测试确认通过。

### 任务 3：E-00、E-02、E-03 回声体验

**文件：**
- 新建：`DayGlyph/Views/Echo/EchoHomeView.swift`
- 新建：`DayGlyph/Views/Echo/ActionResponseSheet.swift`
- 新建：`DayGlyph/Views/Echo/EchoInsightsView.swift`
- 修改：`DayGlyph/Views/AppRootView.swift`
- 修改：`DayGlyph/Views/Today/MicroActionSection.swift`
- 新建：`DayGlyphTests/EchoCopyTests.swift`

- [ ] 先写文案与状态测试，确保四个反馈选项中性，空状态和不足三次时不输出伪发现。
- [ ] 运行测试确认失败。
- [ ] 微行动完成后设置 `followUpAt`；回声首页按等待、到期和最近回应分段；反馈 Sheet 支持四选一、备注和“不记录感受”；发现页展示样本次数、时间范围和文字分布。
- [ ] 用 `EchoHomeView` 替换占位页，运行定向测试与构建。

### 任务 4：M-00 至 M-04 我的模块

**文件：**
- 新建：`DayGlyph/Models/MineModels.swift`
- 新建：`DayGlyph/Services/MineAggregator.swift`
- 新建：`DayGlyph/Services/LocalDataExporter.swift`
- 新建：`DayGlyph/Views/Mine/MineHomeView.swift`
- 新建：`DayGlyph/Views/Mine/AchievementsView.swift`
- 新建：`DayGlyph/Views/Mine/EmotionHistoryView.swift`
- 新建：`DayGlyph/Views/Mine/EmotionStatisticsView.swift`
- 修改：`DayGlyph/Views/SettingsView.swift`
- 修改：`DayGlyph/Services/DemoDataSeeder.swift`
- 修改：`DayGlyph/Views/AppRootView.swift`
- 新建：`DayGlyphTests/MineAggregatorTests.swift`
- 新建：`DayGlyphTests/DemoDataSafetyTests.swift`

- [ ] 先写失败测试，覆盖累计而非连续的成就、至少七天趋势门槛、搜索过滤、演示数据清理不影响真实记录，以及全量删除关联对象。
- [ ] 运行定向测试确认失败。
- [ ] 实现个人汇总、成就、历史搜索删除、统计复用宇宙聚合结果、本地 JSON 导出和分享；设置页增加行动偏好、模块开关、演示数据、安全确认与系统设置入口。
- [ ] 替换我的占位页，重跑定向测试和构建。

### 任务 5：O-01 至 O-03 引导与全局状态

**文件：**
- 新建：`DayGlyph/Views/Onboarding/OnboardingView.swift`
- 修改：`DayGlyph/Views/AppRootView.swift`
- 修改：`DayGlyph/Views/SettingsView.swift`
- 新建：`DayGlyphTests/OnboardingCopyTests.swift`
- 修改：`DayGlyphUITests/DayGlyphUITests.swift`

- [ ] 先写失败测试，固定三屏标题、隐私承诺和通知只能由明确开关触发的规则。
- [ ] 运行测试确认失败。
- [ ] 实现可跳过三屏引导、本地隐私说明、最少偏好与显式通知授权；设置页可重新查看或重置引导。
- [ ] 为删除确认、导出失败与成功提示使用系统 Alert/ConfirmationDialog/Sheet，补关键可访问标识。
- [ ] 重跑定向测试、全量单元测试和两个基准尺寸 UI 烟雾测试。

### 任务 6：验收、文档、合并与推送

**文件：**
- 修改：`设计路线图.md`
- 修改：`README.md`（仅当功能说明需同步）

- [ ] 将 Stage 4/5 状态和交付项更新为完成，检查新增用户文案均为简体中文且无诊断或惩罚表达。
- [ ] 运行 `xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`。
- [ ] 运行 `xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'generic/platform=iOS Simulator'`。
- [ ] 检查 `git diff --check`、工作区差异与提交内容，提交 Stage 4/5。
- [ ] 获取远端 `main`，将当前功能分支合并到 `main`，在合并结果上再次运行全量测试。
- [ ] 推送 `main` 到 `origin` 并确认本地与远端提交一致。
