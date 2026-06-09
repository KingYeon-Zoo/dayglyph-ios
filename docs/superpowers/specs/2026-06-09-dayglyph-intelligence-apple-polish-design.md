# DayGlyph 智能分析与 Apple 化视觉改造设计

日期：2026-06-09

## 背景

当前 DayGlyph demo 已经完成基础闭环：用户输入当天记录，App 进行本地规则分析，生成 SwiftUI Canvas Glyph，保存到 SwiftData，并在今日、月历、详情和设置页展示。这个版本适合说明产品流程，但在三个关键点上还不够像一个可信的 Apple 平台产品：

1. 情绪分析依赖很短的关键词表，未命中就回到“混合 / 未知”，对口语、隐含表达、错别字和模糊状态判断太弱。
2. Glyph 由随机弧线、折线、波形和点阵组成，线条秩序、留白、笔触统一性和图标质感不足。
3. 代码没有真正接入 Apple Intelligence 相关能力：没有 Foundation Models，也没有 App Intents。

本次改造采用已确认的方案 B：智能 + Apple 化。

## 目标

本次改造要让 demo 从“能跑通”提升到“能让甲方相信产品方向”：

- 情绪理解不再像关键词玩具，普通日常语句不应轻易显示“未知”。
- Glyph 视觉从随机线条变成稳定、克制、几何化、接近 Apple 平台审美的符号系统。
- App 具备明确的 Apple Intelligence 接入：App 内使用 Foundation Models 增强理解，系统层使用 App Intents 暴露核心动作。
- 所有智能能力必须可回退，不能因为模拟器、设备未开启 Apple Intelligence 或模型不可用而破坏 demo。

## 非目标

本次不做以下内容：

- 不接入云端 AI 或第三方模型。
- 不做 iCloud 同步、账号系统或跨设备历史。
- 不实现完整统计报表。
- 不把全部 SwiftData 记录建成复杂 AppEntity 图谱。
- 不要求 Foundation Models 在所有运行环境中一定可用；必须优雅回退。
- 不把 Glyph 生成改成图片生成服务；仍然使用本地确定性渲染。

## 设计原则

1. **本地优先**：记录、分析结果和 Glyph 生成仍默认保存在本机。
2. **智能可用但不脆弱**：Foundation Models 是优先路径，本地增强规则是稳定路径。
3. **结果可解释**：情绪、主题、能量和关键词要有简短解释，避免黑箱判断。
4. **视觉有系统**：Glyph 必须由明确的几何语法生成，而不是随机线条堆叠。
5. **系统入口克制**：App Intents 暴露最小有用动作，不镜像整个 App 导航。

## 情绪分析改造

### 输出模型

`EmotionAnalysis` 扩展为更适合智能与 UI 展示的结构：

- `emotion: DayEmotion`
- `theme: DayTheme`
- `energy: Double`
- `keywords: [String]`
- `confidence: Double`
- `explanation: String`
- `source: AnalysisSource`

`AnalysisSource` 至少包含：

- `foundationModel`
- `localRules`
- `fallback`

`confidence` 用于 UI 表达判断强度。低置信度不再默认展示失败感强的“未知”，而是展示更自然的“待理解”或“混合”，并在详情中用解释说明“今天的表达比较含蓄”。

### Foundation Models 路径

新增一个独立服务，例如 `FoundationEmotionAnalyzer` 或 `IntelligentEmotionAnalyzer`，内部使用 Foundation Models：

- 用结构化输出生成情绪分析结果。
- Prompt 明确要求只从 DayGlyph 支持的情绪和主题枚举中选择。
- 要求模型处理中文口语、错别字、隐含状态和短句。
- 要求输出简短解释，不生成医疗、诊断或绝对化判断。
- 失败时抛出或返回不可用状态，由上层自动走本地规则。

Foundation Models 可用性检查必须覆盖：

- 设备或系统不支持。
- Apple Intelligence 未开启。
- 模型尚未下载或暂不可用。
- 当前语言或地区不支持。
- 生成失败或结构化输出无法解析。

UI 不直接依赖 Foundation Models 类型。今日页只调用统一分析服务，避免平台 API 泄漏到视图层。

