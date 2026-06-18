# DayGlyph v2 基础架构与 Today 核心闭环 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 先完成 v2 四 Tab 应用壳和 Today “记录 -> 调制 -> 情绪鸡尾酒结果”的最小完整闭环。

**Architecture:** 保留现有 `UnifiedEmotionAnalyzer` 和 SwiftData 持久化入口，新增 v2 视觉派生模型，把分析结果稳定映射为情绪配方、鸡尾酒视觉、日星球和天气。UI 层拆成 Today 子页面和共享组件，旧 Glyph 代码暂时保留作兼容，但不再出现在主路径。

**Tech Stack:** SwiftUI、SwiftData、Swift Testing、Foundation Models 现有封装、SF Symbols、系统 Dynamic Type。

---

## 文件结构

新增文件：

- `DayGlyph/Models/EmotionVisuals.swift`：定义 `EmotionRecipe`、`CocktailVisual`、`PlanetVisual`、`MoodWeather`、`RecipePart`、`ConfidenceBand` 等可编码值类型。
- `DayGlyph/Services/EmotionVisualFactory.swift`：把 `EmotionAnalysis`、文本、日期和 seed 映射为稳定 v2 结果。
- `DayGlyph/Views/Today/TodayHomeView.swift`：Today 容器，负责 T-00/T-03 与模块顺序。
- `DayGlyph/Views/Today/EmotionRecordView.swift`：T-01 输入页。
- `DayGlyph/Views/Today/EmotionGeneratingView.swift`：T-02 生成页。
- `DayGlyph/Views/Today/CocktailResultView.swift`：T-03 结果页。
- `DayGlyph/Views/Today/CocktailHeroView.swift`：鸡尾酒 Hero 视觉组件。
- `DayGlyph/Views/Today/TodaySupportPlaceholders.swift`：T-04 至 T-07 的非业务占位卡，后续阶段替换。
- `DayGlyph/Views/App/UniversePlaceholderView.swift`：宇宙 Tab 暂不实现业务的占位页。
- `DayGlyph/Views/App/EchoPlaceholderView.swift`：回声 Tab 暂不实现业务的占位页。
- `DayGlyph/Views/App/MineHomePlaceholderView.swift`：我的 Tab 暂不实现业务的占位页，提供设置入口。
- `DayGlyphTests/EmotionVisualFactoryTests.swift`：v2 视觉映射和稳定性测试。
- `DayGlyphTests/DayEntryV2PersistenceTests.swift`：`DayEntry` v2 字段保存和更新测试。

修改文件：

- `DayGlyph/Views/AppRootView.swift`：替换为四 Tab，统一模块色。
- `DayGlyph/Views/DayGlyphStyle.swift`：迁移 v2 设计令牌，保留旧 token 的兼容别名直到旧 View 退出。
- `DayGlyph/Views/TodayView.swift`：只保留兼容或删除引用，主入口改用 `TodayHomeView`。
- `DayGlyph/Views/EntryDetailView.swift`：历史入口先渲染 `CocktailResultView` 的历史模式。
- `DayGlyph/Models/DayEntry.swift`：增加 v2 可编码字段和便捷访问器。
- `DayGlyph/Services/DayEntryStore.swift`：保存记录时生成 v2 视觉结果。
- `DayGlyph/Services/DemoDataSeeder.swift`：演示数据保存 v2 结果，文案不再引用一划。
- `DayGlyph.xcodeproj/project.pbxproj`：如 Xcode 未自动管理，需要加入新增 Swift 文件。

本阶段不修改：

- `DayGlyph/Glyph/*`：旧兼容代码暂不删除，避免扩大迁移风险。
- `DayGlyph/Views/CalendarView.swift`：阶段 3 再处理；本阶段不再作为一级 Tab 暴露。
- `ReminderService`：阶段 4 再扩展通知类型。

## Task 1: 增加 v2 视觉锚点与派生模型

**Files:**

- Create: `DayGlyph/Models/EmotionVisuals.swift`
- Create: `DayGlyph/Services/EmotionVisualFactory.swift`
- Test: `DayGlyphTests/EmotionVisualFactoryTests.swift`

- [ ] **Step 1: 写失败测试，验证同一输入稳定生成同一配方**

