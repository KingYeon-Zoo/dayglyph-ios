# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## 项目概览

DayGlyph 是一款本地优先、非医疗化的 iOS 情绪记录应用（SwiftUI + SwiftData，目标 iOS 26.5 / Xcode 26.5）。用户写下一句话，应用生成情绪鸡尾酒与日星球，并提供微行动、回声与长期回顾。所有界面文案为简体中文，`AppRootView` 强制 `Locale("zh_CN")`。

## 常用命令

构建（无需模拟器）：

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph \
  -destination 'generic/platform=iOS Simulator'
```

运行单元测试（需已安装对应模拟器）：

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:DayGlyphTests
```

运行单个测试类型 / 单个用例（Swift Testing，按类型与方法过滤）：

```bash
# 整个测试类型
xcodebuild test ... -only-testing:DayGlyphTests/EmotionAnalysisTests
# 单个 @Test 方法
xcodebuild test ... -only-testing:DayGlyphTests/EmotionAnalysisTests/clampsContinuousDimensionsAndConfidence
```

测试框架是 **Swift Testing**（`import Testing`、`@Test`、`#expect`），不是 XCTest。测试类型通常标注 `@MainActor`。UI 测试在 `DayGlyphUITests`。

## 架构要点

数据流分层（见 README「工程架构」），但以下几点只有读代码才能发现：

### 情绪分析有多个入口，必须区分

- `SeedTextClient` / `SeedImageClient` — **当前生产路径**，直连火山方舟豆包（Seed 2.0 Lite 文本 + Seedream 生图）。由 `DayGenerationOrchestrator` 状态机编排，`GenerationAnalysisMapper` 把 1～8 种复杂情绪投影回 `EmotionAnalysis`（VAD + 12 锚点权重）以复用下游视觉/统计。详见 `docs/superpowers/specs/2026-06-20-dayglyph-doubao-ai-generation-design.zh-CN.md`。
- `UnifiedEmotionAnalyzer` / `FoundationEmotionAnalyzer` — 设备端 Apple Intelligence 路径，现**保留为离线降级**，核心演示流程不依赖它。`@Generable FoundationEmotionOutput` + `FoundationModels` 结构化输出，可用性由 `AppleIntelligenceStatus.current` 判断。
- `EmotionAnalyzer` — 纯本地中文关键词规则引擎，确定性降级路径，`source = .localRules`。修改情绪/主题识别逻辑（关键词表、energy/confidence 评分）改这里。

注入测试用的假分析器时，实现 `FoundationEmotionAnalyzing` 协议传入 `UnifiedEmotionAnalyzer(foundationAnalyzer:)`。

### 情绪模型有双重表示，新代码用 EmotionAnchor

`Emotion.swift` 同时存在 `DayEmotion`（旧的 8 类枚举）和 `EmotionAnchor`（12 锚点 + VAD 连续空间）。`EmotionAnalysis` 以 `emotionWeights: [EmotionWeight]` + valence/arousal/dominance 为权威表示。`DayEmotion` 通过 `.anchor` / `.legacyEmotion` 桥接，仅为兼容保留。**新功能基于 `EmotionAnchor` 和权重，不要新增对 `DayEmotion` 的依赖。** `EmotionAnalysis` 在初始化时会 clamp 各维度并归一化权重。

### 确定性是硬约束

同一段文字 + 同一天必须生成稳定结果，历史不能随机变化：

- `GlyphSignature.seed(for:date:)` 用文本 hash + 当天 0 点时间戳生成种子；所有随机性走 `SeededRandom(seed:)`。
- `GlyphSignature.init` 把分析结果通过固定权重公式映射成几何/调色板参数——改视觉公式会改变所有历史记录的呈现。
- 视觉产物（recipe / cocktail / planet / weather）由 `EmotionVisualFactory.makeVisuals` 生成。

### SwiftData 持久化约定

- `DayEntryStore.saveEntry` 是唯一写入入口：按当天 0 点去重（一天一条，存在则 `update`），自动算 seed、生成视觉、`context.save()`。不要绕过它直接 insert。
- `DayEntry` 把复杂值类型（权重、四种视觉）以 JSON `Data` 字段存储，通过计算属性解码；解码失败时回退到 `EmotionVisualFactory` 重新生成。新增字段需提供默认值以兼容旧数据（注意 `analysisVersion` / `visualVersion`）。
- Schema 在 `DayGlyphApp.swift` 注册：`DayEntry`、`ActionInstance`、`TimeLetter`、`EmpathyCopy`、`ActionResponse`、`AIGenerationRecord`。新增 `@Model` 必须加进这个 Schema 数组。
- AI 生成版本独立存于 `AIGenerationRecord`（不进 `DayEntry`），图片落本地 `Application Support/DayGlyphGenerated/`（JPEG），SwiftData 只存路径与状态；增删走 `GenerationRepository` / `GeneratedAssetStore`。
- 演示数据用 `isDemo` 标记，可单独清除（`DemoDataSeeder` / `LocalDataExporter`）。

### 业务逻辑集中在 Services 的 Aggregator

聚合与派生数据不放在 View 里，而是 `*Aggregator`（`UniverseAggregator`、`UniverseTrendAggregator`、`EchoAggregator`、`MineAggregator`）。这些是可测试的纯逻辑，对应 `DayGlyphTests` 里的同名测试。改统计/趋势/回声逻辑改 Aggregator，不要在 View 内联计算。

### 四 Tab 结构

`AppRootView` = TabView（今日 / 宇宙 / 回声 / 我的）+ 首启 `OnboardingView`（由 `@AppStorage("hasCompletedOnboarding")` 控制）。每个 Tab 的 Home 在 `Views/Today`、`Views/Universe`、`Views/Echo`、`Views/Mine`。宇宙的 RealityKit 体验（`UniverseRealityView`）必须提供二维可访问降级（`UniverseAccessibleList`），由 `UniverseRenderingPolicy` / `UniverseInteractionPolicy` 决策。

## 工程约定（踩过的坑）

- **新增源文件零配置**：工程用文件系统同步组（`PBXFileSystemSynchronizedRootGroup`）。新 `.swift` 落在 `DayGlyph/` 目录树即自动编译，不要手改 `.pbxproj`。
- **MainActor 默认隔离**：纯 Sendable 值类型（Codable struct、配置、无状态文件存储）需显式标 `nonisolated`，否则在非主线程上下文出现 actor 隔离告警（Swift 6 下为错误）。
- **测试共享静态状态要序列化**：Swift Testing 默认并行。带 static 状态的测试（如 `MockURLProtocol`）须用 `@Suite(.serialized)` 包裹，否则跨套件交错导致偶发失败。
- **演示密钥隔离**：真实火山方舟 Key 在 `DayGlyph/Services/AISecrets.swift`（已 gitignore），模板见 `AISecrets.template.txt`。`AIConfiguration.demo` 引用它，勿把 Key 写进任何入库文件。

## 产品约束（影响实现决策）

- 非医疗化：不诊断、不分级、不承诺疗效；文案与功能都不能违反。
- 低压力：不做连续签到、排行榜、断签惩罚。
- 可访问：支持减少动态、大字体、VoiceOver；图表须有文字替代。
- 共情海（`EmpathySea*`）当前为本地审核样本演示，任何可能公开的副本需二次确认。

详细设计见 `产品文档.md`、`设计路线图.md`、`docs/superpowers/plans/`。
