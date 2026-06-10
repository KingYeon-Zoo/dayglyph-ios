# DayGlyph 图标与 Apple Intelligence 诊断改造设计

日期：2026-06-10

## 背景

现有 App Icon 使用圆环、斜向指针和底部圆点，缩小后接近仪表盘，线条关系杂乱，也没有准确表达 DayGlyph 的“一划”概念。

App 已接入 Foundation Models，但当前开发环境的 `SystemLanguageModel.default.availability` 返回 `deviceNotEligible`。宿主设备为中国大陆购买的 Mac，Apple 官方说明此类设备目前不能启用 Apple Intelligence。iOS 模拟器使用宿主 Mac 的模型，因此不能通过 App 代码或模拟器设置绕过这一系统资格限制。

## 已确认方向

采用图标方案 A“一笔日痕”，并保持真实 Apple Intelligence 接入：

- 不使用本地规则冒充 Apple Intelligence。
- Foundation Models 可用时优先运行系统模型。
- 不可用时继续使用本地分析，确保 demo 可操作。
- UI 显示系统返回的具体不可用类别，不再只写笼统的“当前不可用”。

## App Icon

### 视觉结构

- 使用暖白到浅青灰的安静背景。
- 中心只保留一条深绿色连续笔迹。
- 笔迹形成未完全闭合的圆形轨迹，表达一天留下的一划。
- 使用一个小型珊瑚色圆点作为日期落点。
- 不使用文字、外框、表盘刻度、指针或额外装饰线。
- 在主屏幕小尺寸下仍需清楚识别为“笔迹 + 落点”。

### 图标变体

- 默认：浅色背景、深绿色笔迹、珊瑚色落点。
- 深色：深墨绿色背景、浅色笔迹、暖色落点。
- 着色：使用单色层级，确保系统 tinted 模式下结构清楚。

三张资源均为 1024 x 1024 PNG，由确定性的本地绘制脚本生成，避免生成式图片造成边缘、比例和变体不一致。

## Apple Intelligence 状态模型

新增独立的可用性描述层，将 Foundation Models 的系统状态映射为 App 自己的展示模型：

- `available`：Apple Intelligence 可用。
- `appleIntelligenceNotEnabled`：设备支持，但用户尚未开启。
- `modelNotReady`：模型仍在准备或下载。
- `deviceNotEligible`：设备、地区或系统资格不符合要求。
- `unknown`：未来系统新增了尚未识别的状态。

状态模型提供：

- 简短标题。
- 面向用户的说明。
- 是否可以尝试 Foundation Models。
- 对应的 SF Symbol 和强调颜色语义。

视图层不直接解析 Foundation Models 的字符串输出。

## UI 调整

### 今日页

现有 Apple Intelligence 卡片改为实时状态：

- 可用时显示“Apple Intelligence 已就绪”。
- 未开启时提示前往系统设置开启。
- 模型未就绪时提示等待模型准备完成。
- 设备不符合资格时明确显示“此设备不符合 Apple Intelligence 运行条件”。
- 所有不可用状态同时说明 DayGlyph 会使用本地分析，不影响保存和 Glyph 生成。

分析完成后，结果卡继续显示真实来源：

- 系统模型成功：`Apple Intelligence 已参与理解`。
- 本地规则：`本地理解`。
- 系统模型失败后回退：`已使用本地回退`。

### 设置页

增加“Apple Intelligence”诊断区：

- 当前状态。
- 当前运行环境是模拟器还是实体设备。
- 简短解决建议。
- Apple 官方可用性说明链接。

不提供“强制开启”或“模拟已启用”开关，避免 demo 对能力来源产生误导。

## 环境结论

当前 Mac：

- Apple M5，macOS 26.5.1。
- 型号 `MDH74CH/A`，中国大陆购买版本。
- 系统语言与区域为简体中文、中国大陆。
- Foundation Models 返回 `deviceNotEligible`。

因此当前模拟器不能运行真实 Foundation Models。真实验证需要以下任一环境：

- Apple Intelligence 已启用且符合地区资格的 Apple silicon Mac，运行 iOS 26 或更高版本模拟器。
- 支持 Apple Intelligence、已启用该功能且运行 iOS 26 或更高版本的实体 iPhone 或 iPad。

## 测试

- 可用性映射的每个已知状态都有单元测试。
- `deviceNotEligible` 的 UI 文案不声称 Apple Intelligence 已参与分析。
- Foundation Models 不可用时统一分析器仍可靠回退。
- App Icon 三个 PNG 均为 1024 x 1024，且 Xcode Asset Catalog 正确引用。
- 在 iPhone 模拟器构建并运行，检查今日页与设置页状态。
- 运行全部现有单元测试，确保情绪分析、存储、Glyph 和 App Intents 无回归。

## 非目标

- 不绕过 Apple 的地区、账户或设备资格限制。
- 不修改用户的系统区域、Apple 账户或系统安全设置。
- 不添加云端模型。
- 不把本地分析标记成 Apple Intelligence。
