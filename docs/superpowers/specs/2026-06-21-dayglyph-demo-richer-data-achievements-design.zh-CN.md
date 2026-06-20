# DayGlyph 演示数据升级 + 成就系统扩展 设计文档

- 日期：2026-06-21
- 范围：演示数据用真实豆包 AI 出图并写死、历史详情页显示真图（修 bug）、成就系统扩展到 20+
- 关联：`docs/superpowers/specs/2026-06-20-dayglyph-doubao-ai-generation-design.zh-CN.md`、`产品文档.md`

## 1. 背景与目标

演示数据当前由 `DemoDataSeeder` 用 12 条手写简单样本（`source = .demoFixture`，手填 VAD）循环铺成 30 条，图片走 `EmotionVisualFactory` 程序化绘制，**不触发任何 AI 路径**。这与"我们已经接了豆包 AI"的事实脱节——演示时呈现的还是早期的简单情绪流图。

同时存在一个明确的 **bug**：即使一条记录有真实 `AIGenerationRecord` 真图（已入库、slot=.saved、文件落盘），历史详情页（`CocktailResultView` 的 `.history` 模式 → `CocktailHeroView`）也**只画程序化图形，从不读真图**。真图读取链路目前只存在于 `TodayHomeView` 的生成流程里。

成就系统当前只有 5 个（`MineAggregator.achievements`），全是累计达标型，演示张力不足。

本设计三个目标：

1. **演示数据升级**：用 8〜10 套多情绪交织的复杂 AI 样本替换旧演示数据，每套带真实豆包出的鸡尾酒+星球 JPEG，写死进 App bundle，离线、稳定、可复现。
2. **修真图显示 bug**：让历史详情页与宇宙星球视图在有 `AIGenerationRecord` 真图时优先显示真图，无图回退程序化绘制（既服务演示，也补全真实用户功能）。
3. **成就系统扩展**：扩到 21 个成就，加分类 + 四档稀有度。约 6 个接真实统计真触发（真解锁/真提示/真稀有度光效），约 15 个纯前端展示。

## 2. 非目标

- **不动"保存图片"按钮**。它现在弹假 toast（"保存图片会在下一阶段接入"），本次保持现状，单独立项。
- 不改 `DayGenerationOrchestrator` / `SeedTextClient` / `SeedImageClient` 的生产生成逻辑。
- 不引入连续签到、排行榜、断签惩罚等违反低压力约束的机制。
- 演示产物的生成是一次性本机操作，不进 CI。

## 3. 产物生成（实现阶段，本机一次性）

由实现者（Claude）在本机用 `curl` 直连火山方舟，使用用户已授权的 `AISecrets.arkAPIKey`：

1. 手写 8〜10 套复杂 `DayGenerationResponse`，结构对标 `DemoFallbackCatalog.richSample`：每套 5〜8 种情绪交织、完整 `emotionAnalysis` / `cocktail` / `planet` / 叙事 / 三档行动 / 分享卡。情绪基调覆盖不同光谱，例如：纯粹平静、欣慰交织疲惫、高涨兴奋、焦虑、愤怒、孤独回暖、困惑、感恩等。
2. 每套用其 `cocktail` / `planet` spec 构造 Seedream 图像 prompt，调用出两张真图 JPEG。
3. 产物落进新建工程目录 `DayGlyph/DemoAssets/`：

```
DemoAssets/
  demo-01/
    manifest.json     # 该套完整 DayGenerationResponse 的 JSON 编码
    cocktail.jpeg     # 真实豆包出图
    planet.jpeg       # 真实豆包出图
  demo-02/ ...
  ...（共 8〜10 套）
```

`manifest.json` 必须能通过现网同一套 `GenerationSchemaValidator.validate` 校验。这些文件作为 bundle 资源提交入库（真东西、写死）。

成本提示：约 8〜10 套文本 + 16〜20 张图，真实消耗用户 ARK Key 额度（已获授权）。

## 4. 演示数据入库管线（重写 DemoDataSeeder）

弃用现有 12 条 `.demoFixture` 简单样本与 `sample(...)` helper。新流程：