### 本地增强规则路径

现有 `EmotionAnalyzer` 的关键词表过薄，需要改成分层规则：

1. 情绪词典：正向、低落、焦虑、疲惫、平静、感恩、兴奋、混合。
2. 隐含表达：如“撑住了”“说不上来”“不想动”“松了一口气”“终于搞完”“脑子很乱”。
3. 时间和状态表达：如“很早搞完”“一早就处理完”“拖了很久终于结束”，不能因为没有情绪词就未知。
4. 强度修正：标点、重复词、程度副词、否定词、转折词影响能量和置信度。
5. 主题词典：工作、关系、成长、休息、家庭、健康、创造，并支持日常近义词。

本地规则的默认策略：

- 空文本：不分析。
- 普通文本但情绪不强：优先给出“平静 / 混合”而不是“未知”。
- 主题不明显：可保留“生活”或“日常”类展示文案；数据层仍可映射到 `.unknown` 或新增更合适枚举。
- 只有在文本极短且没有可用信息时，才显示“待理解”。

### UI 展示

今日结果和详情页显示：

- 情绪标签。
- 主题标签。
- 能量百分比。
- 可选的简短解释，例如“这段话更像是完成后的释放感”。
- 如果 `source == foundationModel`，可以显示低调标记“Apple Intelligence 已参与理解”。
- 如果走本地规则，则不强调降级，避免让 demo 看起来失败。

## Glyph 与 App Icon 改造

### Glyph 视觉方向

新的 Glyph 系统使用“Apple 化几何徽章”方向：

- 统一圆角和留白。
- 控制线条数量和层级。
- 使用少量稳定形状：圆环、胶囊线、圆点、短弧、内切几何块。
- 避免杂乱折线和过多随机路径。
- 使用克制渐变、内阴影或透明层次，但不做浮夸装饰。
- 小尺寸月历缩略图必须仍然清晰。

### 视觉参数

`GlyphSignature` 扩展为稳定视觉参数：

- `baseShape`：主结构，例如圆环、双环、胶囊轨道、柔和方印。
- `accentShape`：辅助符号，例如点、短弧、斜切胶囊、小圆。
- `palette`：情绪色板，包含背景、主色、辅色、强调色。
- `density`：由能量决定，影响元素数量和对比，不再直接制造乱线。
- `calmness` 或 `tension`：由情绪和置信度决定，影响对称性与偏移幅度。
- `themeMark`：由主题决定的小型辅助符号。

情绪映射：

- 平静：低对比圆环、柔和青绿、对称结构。
- 喜悦：暖黄强调、轻微上扬弧线。
- 低落：蓝灰低饱和、下沉小点或短弧。
- 焦虑：紫蓝、轻微错位双环，但保持秩序。
- 激动：珊瑚红强调、放射式短胶囊，数量受控。
- 疲惫：灰褐、低密度、厚重但安静。
- 感恩：金橙、包裹式圆弧。
- 混合：双色分层，但不变成杂色噪音。

### Canvas 渲染

`GlyphCanvasView` 保留 SwiftUI Canvas，但重写绘制逻辑：

- 绘制背景徽章。
- 绘制主几何结构。
- 绘制主题辅助符号。
- 绘制能量层或强调点。
- 所有随机数只用于细微偏移，不能破坏整体几何秩序。

同一文本、同一天、同一分析结果必须稳定复现。

### App Icon

补齐 `Assets.xcassets/AppIcon.appiconset`：

- 默认 1024 图标。
- 暗色图标。
- tinted 图标。

App Icon 使用与 App 内 Glyph 同源的几何语言，但要更简洁：

- 暖白或系统感浅底。
- 中心为“一划”几何符号。
- 高识别度、少细节、适合小尺寸。
- 避免复杂文字。

## Apple Intelligence 与系统入口

### Foundation Models

Foundation Models 用于 App 内文本理解。它不是唯一分析路径，而是增强路径：

- 可用时优先分析。
- 不可用时自动回退。
- 结果必须转换成本地 `EmotionAnalysis`。
- 不把原文发送到云端。

### App Intents

新增独立的 App Intents 层，暴露最小有用能力：