```swift
import Foundation
import Testing
@testable import DayGlyph

struct EmotionVisualFactoryTests {
    @Test func recipeIsStableForSameAnalysisDateAndText() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 17)))
        let analysis = EmotionAnalysis(
            valence: 0.62,
            arousal: 0.44,
            dominance: 0.32,
            emotionWeights: [
                EmotionWeight(anchor: .joy, value: 0.62),
                EmotionWeight(anchor: .calm, value: 0.28),
                EmotionWeight(anchor: .tired, value: 0.10)
            ],
            theme: .rest,
            keywords: ["散步", "安静"],
            confidence: 0.82,
            explanation: "轻松和安静更明显。",
            source: .localRules
        )

        let first = EmotionVisualFactory.makeVisuals(
            text: "傍晚散步后轻松了一点。",
            date: date,
            analysis: analysis,
            calendar: calendar
        )
        let second = EmotionVisualFactory.makeVisuals(
            text: "傍晚散步后轻松了一点。",
            date: date,
            analysis: analysis,
            calendar: calendar
        )

        #expect(first.recipe == second.recipe)
        #expect(first.cocktail == second.cocktail)
        #expect(first.planet == second.planet)
        #expect(first.weather == second.weather)
        #expect(first.recipe.primary == .joy)
        #expect(first.recipe.parts.reduce(0) { $0 + $1.parts } == 10)
        #expect(first.recipe.parts.count <= 3)
    }

    @Test func legacyEmotionAnchorsMapToProductVisualAnchors() {
        #expect(EmotionVisualAnchor.map(from: .hopeful) == .anticipation)
        #expect(EmotionVisualAnchor.map(from: .grateful) == .moved)
        #expect(EmotionVisualAnchor.map(from: .excited) == .proud)
        #expect(EmotionVisualAnchor.map(from: .relief) == .calm)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests/EmotionVisualFactoryTests test
```

Expected: FAIL，提示 `EmotionVisualFactory` 或 v2 模型不存在。

- [ ] **Step 3: 新增 `EmotionVisuals.swift`**

```swift
import Foundation

enum EmotionVisualAnchor: String, CaseIterable, Codable, Equatable, Hashable, Identifiable {
    case joy
    case calm
    case anticipation
    case moved
    case proud
    case tired
    case sad
    case anxious
    case angry
    case lonely
    case confused
    case numb

    var id: String { rawValue }

    var title: String {
        switch self {
        case .joy: "喜悦"
        case .calm: "平静"
        case .anticipation: "期待"
        case .moved: "感动"
        case .proud: "自豪"
        case .tired: "疲惫"
        case .sad: "难过"
        case .anxious: "焦虑"
        case .angry: "愤怒"
        case .lonely: "孤独"
        case .confused: "困惑"
        case .numb: "麻木"
        }
    }

    static func map(from anchor: EmotionAnchor) -> EmotionVisualAnchor {
        switch anchor {
        case .calm, .relief: .calm
        case .joy: .joy
        case .grateful: .moved
        case .hopeful: .anticipation
        case .excited: .proud
        case .angry: .angry
        case .anxious: .anxious
        case .sad: .sad
        case .tired: .tired
        case .lonely: .lonely
        case .confused: .confused
        }
    }
}

struct EntryVisuals: Codable, Equatable {
    var recipe: EmotionRecipe
    var cocktail: CocktailVisual
    var planet: PlanetVisual
    var weather: MoodWeather
    var visualVersion: Int
}

struct EmotionRecipe: Codable, Equatable {
    var primary: EmotionVisualAnchor
    var secondary: [EmotionVisualAnchor]
    var parts: [RecipePart]
    var keywords: [String]
    var confidenceBand: ConfidenceBand
    var name: String
    var supportCopy: String
}

struct RecipePart: Codable, Equatable, Identifiable {
    var anchor: EmotionVisualAnchor
    var parts: Int

    var id: EmotionVisualAnchor { anchor }
}

enum ConfidenceBand: String, Codable, Equatable {
    case low
    case medium
    case high
}

struct CocktailVisual: Codable, Equatable {
    var glassType: String
    var liquidLayers: [String]
    var bubbleLevel: Double
    var garnish: String
    var backgroundSeed: Int
}

struct PlanetVisual: Codable, Equatable {
    var seed: Int
    var baseHue: Double
    var secondaryHue: Double
    var textureComplexity: Double
    var glow: Double
    var rings: Int
    var satellites: Int
    var rotationSpeed: Double
}

struct MoodWeather: Codable, Equatable {
    var type: String
    var intensityBand: String
    var animationSeed: Int
    var explanation: String
}
```

