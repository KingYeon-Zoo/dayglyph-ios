# 2026-09-05 核心逻辑复核

基线：[`bf77f85`](https://github.com/KingYeon-Zoo/dayglyph-ios/commit/bf77f8572775605a94e92cc3b486b3c5d09ce4dc)。本次代码检查、修复与命令行测试由 Codex 执行；维护者本人对最终差异的审阅状态见 PR 勾选项。

## 发现与修改

豆包响应经 `GenerationAnalysisMapper` 转为情绪分析后，原来使用 `foundationModel` 来源值；这个值的显示文案是“Apple Intelligence 已参与理解”。`GenerationProgressViewModel` 会把它保存到日记，读取 `analysisSource.title` 的界面因此可能显示错误来源。

此次新增 `cloudModel`，将在线映射结果标为“在线模型已参与理解”。Apple 分析器仍使用 `foundationModel`，演示数据仍由 `DemoDataSeeder` 明确覆盖为 `demoFixture`。旧记录只有来源字符串，无法可靠区分当时走过的路径，因此不批量改写历史值。

## 核对范围与结果

| 核对内容 | 代码与验证 |
| --- | --- |
| 在线与 Apple 来源 | [映射器](../../DayGlyph/Services/GenerationAnalysisMapper.swift)、[来源枚举](../../DayGlyph/Models/Emotion.swift)；回归检查在线来源值和文案，检查来源编解码与旧值兼容。Apple 分析器只做代码核对。 |
| VAD 与情绪权重 | [EmotionAnalysisTests](../../DayGlyphTests/EmotionAnalysisTests.swift)；检查维度边界、权重归一化及零权重回退。 |
| 确定性视觉 | [GlyphSignatureTests](../../DayGlyphTests/GlyphSignatureTests.swift)；检查相同输入的稳定性、情绪结构差异及种子微扰范围。 |

本地环境：Xcode 26.6（17F113）、Swift 6.3.3、Apple Silicon。执行：

```bash
bash scripts/test-core.sh
```

先把来源回归断言加到旧实现上：14 项测试中 1 项失败，报出 `foundationModel != cloudModel` 和文案包含 `Apple`。修复后：**3 个测试组、14 项测试全部通过**。

脚本直接复制指定生产源文件与测试到临时 Swift Package，使用 Swift 5 语言模式及生产模块的默认 MainActor 隔离。它验证 macOS 上的核心逻辑，不构建完整 iOS 应用。本次未运行真机 UI、SwiftData 集成测试、Apple 端侧模型或豆包在线请求。

后续 PR 会自动执行相同脚本，日志见 [GitHub Actions](https://github.com/KingYeon-Zoo/dayglyph-ios/actions/workflows/core-tests.yml)。自动检查与本人自审分别记录。