1. **记录今天的一划**
   - 参数：文本。
   - 行为：分析文本、生成或更新今天的记录。
   - 可在不打开 App 的情况下完成；如果系统限制需要打开，则落到今日页。

2. **打开今日**
   - 行为：打开 App 并进入今日页。

3. **打开情绪月历**
   - 行为：打开 App 并进入月历页。

第一版不需要把每条 `DayEntry` 都暴露成完整 `AppEntity`。如果为了 Spotlight 或后续 Siri 查询需要实体，可先定义很薄的 `DayEntryEntity`，只包含日期、情绪标题、主题标题和展示名称，不暴露完整文本。

### 路由与数据复用

App Intents 不应复制业务逻辑。应复用：

- 统一分析服务。
- 记录保存 / 更新逻辑。
- Glyph seed 生成逻辑。

如果 intent 需要打开 App 到指定 tab，新增一个轻量路由状态，例如 `AppRoute` 或 `AppNavigationTarget`，由 `AppRootView` 处理。

### Discoverability

新增 `AppShortcutsProvider`：

- “记录今天的一划”
- “打开一划”
- “查看情绪月历”

短语应自然、直接，适合 Siri / Shortcuts / Spotlight。

## 数据模型影响

`DayEntry` 需要新增或迁移字段：

- `confidence: Double`
- `analysisSourceRawValue: String`
- `explanation: String`

如果为了避免 SwiftData 迁移复杂度影响 demo，可提供默认值并确保旧记录读取正常。

已有字段继续保留：

- `date`
- `text`
- `emotionRawValue`
- `energy`
- `themeRawValue`
- `keywordsBlob`
- `glyphSeed`
- `createdAt`
- `updatedAt`
- `isDemo`

## 错误和回退

- Foundation Models 不可用：静默回退到本地增强规则，结果来源记录为 `localRules` 或 `fallback`。
- 结构化输出解析失败：回退到本地增强规则。
- intent 输入为空：返回清晰错误，不创建记录。
- SwiftData 保存失败：intent 返回失败说明，App UI 保留当前输入。
- 图标资源生成失败：构建前必须修复，不允许缺失 AppIcon PNG。

## 测试与验证

### 单元测试

新增或更新测试：

- 普通口语输入不会轻易返回“未知”。
- “很早搞完 / 终于搞定 / 脑子很乱 / 说不上来”等隐含表达能得到合理情绪或混合结果。
- 空文本仍保持不可分析。
- Foundation Models 不可用时统一分析服务能回退。
- `GlyphSignature` 在同输入下稳定。
- 高低能量影响密度或对比，但不产生失控线条数量。
- App Intents 类型能编译，核心参数定义正确。

### 构建验证

必须验证：

- iOS Simulator Debug 构建通过。
- 现有测试通过或明确记录不能运行的原因。
- 今日页生成记录成功。
- 月历缩略图清晰可识别。
- AppIcon 资源存在并被 Xcode 识别。
- 未开启 Apple Intelligence 的环境不影响 demo 使用。

## 实现边界

建议按以下顺序实现：

1. 扩展分析模型和增强本地规则，先解决“未知”问题。
2. 接入 Foundation Models 适配层，并保证不可用时回退。
3. 重写 Glyph 几何签名和 Canvas 渲染。
4. 生成并接入 AppIcon 资源。
5. 新增 App Intents 和 AppShortcutsProvider。
6. 更新 UI 展示置信度、解释和来源。
7. 补测试并构建验证。

## 验收标准

本次改造完成后，以下条件必须成立：

- 输入普通日常语句时，App 不再轻易显示“未知”。
- 输入含糊或口语化文本时，App 能给出可解释的情绪或混合判断。
- Glyph 在今日页、详情页和月历页都呈现有秩序的几何徽章，而不是随机乱线。
- AppIcon 资源完整，不再只有空 `Contents.json`。
- 代码中存在真实 Foundation Models 接入路径，并且不可用时能回退。
- 代码中存在真实 App Intents / App Shortcuts，暴露 DayGlyph 的核心动作。
- 构建通过，核心分析和 Glyph 测试通过。
