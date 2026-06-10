# DayGlyph 第三轮情绪量化、Glyph 与核心 UI 实施计划

> **供代理执行：** 必须使用 `superpowers:test-driven-development` 按任务逐项执行，并在完成前使用 `superpowers:verification-before-completion`。

**目标：** 将 DayGlyph 从单标签模板图案升级为 Foundation Models 驱动的 VAD 多标签情绪印记，并重做今日、月历和详情核心体验。

**架构：** `FoundationEmotionAnalyzer` 输出连续情绪向量和 12 锚点权重，`EmotionAnalysis` 负责规范化，`GlyphGenerator` 将量化结果转换为纯值类型签名，`GlyphCanvasView` 只负责分层绘制。SwiftUI 页面消费同一分析与签名模型，不在视图中复制生成逻辑。

**技术栈：** Swift 5、SwiftUI、SwiftUI Canvas、FoundationModels、SwiftData、AppIntents、Swift Testing、iOS 26.5 Liquid Glass。

---

## 任务 1：分支与分析模型

**文件：**
- 修改 `DayGlyph/Models/Emotion.swift`
- 修改 `DayGlyph/Services/FoundationEmotionAnalyzer.swift`
- 修改 `DayGlyphTests/EmotionAnalyzerTests.swift`
- 新增 `DayGlyphTests/EmotionAnalysisTests.swift`

步骤：

1. 先写失败测试，覆盖 VAD 截断、12 权重归一化、前三项排序、零权重兜底和主情绪计算。
2. 运行对应测试，确认因新类型和接口不存在而失败。
3. 新增 `EmotionAnchor`、`EmotionWeight` 和新版 `EmotionAnalysis`，保留最小兼容计算属性。
4. 将 Foundation Models 结构化输出改为固定 VAD 与 12 权重字段，转换时统一走规范化初始化器。
5. 运行分析相关测试。

## 任务 2：持久化与固定演示数据

**文件：**
- 修改 `DayGlyph/Models/DayEntry.swift`
- 修改 `DayGlyph/Services/DayEntryStore.swift`
- 修改 `DayGlyph/Services/DemoDataSeeder.swift`
- 修改 `DayGlyphTests/DayEntryStoreTests.swift`
- 新增 `DayGlyphTests/DemoDataSeederTests.swift`

步骤：

1. 先写失败测试，覆盖 VAD、权重和 `analysisVersion` 的创建/更新持久化。
2. 为 `DayEntry` 增加默认值字段，并用 JSON `Data` 编码权重；保留旧字段读取兼容。
3. 更新存储服务，统一保存新版分析。
4. 将演示数据改为文本与固定分析夹具，先清理旧 `isDemo` 数据，再生成覆盖全部锚点的新月份。
5. 运行存储与演示数据测试。

## 任务 3：模块化 Glyph 生成器

**文件：**
- 重写 `DayGlyph/Glyph/GlyphSignature.swift`
- 修改 `DayGlyph/Glyph/SeededRandom.swift`
- 新增 `DayGlyph/Glyph/GlyphGenerator.swift`
- 重写 `DayGlyphTests/GlyphSignatureTests.swift`

步骤：

1. 先写失败测试，覆盖确定性、参数范围、权重混合、生气/焦虑/激动差异和 seed 微差异上限。
2. 定义边界、轨迹、核心、节律和外观参数值类型。
3. 实现 VAD 基础映射、12 个情绪算子和参数归一化。
4. 使用稳定 `UInt64` seed，只应用受限偏移。
5. 运行 Glyph 纯逻辑测试。

## 任务 4：Canvas 分层渲染与动效

**文件：**
- 重写 `DayGlyph/Glyph/GlyphCanvasView.swift`
- 新增 `DayGlyph/Glyph/GlyphExplanationView.swift`

步骤：

1. 先补充签名层测试，定义缩略图粒子上限和分层显示阶段。
2. 使用 Canvas 分别绘制纸感徽章、边界、轨迹、核心和节律。
3. 为大图加入 `revealProgress`，按四阶段完成一次性生成。
4. 使用低成本外层光晕做保存后的慢速微动，不持续重算 Canvas 路径。
5. 支持 `accessibilityReduceMotion`，月历模式始终静态。
6. 增加可展开解释视图，展示 VAD、前三权重和四层映射。

## 任务 5：浅色设计系统与今日页

**文件：**
- 重构 `DayGlyph/Views/DayGlyphStyle.swift`
- 重构 `DayGlyph/Views/TodayView.swift`
- 按需要新增 `DayGlyph/Views/TodayInputCard.swift`
- 按需要新增 `DayGlyph/Views/TodayGlyphResultView.swift`

步骤：

1. 建立语义色、间距、圆角、阴影和动效令牌。
2. 用稳定视图树实现输入态与结果态同页转换。
3. 将 Liquid Glass 限制在按钮、标签和交互容器；内容底板保持纸感。
4. 接入生成仪式、成功触觉、编辑/重新生成和错误状态。
5. 加入 TodayView 的主要预览状态和无障碍标签。

## 任务 6：无框月历与详情页

**文件：**
- 重构 `DayGlyph/Views/CalendarView.swift`
- 重构 `DayGlyph/Views/EntryDetailView.swift`

步骤：

1. 月历移除日期白卡，显示静态缩略图和情绪色晕。
2. 新增选中日期状态、玻璃光环和网格下摘要。
3. 详情页使用大 Glyph、解释折叠区、原文纸张卡和系统删除操作。
4. 确保 44pt 触控区域、Dynamic Type 和 VoiceOver 顺序。

## 任务 7：调用方、演示与设置统一

**文件：**
- 修改 `DayGlyph/Intents/DayGlyphIntents.swift`
- 修改 `DayGlyph/Views/SettingsView.swift`
- 修改相关测试

步骤：

1. App Intent 保存新版分析，并用主情绪标题返回对话。
2. 设置页只统一背景、分组材质和设计令牌，不重构信息架构。
3. 更新旧测试和预览夹具，移除对旧单标签几何的断言。

## 任务 8：验证

1. 运行所有 `DayGlyphTests`。
2. 运行完整 `xcodebuild test`，记录 UI 测试结果。
3. 在 iPhone 17 / iOS 26.5 构建并启动。
4. 验证今日输入、生成转换、解释展开、月历选择、详情删除和新演示月。
5. 检查减少动态效果、超大动态字体和 VoiceOver 标签。
6. 检查 `git diff`，确认未包含 `xcuserdata` 或用户现有未跟踪文件。