1. 列举 bundle 内 `DemoAssets/demo-*` 目录。
2. 每套：解码 `manifest.json` → `DayGenerationResponse`。
3. 用现成 `GenerationAnalysisMapper.makeAnalysis(from:)` 把复杂情绪投影成 `EmotionAnalysis`（VAD + 12 锚点权重）。**情绪分析此时是 AI 复杂度产物，不再是手写简单值。** `source` 沿用 `.demoFixture`。
4. `DayEntryStore.saveEntry(text:date:analysis:context:calendar:isDemo:true)` → 建 `DayEntry`，分配 entryID、算 seed、生成程序化视觉（作为兜底保留）。
5. 建 `AIGenerationRecord(entryID:)`：`setResponse(manifest)`，`status = .completed`（或现有表示完成的终态），`cocktailStatus = .saved`、`planetStatus = .saved`，`isDemoFallback = true`，写入 `textModelID` / `imageModelID`（取自 `AIConfiguration.demo`）。
6. 把 `DemoAssets/demo-NN/cocktail.jpeg`、`planet.jpeg` 通过 `GeneratedAssetStore.save(_:entryID:generationID:slot:)` 拷进 `{entryID}/{generationID}/` 路径。

日期分配：沿用现有"从今天往前铺、避开真实记录已占用日"逻辑。套数少于 30，因此每套占一天即可，不再循环复用。

`clearDemoEntries(in:)` 扩展：删 `DayEntry(isDemo==true)` 时，连带删除其 `AIGenerationRecord` 与 `GeneratedAssetStore` 图片目录（复用 `GenerationRepository.deleteAll(for:)` 或等价逻辑）。

### 模块边界

- `DemoAssetCatalog`（新，只读）：发现并解码 bundle 内 `DemoAssets/*`，返回 `[(response: DayGenerationResponse, cocktailURL: URL, planetURL: URL)]`。输入：bundle。输出：已校验样本列表。不依赖 SwiftData。
- `DemoDataSeeder`（重写）：消费 `DemoAssetCatalog`，编排 `DayEntryStore` / `GenerationRepository` / `GeneratedAssetStore` 写库。依赖 `ModelContext`。

## 5. 真图显示（修 bug，真图优先 + 程序化兜底）

### 5.1 新增只读组件 GeneratedImageProvider

给定 `entry`，查其最新 `AIGenerationRecord`（`GenerationRepository.latestRecord(for:)`），用 `GeneratedAssetStore.load(...)` 拿 cocktail/planet 的 `UIImage?`。任一缺失（无记录 / slot 非 .saved / 文件丢失）→ 对应返回 nil。

触发条件严格限定为"有 `AIGenerationRecord` 且 slot=.saved 且文件存在"，演示数据满足，真实老数据不满足 → 自动回退，零回归。

### 5.2 鸡尾酒侧

`CocktailHeroView` 增加可选入参 `generatedImage: UIImage?`：
- 有图 → 显示真图（圆角卡片，沿用现有视觉风格）。
- nil → 走现有 `cocktailVisual` 程序化绘制。

`CocktailResultView` 在 `.history` 模式下，从 `GeneratedImageProvider` 取 cocktail 真图传入 `CocktailHeroView`。`.today` 模式保持现状（其真图显示已在 `TodayHomeView` 流程中）。

### 5.3 星球侧

`UniversePlanetView` 增加可选 `generatedImage: UIImage?`，逻辑同上。`UniverseDaySummaryView` / `MonthlyPlanetDetailView` 用到该视图、且对应单条 entry 有真图时传入真图，否则程序化绘制。注意：月度聚合星球（多天合成）无单一 `AIGenerationRecord`，保持程序化绘制不变；仅单日 entry 详情走真图优先。

## 6. 成就系统扩展（纯前端工程，21 个）

### 6.1 数据模型扩展

`EmotionAchievement`（`MineModels.swift`）新增字段：

```swift
enum AchievementCategory: String { case record, explore, growth, connection, rareMoment }
enum AchievementRarity: String { case common, rare, epic, legendary }
enum AchievementKind { case live, showcase }

struct EmotionAchievement: Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var symbol: String
    var category: AchievementCategory
    var rarity: AchievementRarity
    var kind: AchievementKind
    var progress: Int
    var target: Int
    var isUnlocked: Bool {
        kind == .showcase ? showcaseUnlocked : progress >= target
    }
    var showcaseUnlocked: Bool   // .showcase 用预设解锁态
}
```