- [ ] **Step 4: 新增 `EmotionVisualFactory.swift`**

```swift
import Foundation

enum EmotionVisualFactory {
    static func makeVisuals(
        text: String,
        date: Date,
        analysis: EmotionAnalysis,
        calendar: Calendar = .current
    ) -> EntryVisuals {
        let seed = stableSeed(text: text, date: date, calendar: calendar)
        let topWeights = analysis.topEmotionWeights
        let primary = EmotionVisualAnchor.map(from: topWeights.first?.anchor ?? .confused)
        let parts = recipeParts(from: topWeights)
        let secondary = parts.dropFirst().map(\.anchor)
        let keywords = Array((analysis.keywords + parts.map { $0.anchor.title }).uniqued().prefix(3))

        return EntryVisuals(
            recipe: EmotionRecipe(
                primary: primary,
                secondary: secondary,
                parts: parts,
                keywords: keywords,
                confidenceBand: confidenceBand(for: analysis.confidence),
                name: recipeName(for: primary, seed: seed),
                supportCopy: supportCopy(for: primary, confidence: analysis.confidence)
            ),
            cocktail: CocktailVisual(
                glassType: glassType(for: primary),
                liquidLayers: parts.map { colorToken(for: $0.anchor) },
                bubbleLevel: min(max(analysis.arousal, 0.08), 0.95),
                garnish: garnish(for: primary),
                backgroundSeed: seed
            ),
            planet: PlanetVisual(
                seed: seed,
                baseHue: hue(for: primary),
                secondaryHue: hue(for: secondary.first ?? primary),
                textureComplexity: min(max(analysis.emotionWeights.filter { $0.value > 0.08 }.count.doubleValue / 4.0, 0.20), 0.85),
                glow: min(max(analysis.arousal, 0.25), 0.90),
                rings: min(secondary.count, 3),
                satellites: min(max(analysis.keywords.count - 1, 0), 3),
                rotationSpeed: 0.02 + Double(seed % 11) / 100.0
            ),
            weather: MoodWeather(
                type: weatherType(for: primary),
                intensityBand: analysis.arousal > 0.66 ? "明显" : "柔和",
                animationSeed: seed,
                explanation: weatherExplanation(for: primary)
            ),
            visualVersion: 1
        )
    }

    private static func stableSeed(text: String, date: Date, calendar: Calendar) -> Int {
        let day = calendar.startOfDay(for: date).timeIntervalSince1970
        return abs("\(text)|\(Int(day))".hashValue)
    }

    private static func recipeParts(from weights: [EmotionWeight]) -> [RecipePart] {
        let selected = Array(weights.prefix(3))
        guard selected.isEmpty == false else { return [RecipePart(anchor: .confused, parts: 10)] }
        let raw = selected.map { max(1, Int(($0.value * 10).rounded())) }
        let total = raw.reduce(0, +)
        var adjusted = raw
        adjusted[0] += 10 - total
        return zip(selected, adjusted).map { RecipePart(anchor: EmotionVisualAnchor.map(from: $0.anchor), parts: max(1, $1)) }
    }

    private static func confidenceBand(for confidence: Double) -> ConfidenceBand {
        if confidence < 0.45 { return .low }
        if confidence < 0.75 { return .medium }
        return .high
    }

    private static func recipeName(for anchor: EmotionVisualAnchor, seed: Int) -> String {
        let suffixes = ["微光", "余响", "晨雾", "柔风"]
        return "\(anchor.title)\(suffixes[seed % suffixes.count])"
    }

    private static func supportCopy(for anchor: EmotionVisualAnchor, confidence: Double) -> String {
        if confidence < 0.45 { return "如果这份结果与你的感受不完全一致，可以把它当作一次温和的观察。" }
        return "它不是对你的定义，只是为今天留下的一种观察。"
    }

    private static func glassType(for anchor: EmotionVisualAnchor) -> String {
        switch anchor {
        case .calm, .tired, .sad, .lonely, .numb: "lowball"
        case .joy, .moved, .anticipation, .proud: "coupe"
        default: "highball"
        }
    }

    private static func colorToken(for anchor: EmotionVisualAnchor) -> String {
        switch anchor {
        case .joy: "#FF6D8F"
        case .calm: "#61C7B5"
        case .anticipation: "#7C69E8"
        case .moved: "#E678A7"
        case .proud: "#F49B43"
        case .tired: "#8E91B4"
        case .sad: "#5E76C9"
        case .anxious: "#8866D8"
        case .angry: "#E75C6C"
        case .lonely: "#536AAE"
        case .confused: "#6B8FA3"
        case .numb: "#7E858E"
        }
    }

    private static func hue(for anchor: EmotionVisualAnchor) -> Double {
        switch anchor {
        case .joy: 344
        case .calm: 171
        case .anticipation: 252
        case .moved: 329
        case .proud: 33
        case .tired: 232
        case .sad: 222
        case .anxious: 260
        case .angry: 352
        case .lonely: 226
        case .confused: 199
        case .numb: 210
        }
    }

    private static func garnish(for anchor: EmotionVisualAnchor) -> String {
        switch anchor {
        case .joy, .moved: "rose"
        case .calm: "mint"
        case .angry, .anxious: "citrus"
        default: "light"
        }
    }

    private static func weatherType(for anchor: EmotionVisualAnchor) -> String {
        switch anchor {
        case .joy, .moved, .proud: "晴光"
        case .calm: "微风"
        case .sad: "细雨"
        case .anxious: "阵雨"
        case .angry: "闷雷"
        case .lonely: "夜雾"
        case .tired: "阴天"
        case .numb: "无风阴天"
        case .anticipation: "晨曦"
        default: "薄雾"
        }
    }

    private static func weatherExplanation(for anchor: EmotionVisualAnchor) -> String {
        "\(anchor.title)在这份记录里更明显，所以今天的天气被写成一种轻量隐喻。"
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

private extension Int {
    var doubleValue: Double { Double(self) }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run:

```bash
xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests/EmotionVisualFactoryTests test
```

Expected: PASS。

- [ ] **Step 6: Commit**

```bash
git add DayGlyph/Models/EmotionVisuals.swift DayGlyph/Services/EmotionVisualFactory.swift DayGlyphTests/EmotionVisualFactoryTests.swift
git commit -m "feat: add v2 emotion visual models"
```

## Task 2: 持久化 v2 视觉结果

**Files:**

- Modify: `DayGlyph/Models/DayEntry.swift`
- Modify: `DayGlyph/Services/DayEntryStore.swift`
- Modify: `DayGlyph/Services/DemoDataSeeder.swift`
- Test: `DayGlyphTests/DayEntryV2PersistenceTests.swift`

- [ ] **Step 1: 写失败测试，验证保存和更新都会写入 v2 视觉数据**

```swift
import Foundation
import SwiftData
import Testing
@testable import DayGlyph

