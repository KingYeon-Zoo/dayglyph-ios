<p align="center">
  <img src="images/readme/dayglyph-logo.png" width="96" alt="DayGlyph 日迹" />
</p>

# DayGlyph 日迹

**用情绪鸡尾酒、日星球和长期星图，记录一天中难以用单一标签概括的感受。**

写下一段话，留下当日情绪与一个可选择的微行动。过一段时间再记录行动后的感受，把离散日记连成可以回看的个人历史。

<p align="center">
  <img src="images/readme/preview-today.jpg" width="30%" alt="实际应用界面：今日记录与情绪印记" />
  <img src="images/readme/preview-universe.jpg" width="30%" alt="实际应用界面：个人情绪宇宙" />
  <img src="images/readme/preview-mine.jpg" width="30%" alt="实际应用界面：历史与个人记录" />
</p>

[观看演示](https://github.com/KingYeon-Zoo/dayglyph-ios/releases/download/showcase-2026/DayGlyph-Product-Demo-4K.mp4) · [产品文档](docs/product/DayGlyph-产品文档.pdf) · [核心设计](#核心设计) · [运行与测试](docs/运行与测试.md) · [核心逻辑复核](docs/reviews/2026-09-05-core-review.md)

## 记录之后，还能做什么

- **今日：** 记录文字，查看情绪构成、鸡尾酒与日星球，选择适合当下的微行动。
- **宇宙：** 按月浏览记录与星图，查看较长时间内的情绪变化。
- **回声：** 留下行动后的真实感受，回看个人历史中的关联。
- **我的：** 浏览历史、管理偏好，导出或清除本地数据。

产品不做心理诊断，不承诺疗效，也不用连续签到制造压力。趋势与行动反馈只呈现观察到的关联。

## 核心设计

### 用连续空间表达复合情绪

情绪分析以 VAD（愉悦度、唤醒度、支配感）和 12 个情绪锚点权重表示。多个感受可以同时存在，后续视觉与统计共享这份结构化表示。

本地视觉映射将情绪权重转换为鸡尾酒配比、颜色和星球参数。固定输入与日期产生稳定种子，历史星图的布局不会在每次打开时随机改变。在线生成的图片则保存为独立产物，不等同于确定性的程序化视觉。

### 端侧分析与在线生成各有入口

| 路径 | 实现与数据去向 |
| --- | --- |
| Apple 端侧情绪分析 | `FoundationEmotionAnalyzer` 通过 Foundation Models 生成结构化结果，在支持 Apple Intelligence 的设备上执行。仓库保留该分析实现及测试。 |
| 本地规则分析 | `EmotionAnalyzer` 使用中文规则生成分析结果，供本地分析流程在模型不可用时使用。 |
| 豆包增强生成 | 当前主界面生成流程通过 Seed 文本模型与 Seedream 图像模型生成叙事、鸡尾酒及日星球图片，相关输入会发送至火山方舟。 |

记录与生成产物通过 SwiftData 和本地图片文件保存。端侧分析与在线生成是不同实现路径，当前在线生成失败不等于会自动切换为完整的 Apple 端侧体验。

### 把每日记录接到长期回顾

微行动、延迟回声与趋势统计围绕本地记录展开。聚合逻辑集中在服务层，界面读取计算结果；生成任务分别记录文本与图片状态，单项失败可独立重试。

界面支持减少动态、VoiceOver 与文字替代，情绪宇宙同时保留二维可访问路径。

## 代码导览

| 设计 | 实现入口 |
| --- | --- |
| VAD 与情绪权重 | [Emotion.swift](DayGlyph/Models/Emotion.swift) |
| 稳定种子与视觉参数 | [GlyphSignature.swift](DayGlyph/Glyph/GlyphSignature.swift) |
| Apple 端侧结构化分析 | [FoundationEmotionAnalyzer.swift](DayGlyph/Services/FoundationEmotionAnalyzer.swift) |
| 本地规则分析 | [EmotionAnalyzer.swift](DayGlyph/Services/EmotionAnalyzer.swift) |
| 在线生成状态与单项重试 | [DayGenerationOrchestrator.swift](DayGlyph/Services/DayGenerationOrchestrator.swift) |
| 生成结果映射回情绪模型 | [GenerationAnalysisMapper.swift](DayGlyph/Services/GenerationAnalysisMapper.swift) |
| 核心测试 | [情绪权重](DayGlyphTests/EmotionAnalysisTests.swift)、[确定性映射](DayGlyphTests/GlyphSignatureTests.swift)、[模型响应映射](DayGlyphTests/GenerationAnalysisMapperTests.swift) |

## 本地运行

使用兼容项目目标的 Xcode 与 iOS 运行环境。当前工程目标为 iOS 26.5，在线生成需要自行配置火山方舟凭证。

```bash
git clone https://github.com/KingYeon-Zoo/dayglyph-ios.git
cd dayglyph-ios
```

按[运行与测试说明](docs/运行与测试.md)创建本地密钥文件，再打开 `DayGlyph.xcodeproj` 构建。真实密钥文件已排除出版本控制。

演示启动脚本会重置所选模拟器中的应用数据，使用前请阅读说明。端侧模型可用性取决于设备与系统条件，不能用模拟器构建成功代替端侧模型验证。

## 项目工作与资料

这是一个独立开发项目，工作覆盖产品需求、视觉交互、SwiftUI 客户端、本地数据模型、情绪视觉映射与测试。Apple Intelligence 和豆包提供模型能力，项目侧负责数据表示、交互流程、生成控制与长期记录。

更多界面可查看[今日体验](images/readme/feature-today.jpg)、[宇宙与趋势](images/readme/feature-universe.jpg)、[行动回声](images/readme/feature-echo.jpg)。

仓库尚未附带开源许可证，保留现有版权状态。