### 6.2 成就清单

**`.live`（约 6 个，接真实统计，演示真触发）** —— 复用 `MineAggregator` 已有的 days / anchors / completedActions / responses 统计：
- `first-planet` 第一颗星球（记录 1 天，common）
- `seven-days` 七日足迹（7 天，rare）
- `four-anchors` 完整体验者（4 锚点，rare）
- `small-steps` 小步收藏家（8 微行动，common）
- `echoes` 回声记录者（3 回声，common）
- `spectrum-five` 情绪光谱（覆盖 5 种锚点，epic）—— 新增，演示数据可满足

**`.showcase`（约 15 个，纯前端展示，不接统计）** —— 定义标题/描述/图标/分类/稀有度 + 预设解锁态：
满月轨迹（30 天）、百步旅人（100 微行动）、深夜记录者、四季轮转、最平静的一天（VAD 极值徽章）、最高涨的一天、全主题覆盖、连续记录里程碑、星海收藏家、回声共鸣者、晨光记录者、岁月寄信人、一年之约（legendary）等。预设解锁态混合（部分解锁演示视觉张力、部分锁定显示进度），稀有度拉满做视觉层次。

### 6.3 触发与提示（仅 .live）

进入「我的」或成就墙时，`MineAggregator` 算出当前已解锁的 `.live` 成就。用 `@AppStorage` 存"已弹过提示的成就 ID 集合"，对新解锁的弹一次解锁提示（卡片/toast 动画 + 稀有度光效），避免重复弹。`.showcase` 不参与触发，纯静态。

### 6.4 UI

`AchievementsView` 重做为成就墙：网格布局，按稀有度配色描边/光晕；已解锁高亮 + 稀有度光效，未解锁灰态 + 进度文案。按 category 分组或加筛选。`MineHomeView` 成就卡摘要数字更新为"已解锁 X/21"。

### 6.5 边界

`.showcase` 成就纯前端假数据，不写 SwiftData、不影响任何统计或聚合，演示与真实用户都只看到其展示态。`MineAggregator.achievements(...)` 输出的 `.live` 成就保持基于真实数据计算。

## 7. 测试与验证

- **演示数据管线**：单测验证种子后能查到 8〜10 条 `DayEntry(isDemo==true)`，每条有对应 `AIGenerationRecord`（双图 slot=.saved），图片文件真实落盘；`clearDemoEntries` 连带清掉记录与图片目录。
- **DemoAssetCatalog**：单测验证能解码 bundle 内 manifest 且通过 `GenerationSchemaValidator`。
- **真图优先逻辑**：单测 `GeneratedImageProvider`——有 saved 图返回 `UIImage`，无记录/文件丢失返回 nil。
- **成就系统**：`MineAggregator` 单测覆盖 `.live` 成就在演示数据下的解锁判定；`.showcase` 纯前端无需逻辑测试。
- **构建验证**：`xcodebuild build` 通过（新文件靠文件系统同步组自动编译）。
- 测试框架沿用 Swift Testing；带共享静态状态的测试用 `@Suite(.serialized)`。

## 8. 风险与缓解

- **API 调用花真钱**：已获用户授权，套数控制在 8〜10。
- **bundle 体积**：16〜20 张 JPEG，控制单图尺寸（Seedream 默认即可），可接受。
- **真图优先回归风险**：严格门控（有记录 + slot=.saved + 文件存在），默认回退程序化绘制，真实老数据不受影响。
- **月度聚合星球**：明确不走真图，避免多天合成与单图冲突。

## 9. 交付顺序（供实现计划参考）

1. 本机生成 8〜10 套产物，落 `DemoAssets/`。
2. `DemoAssetCatalog` + `DemoDataSeeder` 重写 + 入库管线 + clear 扩展。
3. `GeneratedImageProvider` + 鸡尾酒/星球真图优先显示（修 bug）。
4. 成就模型扩展 + 21 个清单 + `.live` 触发提示 + 成就墙 UI。
5. 测试 + 构建验证。