struct DayEntryV2PersistenceTests {
    @Test func saveEntryStoresV2Visuals() throws {
        let container = try ModelContainer(
            for: DayEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 17)))
        let analysis = EmotionAnalysis(
            valence: 0.48,
            arousal: 0.36,
            dominance: 0.28,
            emotionWeights: [
                EmotionWeight(anchor: .calm, value: 0.7),
                EmotionWeight(anchor: .joy, value: 0.3)
            ],
            theme: .rest,
            keywords: ["散步"],
            confidence: 0.8,
            explanation: "平静更明显。",
            source: .localRules
        )

        let entry = try DayEntryStore.saveEntry(
            text: "今天傍晚散步，心里安静了一些。",
            date: date,
            analysis: analysis,
            context: context,
            calendar: calendar
        )

        #expect(entry.visualVersion == 1)
        #expect(entry.emotionRecipe.primary == .calm)
        #expect(entry.emotionRecipe.parts.reduce(0) { $0 + $1.parts } == 10)
        #expect(entry.cocktailVisual.liquidLayers.isEmpty == false)
        #expect(entry.planetVisual.seed > 0)
        #expect(entry.moodWeather.type == "微风")
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests/DayEntryV2PersistenceTests test
```

Expected: FAIL，提示 v2 字段不存在。

- [ ] **Step 3: 扩展 `DayEntry`**

在 `DayEntry` 中新增字段：

```swift
var emotionRecipeData: Data = Data()
var cocktailVisualData: Data = Data()
var planetVisualData: Data = Data()
var moodWeatherData: Data = Data()
var visualVersion: Int = 0
var isFavorite: Bool = false
```

新增访问器：

```swift
var emotionRecipe: EmotionRecipe {
    decode(EmotionRecipe.self, from: emotionRecipeData)
        ?? EmotionVisualFactory.makeVisuals(text: text, date: date, analysis: analysis).recipe
}

