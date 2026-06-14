# DayGlyph iOS

DayGlyph 是一个本地优先的 iOS 情绪记录产品原型。用户写下当天的感受后，应用通过设备端 Apple Intelligence 理解情绪结构，并将结果转化为可回顾的视觉印记。

> 当前仓库用于产品评审与原型协作，暂不代表正式发布版本。

## 当前已实现

- 每日文字记录与本地持久化
- 基于 Foundation Models 的设备端情绪分析
- 情绪权重、主题、能量与解释文案
- 确定性生成的每日情绪 Glyph
- 情绪月历与历史记录详情
- 每日提醒与演示数据
- App Intents / Shortcuts 入口
- 单元测试与 Apple Intelligence 环境诊断

所有日记原文与分析结果默认保存在设备本地。

## 当前产品方向

当前可运行版本仍以“每日一划”和情绪 Glyph 为核心视觉。

产品团队正在评审下一阶段体验：以“情绪鸡尾酒”替代 Glyph，并扩展情绪宇宙、微行动、行动回声、时间来信与共情海。相关设计稿见：

- [`docs/superpowers/specs/2026-06-14-dayglyph-emotional-support-expansion-design.zh-CN.md`](docs/superpowers/specs/2026-06-14-dayglyph-emotional-support-expansion-design.zh-CN.md)

上述下一阶段功能尚未在当前代码中实现。

## 技术栈

- SwiftUI
- SwiftData
- Foundation Models
- App Intents
- UserNotifications
- Swift Testing
- SwiftUI Canvas

## 运行要求

- Xcode 26.5
- iOS 26.5 Simulator Runtime
- 推荐设备：iPhone 17 模拟器
- 完整 AI 路径需要 Apple Intelligence 可用且本地模型已完成下载

打开 `DayGlyph.xcodeproj`，选择 `DayGlyph` Scheme 后运行。

如果 Apple Intelligence 不可用，应用会显示具体环境状态。真实 Foundation Models 测试要求见：

- [`docs/testing/2026-06-10-apple-intelligence-outsourcing-test-requirements.zh-CN.md`](docs/testing/2026-06-10-apple-intelligence-outsourcing-test-requirements.zh-CN.md)

## 测试

```bash
xcodebuild \
  -project DayGlyph.xcodeproj \
  -scheme DayGlyph \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:DayGlyphTests \
  test
```

## 仓库说明

- `main`：供产品与研发共同查看的最新稳定原型
- `docs/superpowers/specs/`：产品与体验设计文档
- `docs/superpowers/plans/`：实现计划与历史执行记录
- `docs/testing/`：专项测试要求

当前产品名 `DayGlyph` 为工程与沟通代号，正式品牌名仍待产品评审。