var cocktailVisual: CocktailVisual {
    decode(CocktailVisual.self, from: cocktailVisualData)
        ?? EmotionVisualFactory.makeVisuals(text: text, date: date, analysis: analysis).cocktail
}

var planetVisual: PlanetVisual {
    decode(PlanetVisual.self, from: planetVisualData)
        ?? EmotionVisualFactory.makeVisuals(text: text, date: date, analysis: analysis).planet
}

var moodWeather: MoodWeather {
    decode(MoodWeather.self, from: moodWeatherData)
        ?? EmotionVisualFactory.makeVisuals(text: text, date: date, analysis: analysis).weather
}

func applyVisuals(_ visuals: EntryVisuals) {
    emotionRecipeData = encode(visuals.recipe)
    cocktailVisualData = encode(visuals.cocktail)
    planetVisualData = encode(visuals.planet)
    moodWeatherData = encode(visuals.weather)
    visualVersion = visuals.visualVersion
}

private func encode<T: Encodable>(_ value: T) -> Data {
    (try? JSONEncoder().encode(value)) ?? Data()
}

private func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
    guard data.isEmpty == false else { return nil }
    return try? JSONDecoder().decode(type, from: data)
}
```

在初始化和 `update` 中调用：

```swift
let visuals = EmotionVisualFactory.makeVisuals(text: text, date: self.date, analysis: analysis)
applyVisuals(visuals)
```

- [ ] **Step 4: 更新 `DayEntryStore` 保存路径**

保持现有 `saveEntry` 签名不变。确认新建和更新都通过 `DayEntry.init` 或 `update` 触发 `applyVisuals`。不要在 View 层手动生成并保存 v2 数据。

- [ ] **Step 5: 更新演示数据文案**

在 `DemoDataSeeder` 中把旧解释从“轨迹、边界、节律”等 Glyph 语义改成鸡尾酒/星球可共用语义，例如：

```swift
explanation: "今天的平静像柔和底色，轻轻托住了这一段记录。"
```

- [ ] **Step 6: 运行持久化测试**

Run:

```bash
xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests/DayEntryV2PersistenceTests test
```

Expected: PASS。

- [ ] **Step 7: 运行现有 DayEntry 测试，确认兼容**

Run:

```bash
xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests/DayEntryStoreTests test
```

Expected: PASS。

- [ ] **Step 8: Commit**

```bash
git add DayGlyph/Models/DayEntry.swift DayGlyph/Services/DayEntryStore.swift DayGlyph/Services/DemoDataSeeder.swift DayGlyphTests/DayEntryV2PersistenceTests.swift
git commit -m "feat: persist v2 entry visuals"
```

## Task 3: 迁移 v2 设计令牌与四 Tab 应用壳

**Files:**

- Modify: `DayGlyph/Views/DayGlyphStyle.swift`
- Modify: `DayGlyph/Views/AppRootView.swift`
- Create: `DayGlyph/Views/App/UniversePlaceholderView.swift`
- Create: `DayGlyph/Views/App/EchoPlaceholderView.swift`
- Create: `DayGlyph/Views/App/MineHomePlaceholderView.swift`

- [ ] **Step 1: 更新 `DayGlyphStyle` token**

新增 v2 token，旧 token 暂保留为兼容别名：

```swift
static let canvas = Color(red: 1.0, green: 0.973, blue: 0.980)
static let surface = Color.white
static let surfaceSoft = Color(red: 1.0, green: 0.898, blue: 0.929)
static let textPrimary = Color(red: 0.129, green: 0.106, blue: 0.141)
static let textSecondary = Color(red: 0.506, green: 0.467, blue: 0.518)
static let divider = Color(red: 0.933, green: 0.875, blue: 0.898)
static let today = Color(red: 1.0, green: 0.365, blue: 0.514)
static let universe = Color(red: 0.463, green: 0.341, blue: 0.784)
static let universeBackground = Color(red: 0.094, green: 0.098, blue: 0.184)
static let echo = Color(red: 1.0, green: 0.604, blue: 0.263)
static let mine = Color(red: 0.357, green: 0.498, blue: 0.886)
static let danger = Color(red: 0.906, green: 0.361, blue: 0.424)
```

保留：

```swift
static let ink = textPrimary
static let mutedInk = textSecondary
static let paper = canvas
static let jade = today
static let amber = echo
```

- [ ] **Step 2: 创建三个占位 Tab**

`UniversePlaceholderView` 要显示深色宇宙空状态，但只做入口说明，不实现交互星球。

`EchoPlaceholderView` 要显示“完成一个小行动后，这里会留下回声”，不推荐任务。

`MineHomePlaceholderView` 要提供本地设置入口，临时复用 `SettingsView` 的 NavigationLink。

- [ ] **Step 3: 修改 `AppRootView` 为四 Tab**

```swift
struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayHomeView()
            }
            .tabItem {
                Label("今日", systemImage: "house.fill")
            }

            NavigationStack {
                UniversePlaceholderView()
            }
            .tabItem {
                Label("宇宙", systemImage: "sparkles")
            }

            NavigationStack {
                EchoPlaceholderView()
            }
            .tabItem {
                Label("回声", systemImage: "dot.radiowaves.left.and.right")
            }

            NavigationStack {
                MineHomePlaceholderView()
            }
            .tabItem {
                Label("我的", systemImage: "person.crop.circle")
            }
        }
        .tint(DayGlyphStyle.today)
        .environment(\.locale, Locale(identifier: "zh_CN"))
    }
}
```

- [ ] **Step 4: 编译验证**

Run:

```bash
xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests test
```

Expected: PASS 或仅失败于 `TodayHomeView` 尚未创建。若后者失败，继续 Task 4 后再回跑。

- [ ] **Step 5: Commit**

```bash
git add DayGlyph/Views/DayGlyphStyle.swift DayGlyph/Views/AppRootView.swift DayGlyph/Views/App/UniversePlaceholderView.swift DayGlyph/Views/App/EchoPlaceholderView.swift DayGlyph/Views/App/MineHomePlaceholderView.swift
git commit -m "feat: add v2 tab shell"
```

## Task 4: 实现 Today T-00/T-01/T-02/T-03 核心页面

**Files:**

- Create: `DayGlyph/Views/Today/TodayHomeView.swift`
- Create: `DayGlyph/Views/Today/EmotionRecordView.swift`
- Create: `DayGlyph/Views/Today/EmotionGeneratingView.swift`
- Create: `DayGlyph/Views/Today/CocktailResultView.swift`
- Create: `DayGlyph/Views/Today/CocktailHeroView.swift`
- Create: `DayGlyph/Views/Today/TodaySupportPlaceholders.swift`
- Modify: `DayGlyph/Views/EntryDetailView.swift`

- [ ] **Step 1: 创建 `TodayHomeView` 状态结构**

实现状态：

```swift
enum TodayRoute: Hashable {
    case record
    case generating(String)
}
```

`TodayHomeView` 查询当日 `DayEntry`：

- 无今日记录：显示 T-00 空状态，主按钮 push T-01。
- 有今日记录：显示 T-03 结果和 T-04 至 T-07 占位卡。
- `NavigationDestination` 处理 T-01 和 T-02。

- [ ] **Step 2: 创建 T-01 输入页**

要求：

- 标题：“今天发生了什么？可以只写一句”
- `TextEditor` 最小高度 240 pt。
- 500 字上限提示。
- 非空后按钮“调制今日情绪”可点击。
- 取消时有输入则弹出保存草稿确认，本阶段草稿只保留内存状态。

- [ ] **Step 3: 创建 T-02 生成页**

要求：

- 三阶段文案：`理解文字`、`调制颜色`、`凝结星球`。
- 不显示精确百分比。
- 减少动态时用静态阶段切换。
- 成功后保存 `DayEntry` 并返回 Today 展示 T-03。
- 分析不可用时使用现有 `UnifiedEmotionAnalyzer` 的 fallback，不在 UI 中显示模型品牌。

- [ ] **Step 4: 创建 T-03 鸡尾酒结果**

要求：

- 标题根据 `entry.emotionRecipe.confidenceBand` 决定：低置信度使用“今天可能由这些感受组成”，否则使用“今日情绪鸡尾酒”。
- Hero 展示 `entry.emotionRecipe.name`、日期、最多 3 个关键词和 `CocktailHeroView`。
- 配方详情用“份”，不在首屏使用“严重程度”语言。
- 显示 `MoodWeather` 一句话卡片。
- 主按钮：“收藏配方”或“已收藏”。
- 次按钮：“保存图片”，本阶段可显示 Toast 占位，不调用系统分享。

- [ ] **Step 5: 创建 Today 支持模块占位卡**

占位卡只显示结构和后续文案，不实现业务：

- T-04：“今天的天气”
- T-05：“今天迈一小步”
- T-06：“时间来信”
- T-07：“共情海”

每张卡只能有一个次级入口按钮，按钮文案使用“下一阶段接入”，避免用户误以为已完成。

- [ ] **Step 6: 历史详情临时迁移到鸡尾酒结果**

修改 `EntryDetailView`，让其优先渲染 `CocktailResultView(entry: entry, mode: .history)`。旧 Glyph 详情可暂时通过内部 debug 折叠保留，但普通用户路径不得出现“一划”。

- [ ] **Step 7: 编译并运行 Today 相关测试**

Run:

```bash
xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests test
```

Expected: PASS。

- [ ] **Step 8: 人工走查**

在 iPhone 17 模拟器走查：

- 首次打开看到四 Tab。
- 今日空状态主按钮首屏可见。
- 输入一句话后按钮从 disabled 变 active。
- 点击“调制今日情绪”出现三阶段生成。
- 生成后 Today 展示鸡尾酒结果，不出现 Glyph 或“一划”。
- 关闭减少动态后生成页仍可理解。

- [ ] **Step 9: Commit**

```bash
git add DayGlyph/Views/Today DayGlyph/Views/EntryDetailView.swift
git commit -m "feat: implement today cocktail core flow"
```

## Task 5: 清理用户可见旧术语并回归测试

**Files:**

- Modify: `README.md`
- Modify: any Swift file found by search for visible old strings

- [ ] **Step 1: 搜索旧术语**

Run:

```bash
rg -n "一划|Glyph|月历|生成今日|情绪印记|情绪星图" DayGlyph README.md
```

Expected: 只允许工程名、兼容代码、README 历史说明或非用户可见注释保留；用户可见 SwiftUI 文案必须替换。

- [ ] **Step 2: 替换用户可见文案**

替换原则：

- “生成今日一划” -> “调制今日情绪”
- “情绪印记” -> “情绪鸡尾酒”或“星球”
- “月历”一级入口 -> “宇宙”
- “设置”一级入口 -> “我的”
- “Glyph” 用户可见说明 -> 移除或改为 v2 术语

- [ ] **Step 3: 跑完整单元测试**

Run:

```bash
xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests test
```

Expected: PASS。

- [ ] **Step 4: 设计验收检查**

检查项：

- [ ] 四 Tab：今日、宇宙、回声、我的。
- [ ] Today 页面基准横向边距 20 pt。
- [ ] 主按钮高度 52 pt，命中区至少 44 pt。
- [ ] 主结果为鸡尾酒，不出现 Glyph 主视觉。
- [ ] 配方使用“份”，不把百分比当严重程度展示。
- [ ] 所有失败状态保留用户输入。
- [ ] 支持 Dynamic Type，双按钮在大字号下可纵向排列。

- [ ] **Step 5: Commit**

```bash
git add README.md DayGlyph
git commit -m "chore: remove visible legacy glyph wording"
```

## 阶段完成标准

- [ ] `DayGlyphTests` 全部通过。
- [ ] 主路径可在模拟器完成一次记录并看到鸡尾酒结果。
- [ ] 宇宙、回声、我的作为四 Tab 可进入，但明确属于后续阶段，不展示死入口。
- [ ] `docs/superpowers/plans/2026-06-17-dayglyph-v2-sequential-roadmap.zh-CN.md` 中阶段 1 交付标准全部满足。
- [ ] 用户审阅并确认后，才进入阶段 2 计划编写。
