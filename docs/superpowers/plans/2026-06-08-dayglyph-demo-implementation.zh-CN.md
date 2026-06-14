# DayGlyph 演示实现计划

> **给 Agent 工作者：** 必需子技能：使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans`，按任务逐步实现本计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 构建一个完整的本地优先 DayGlyph iOS 演示应用：可以输入轻量级日记条目，分析情绪/主题，生成确定性的 Canvas 符文，保存记录，展示符文月历，管理提醒，并填充演示数据。

**架构：** 用一个以 `DayEntry` 为中心的小型领域模型替换模板中的 SwiftData `Item` 流程。将纯逻辑保留在可测试的 Swift 文件中（`EmotionAnalyzer`、`GlyphSignature`、日历辅助工具），用 SwiftUI `Canvas` 渲染符文，并将全局 UI 放在包含“今日、月历、设置”标签页的 `TabView` 中。Foundation Models 在分析器内部保留为未来扩展接口；演示版使用稳定的本地规则交付。

**技术栈：** SwiftUI、SwiftData、Swift Testing、UserNotifications、SwiftUI Canvas、Xcode 26 文件系统同步分组。

---

## 文件结构

- 修改 `DayGlyph/DayGlyphApp.swift`：在 SwiftData schema 中注册 `DayEntry`，并启动 `AppRootView`。
- 删除 `DayGlyph/Item.swift`：替换后移除模板模型。
- 替换 `DayGlyph/ContentView.swift`：保留为一个轻量兼容包装器，或替换为 `AppRootView`。
- 创建 `DayGlyph/Models/DayEntry.swift`：SwiftData 模型和计算辅助属性。
- 创建 `DayGlyph/Models/Emotion.swift`：情绪/主题枚举和 `EmotionAnalysis`。
- 创建 `DayGlyph/Services/EmotionAnalyzer.swift`：确定性的本地文本分析。
- 创建 `DayGlyph/Services/DemoDataSeeder.swift`：填充和清理演示记录。
- 创建 `DayGlyph/Services/ReminderService.swift`：通知权限和调度。
- 创建 `DayGlyph/Glyph/GlyphSignature.swift`：从每日记录派生视觉参数。
- 创建 `DayGlyph/Glyph/SeededRandom.swift`：稳定的确定性随机数生成器。
- 创建 `DayGlyph/Glyph/GlyphCanvasView.swift`：SwiftUI Canvas 渲染器。
- 创建 `DayGlyph/Utilities/CalendarMonth.swift`：月份网格/日期辅助工具。
- 创建 `DayGlyph/Views/AppRootView.swift`：`TabView` 外壳。
- 创建 `DayGlyph/Views/TodayView.swift`：输入、生成和今日结果。
- 创建 `DayGlyph/Views/CalendarView.swift`：月份符文网格。
- 创建 `DayGlyph/Views/EntryDetailView.swift`：详情和删除流程。
- 创建 `DayGlyph/Views/SettingsView.swift`：提醒和演示数据操作。
- 创建 `DayGlyph/Views/DayGlyphStyle.swift`：共享颜色、间距和标签。
- 修改 `DayGlyphTests/DayGlyphTests.swift`：移除模板占位测试。
- 创建 `DayGlyphTests/EmotionAnalyzerTests.swift`：分析器覆盖测试。
- 创建 `DayGlyphTests/GlyphSignatureTests.swift`：确定性符文覆盖测试。
- 创建 `DayGlyphTests/CalendarMonthTests.swift`：月份网格覆盖测试。

该项目已经使用 `PBXFileSystemSynchronizedRootGroup`，因此 `DayGlyph/` 和 `DayGlyphTests/` 下的文件会自动被 应用/测试 target 识别，无需手动编辑 `DayGlyph.xcodeproj/project.pbxproj`。

---

### 任务 1：领域模型和 App 接线

**文件：**
- 创建：`DayGlyph/Models/Emotion.swift`
- 创建：`DayGlyph/Models/DayEntry.swift`
- 修改：`DayGlyph/DayGlyphApp.swift`
- 修改：`DayGlyph/ContentView.swift`
- 删除：`DayGlyph/Item.swift`

- [ ] **步骤 1：创建情绪和分析类型**

添加 `DayGlyph/Models/Emotion.swift`：

```swift
import Foundation
import SwiftUI

enum DayEmotion: String, CaseIterable, Codable, Identifiable {
    case calm
    case joy
    case low
    case anxious
    case excited
    case tired
    case grateful
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: "平静"
        case .joy: "喜悦"
        case .low: "低落"
        case .anxious: "焦虑"
        case .excited: "激动"
        case .tired: "疲惫"
        case .grateful: "感恩"
        case .mixed: "混合"
        }
    }
}

enum DayTheme: String, CaseIterable, Codable, Identifiable {
    case work
    case relationship
    case growth
    case rest
    case family
    case health
    case creativity
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: "工作"
        case .relationship: "关系"
        case .growth: "成长"
        case .rest: "休息"
        case .family: "家庭"
        case .health: "健康"
        case .creativity: "创造"
        case .unknown: "未知"
        }
    }
}

struct EmotionAnalysis: Equatable {
    var emotion: DayEmotion
    var theme: DayTheme
    var energy: Double
    var keywords: [String]
}
```

- [ ] **步骤 2：创建 SwiftData 记录模型**

添加 `DayGlyph/Models/DayEntry.swift`：

```swift
import Foundation
import SwiftData

@Model
final class DayEntry {
    var date: Date
    var text: String
    var emotionRawValue: String
    var energy: Double
    var themeRawValue: String
    var keywordsBlob: String
    var glyphSeed: Int
    var createdAt: Date
    var updatedAt: Date
    var isDemo: Bool

    init(
        date: Date,
        text: String,
        emotion: DayEmotion,
        energy: Double,
        theme: DayTheme,
        keywords: [String],
        glyphSeed: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isDemo: Bool = false
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.text = text
        self.emotionRawValue = emotion.rawValue
        self.energy = min(max(energy, 0), 1)
        self.themeRawValue = theme.rawValue
        self.keywordsBlob = keywords.joined(separator: "|")
        self.glyphSeed = glyphSeed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDemo = isDemo
    }

    var emotion: DayEmotion {
        DayEmotion(rawValue: emotionRawValue) ?? .mixed
    }

    var theme: DayTheme {
        DayTheme(rawValue: themeRawValue) ?? .unknown
    }

    var keywords: [String] {
        keywordsBlob
            .split(separator: "|")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    func update(text: String, analysis: EmotionAnalysis, glyphSeed: Int, date: Date = .now) {
        self.text = text
        self.emotionRawValue = analysis.emotion.rawValue
        self.energy = min(max(analysis.energy, 0), 1)
        self.themeRawValue = analysis.theme.rawValue
        self.keywordsBlob = analysis.keywords.joined(separator: "|")
        self.glyphSeed = glyphSeed
        self.updatedAt = date
    }
}
```

- [ ] **步骤 3：将 SwiftData 接到 `DayEntry`**

修改 `DayGlyph/DayGlyphApp.swift`，让 schema 包含 `DayEntry.self`，并将根视图设为 `AppRootView()`：

```swift
import SwiftUI
import SwiftData

@main
struct DayGlyphApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DayEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

- [ ] **步骤 4：用包装器替换模板内容**

替换 `DayGlyph/ContentView.swift`：

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        AppRootView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
```

- [ ] **步骤 5：删除模板模型**

删除 `DayGlyph/Item.swift`。

- [ ] **步骤 6：提交领域模型接线**

运行：

```bash
git add DayGlyph/Models/Emotion.swift DayGlyph/Models/DayEntry.swift DayGlyph/DayGlyphApp.swift DayGlyph/ContentView.swift
git rm DayGlyph/Item.swift
git commit -m "Replace template model with day entries"
```

预期：提交成功，并且只包含模型/app 接线相关文件。

---

### 任务 2：带测试的情绪分析器

**文件：**
- 创建：`DayGlyph/Services/EmotionAnalyzer.swift`
- 修改：`DayGlyphTests/DayGlyphTests.swift`
- 创建：`DayGlyphTests/EmotionAnalyzerTests.swift`

- [ ] **步骤 1：清空模板测试文件**

替换 `DayGlyphTests/DayGlyphTests.swift`：

```swift
import Testing
@testable import DayGlyph

struct DayGlyphTests {
    @Test func projectLoads() {
        #expect(DayEmotion.calm.title == "平静")
    }
}
```

- [ ] **步骤 2：编写分析器测试**

添加 `DayGlyphTests/EmotionAnalyzerTests.swift`：

```swift
import Testing
@testable import DayGlyph

struct EmotionAnalyzerTests {
    @Test func detectsGratefulWorkEntry() {
        let result = EmotionAnalyzer().analyze("今天终于完成了项目，特别感谢同事帮我一起收尾。")

        #expect(result.emotion == .grateful)
        #expect(result.theme == .work)
        #expect(result.energy >= 0.45)
        #expect(result.keywords.contains("项目") || result.keywords.contains("感谢"))
    }

    @Test func detectsTiredLowEnergyEntry() {
        let result = EmotionAnalyzer().analyze("今天很累，睡得不好，什么都提不起劲。")

        #expect(result.emotion == .tired)
        #expect(result.theme == .rest)
        #expect(result.energy < 0.5)
    }

    @Test func emptyTextFallsBackToMixedUnknown() {
        let result = EmotionAnalyzer().analyze("   ")

        #expect(result.emotion == .mixed)
        #expect(result.theme == .unknown)
        #expect(result.energy == 0.3)
        #expect(result.keywords.isEmpty)
    }
}
```

- [ ] **步骤 3：运行测试以验证失败**

运行：

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

预期：失败，因为 `EmotionAnalyzer` 还不存在。如果该模拟器名称不可用，运行 `xcrun simctl list devices available`，并使用最新可用的 iPhone 模拟器。

- [ ] **步骤 4：实现分析器**

添加 `DayGlyph/Services/EmotionAnalyzer.swift`：

```swift
import Foundation

struct EmotionAnalyzer {
    func analyze(_ text: String) -> EmotionAnalysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return EmotionAnalysis(emotion: .mixed, theme: .unknown, energy: 0.3, keywords: [])
        }

        let lowercased = trimmed.lowercased()
        let emotion = strongestEmotion(in: lowercased)
        let theme = strongestTheme(in: lowercased)
        let energy = energyScore(in: trimmed, emotion: emotion)
        let keywords = extractKeywords(from: trimmed, theme: theme, emotion: emotion)

        return EmotionAnalysis(emotion: emotion, theme: theme, energy: energy, keywords: keywords)
    }

    private func strongestEmotion(in text: String) -> DayEmotion {
        let table: [(DayEmotion, [String])] = [
            (.grateful, ["感谢", "感恩", "谢谢", "幸运", "珍惜", "grateful", "thanks"]),
            (.joy, ["开心", "快乐", "高兴", "满足", "好棒", "喜欢", "joy", "happy"]),
            (.tired, ["累", "疲惫", "困", "睡不好", "提不起劲", "tired", "exhausted"]),
            (.anxious, ["焦虑", "担心", "紧张", "害怕", "压力", "anxious", "worried"]),
            (.low, ["难过", "低落", "沮丧", "失望", "孤独", "sad", "down"]),
            (.excited, ["激动", "兴奋", "冲刺", "突破", "终于", "excited", "thrilled"]),
            (.calm, ["平静", "安静", "放松", "散步", "呼吸", "calm", "peace"])
        ]

        var best: (emotion: DayEmotion, score: Int) = (.mixed, 0)
        for row in table {
            let score = row.1.reduce(0) { partial, keyword in
                partial + (text.contains(keyword) ? 1 : 0)
            }
            if score > best.score {
                best = (row.0, score)
            }
        }
        return best.score == 0 ? .mixed : best.emotion
    }

    private func strongestTheme(in text: String) -> DayTheme {
        let table: [(DayTheme, [String])] = [
            (.work, ["工作", "项目", "会议", "客户", "同事", "deadline", "work"]),
            (.relationship, ["朋友", "伴侣", "关系", "聊天", "沟通", "friend", "love"]),
            (.growth, ["学习", "成长", "复盘", "进步", "读书", "learn"]),
            (.rest, ["休息", "睡", "散步", "放空", "累", "rest", "sleep"]),
            (.family, ["家", "父母", "孩子", "妈妈", "爸爸", "family"]),
            (.health, ["身体", "运动", "跑步", "健康", "病", "health"]),
            (.creativity, ["画", "写", "设计", "创作", "灵感", "create"])
        ]

        var best: (theme: DayTheme, score: Int) = (.unknown, 0)
        for row in table {
            let score = row.1.reduce(0) { partial, keyword in
                partial + (text.contains(keyword) ? 1 : 0)
            }
            if score > best.score {
                best = (row.0, score)
            }
        }
        return best.score == 0 ? .unknown : best.theme
    }

    private func energyScore(in text: String, emotion: DayEmotion) -> Double {
        var score: Double = switch emotion {
        case .excited: 0.78
        case .joy, .grateful: 0.62
        case .anxious: 0.68
        case .calm: 0.38
        case .low, .tired: 0.28
        case .mixed: 0.46
        }

        score += Double(text.filter { $0 == "!" || $0 == "！" }.count) * 0.06
        score += min(Double(text.count) / 500.0, 0.12)
        return min(max(score, 0), 1)
    }

    private func extractKeywords(from text: String, theme: DayTheme, emotion: DayEmotion) -> [String] {
        let candidates = [
            theme.title,
            emotion.title,
            "项目", "感谢", "休息", "朋友", "学习", "家人", "运动", "创作", "完成", "压力"
        ]

        var result: [String] = []
        for candidate in candidates where text.contains(candidate) && !result.contains(candidate) {
            result.append(candidate)
            if result.count == 4 { break }
        }

        if result.isEmpty {
            result.append(theme == .unknown ? emotion.title : theme.title)
        }
        return Array(result.prefix(4))
    }
}
```

- [ ] **步骤 5：运行分析器测试**

运行：

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/EmotionAnalyzerTests
```

预期：分析器测试通过。

- [ ] **步骤 6：提交分析器**

运行：

```bash
git add DayGlyph/Services/EmotionAnalyzer.swift DayGlyphTests/DayGlyphTests.swift DayGlyphTests/EmotionAnalyzerTests.swift
git commit -m "Add local emotion analyzer"
```

---

### 任务 3：带测试的确定性符文签名

**文件：**
- 创建：`DayGlyph/Glyph/SeededRandom.swift`
- 创建：`DayGlyph/Glyph/GlyphSignature.swift`
- 创建：`DayGlyphTests/GlyphSignatureTests.swift`

- [ ] **步骤 1：编写符文测试**

添加 `DayGlyphTests/GlyphSignatureTests.swift`：

```swift
import Testing
@testable import DayGlyph

struct GlyphSignatureTests {
    @Test func sameInputsProduceSameSeed() {
        let first = GlyphSignature.seed(for: "今天很平静", date: .init(timeIntervalSince1970: 1_780_876_800))
        let second = GlyphSignature.seed(for: "今天很平静", date: .init(timeIntervalSince1970: 1_780_876_800))

        #expect(first == second)
    }

    @Test func signatureUsesEmotionAndEnergy() {
        let analysis = EmotionAnalysis(emotion: .excited, theme: .work, energy: 0.9, keywords: ["项目"])
        let signature = GlyphSignature(analysis: analysis, seed: 42)

        #expect(signature.emotion == .excited)
        #expect(signature.strokeCount >= 10)
        #expect(signature.motif == .radiant)
    }
}
```

- [ ] **步骤 2：运行测试以验证失败**

运行：

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/GlyphSignatureTests
```

预期：失败，因为 `GlyphSignature` 还不存在。

- [ ] **步骤 3：添加确定性随机数**

添加 `DayGlyph/Glyph/SeededRandom.swift`：

```swift
import Foundation

struct SeededRandom {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(bitPattern: Int64(seed == 0 ? 0x9E3779B9 : seed))
    }

    mutating func next() -> Double {
        state = 2862933555777941757 &* state &+ 3037000493
        return Double(state % 10_000) / 10_000.0
    }
}
```

- [ ] **步骤 4：添加符文签名**

添加 `DayGlyph/Glyph/GlyphSignature.swift`：

```swift
import Foundation
import SwiftUI

enum GlyphMotif: String {
    case arcs
    case radiant
    case folded
    case dotted
    case wave
    case hybrid
}

struct GlyphSignature: Equatable {
    var emotion: DayEmotion
    var theme: DayTheme
    var energy: Double
    var seed: Int
    var motif: GlyphMotif
    var strokeCount: Int
    var rotation: Double

    init(analysis: EmotionAnalysis, seed: Int) {
        self.emotion = analysis.emotion
        self.theme = analysis.theme
        self.energy = min(max(analysis.energy, 0), 1)
        self.seed = seed
        self.motif = Self.motif(for: analysis.emotion)
        self.strokeCount = 5 + Int((min(max(analysis.energy, 0), 1) * 9).rounded())
        self.rotation = Double(abs(seed % 360))
    }

    static func seed(for text: String, date: Date, calendar: Calendar = .current) -> Int {
        let day = calendar.startOfDay(for: date).timeIntervalSince1970
        var hash = 5381
        for scalar in text.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        hash = hash &+ Int(day)
        return abs(hash)
    }

    static func motif(for emotion: DayEmotion) -> GlyphMotif {
        switch emotion {
        case .calm: .arcs
        case .joy: .wave
        case .low: .dotted
        case .anxious: .folded
        case .excited: .radiant
        case .tired: .dotted
        case .grateful: .arcs
        case .mixed: .hybrid
        }
    }

    var primaryColor: Color {
        switch emotion {
        case .calm: Color(red: 0.24, green: 0.58, blue: 0.52)
        case .joy: Color(red: 0.89, green: 0.66, blue: 0.24)
        case .low: Color(red: 0.38, green: 0.49, blue: 0.64)
        case .anxious: Color(red: 0.43, green: 0.42, blue: 0.72)
        case .excited: Color(red: 0.78, green: 0.31, blue: 0.29)
        case .tired: Color(red: 0.53, green: 0.49, blue: 0.43)
        case .grateful: Color(red: 0.82, green: 0.51, blue: 0.24)
        case .mixed: Color(red: 0.28, green: 0.48, blue: 0.55)
        }
    }

    var secondaryColor: Color {
        switch emotion {
        case .calm: Color(red: 0.77, green: 0.86, blue: 0.81)
        case .joy: Color(red: 0.96, green: 0.84, blue: 0.48)
        case .low: Color(red: 0.73, green: 0.78, blue: 0.84)
        case .anxious: Color(red: 0.72, green: 0.69, blue: 0.86)
        case .excited: Color(red: 0.91, green: 0.58, blue: 0.43)
        case .tired: Color(red: 0.76, green: 0.71, blue: 0.64)
        case .grateful: Color(red: 0.94, green: 0.75, blue: 0.42)
        case .mixed: Color(red: 0.82, green: 0.74, blue: 0.50)
        }
    }
}
```

- [ ] **步骤 5：运行符文测试**

运行：

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/GlyphSignatureTests
```

预期：符文测试通过。

- [ ] **步骤 6：提交符文签名**

运行：

```bash
git add DayGlyph/Glyph/SeededRandom.swift DayGlyph/Glyph/GlyphSignature.swift DayGlyphTests/GlyphSignatureTests.swift
git commit -m "Add deterministic glyph signatures"
```

---

### 任务 4：符文 Canvas 渲染器

**文件：**
- 创建：`DayGlyph/Glyph/GlyphCanvasView.swift`

- [ ] **步骤 1：添加 Canvas 渲染器**

添加 `DayGlyph/Glyph/GlyphCanvasView.swift`，实现一个可缩放渲染器，支持弧线、放射线、折线、点、波形和混合图案：

```swift
import SwiftUI

struct GlyphCanvasView: View {
    var signature: GlyphSignature
    var lineWidth: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(size.width, size.height) * 0.36
            var random = SeededRandom(seed: signature.seed)

            drawBackground(in: rect, context: &context)

            switch signature.motif {
            case .arcs:
                drawArcs(center: center, radius: radius, random: &random, context: &context)
            case .radiant:
                drawRadiant(center: center, radius: radius, random: &random, context: &context)
            case .folded:
                drawFolded(center: center, radius: radius, random: &random, context: &context)
            case .dotted:
                drawDotted(center: center, radius: radius, random: &random, context: &context)
            case .wave:
                drawWave(center: center, radius: radius, random: &random, context: &context)
            case .hybrid:
                drawArcs(center: center, radius: radius, random: &random, context: &context)
                drawDotted(center: center, radius: radius * 0.85, random: &random, context: &context)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("\(signature.emotion.title)情绪符文")
    }

    private func drawBackground(in rect: CGRect, context: inout GraphicsContext) {
        let path = Path(ellipseIn: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08))
        context.fill(path, with: .color(signature.secondaryColor.opacity(0.18)))
    }

    private func drawArcs(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        for index in 0..<signature.strokeCount {
            let start = Angle.degrees(Double(index) * 28 + random.next() * 18 + signature.rotation)
            let end = start + Angle.degrees(70 + random.next() * 80)
            var path = Path()
            path.addArc(center: center, radius: radius * (0.55 + CGFloat(random.next()) * 0.55), startAngle: start, endAngle: end, clockwise: false)
            context.stroke(path, with: .color(index.isMultiple(of: 2) ? signature.primaryColor : signature.secondaryColor), lineWidth: lineWidth)
        }
    }

    private func drawRadiant(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        for index in 0..<signature.strokeCount {
            let angle = (Double(index) / Double(max(signature.strokeCount, 1))) * .pi * 2 + random.next()
            let inner = radius * (0.16 + CGFloat(random.next()) * 0.24)
            let outer = radius * (0.65 + CGFloat(random.next()) * 0.45)
            var path = Path()
            path.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
            context.stroke(path, with: .color(index.isMultiple(of: 2) ? signature.primaryColor : signature.secondaryColor), lineWidth: lineWidth)
        }
    }

    private func drawFolded(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        var path = Path()
        for index in 0...signature.strokeCount {
            let progress = Double(index) / Double(max(signature.strokeCount, 1))
            let angle = progress * .pi * 2 + Double(signature.rotation) * .pi / 180
            let localRadius = radius * (0.28 + CGFloat(random.next()) * 0.72)
            let point = CGPoint(x: center.x + cos(angle) * localRadius, y: center.y + sin(angle) * localRadius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        context.stroke(path, with: .color(signature.primaryColor), lineWidth: lineWidth)
    }

    private func drawDotted(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        for _ in 0..<(signature.strokeCount + 3) {
            let angle = random.next() * .pi * 2
            let distance = radius * (0.18 + CGFloat(random.next()) * 0.82)
            let dotRadius = CGFloat(3 + random.next() * 8) * max(lineWidth / 4, 0.7)
            let point = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
            context.fill(Path(ellipseIn: CGRect(x: point.x - dotRadius, y: point.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)), with: .color(signature.primaryColor.opacity(0.78)))
        }
    }

    private func drawWave(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        for band in 0..<3 {
            var path = Path()
            let yOffset = CGFloat(band - 1) * radius * 0.26
            for step in 0...40 {
                let x = center.x - radius + CGFloat(step) / 40 * radius * 2
                let wave = sin(CGFloat(step) / 40 * .pi * 2 + CGFloat(signature.rotation) / 90) * radius * (0.12 + CGFloat(random.next()) * 0.05)
                let point = CGPoint(x: x, y: center.y + yOffset + wave)
                step == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            context.stroke(path, with: .color(band == 1 ? signature.primaryColor : signature.secondaryColor), lineWidth: lineWidth)
        }
    }
}

#Preview {
    GlyphCanvasView(signature: GlyphSignature(analysis: EmotionAnalysis(emotion: .calm, theme: .rest, energy: 0.4, keywords: ["休息"]), seed: 24))
        .padding()
}
```

- [ ] **步骤 2：构建以捕获 Canvas 编译错误**

运行：

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

预期：构建通过。如果本地 Swift 版本不支持 `Angle + Angle`，将 `let end = start + Angle.degrees(...)` 替换为 `let end = Angle.degrees(start.degrees + ...)`。

- [ ] **步骤 3：提交渲染器**

运行：

```bash
git add DayGlyph/Glyph/GlyphCanvasView.swift
git commit -m "Render glyphs with SwiftUI Canvas"
```

---

### 任务 5：带测试的月份日历辅助工具

**文件：**
- 创建：`DayGlyph/Utilities/CalendarMonth.swift`
- 创建：`DayGlyphTests/CalendarMonthTests.swift`

- [ ] **步骤 1：编写日历测试**

添加 `DayGlyphTests/CalendarMonthTests.swift`：

```swift
import Foundation
import Testing
@testable import DayGlyph

struct CalendarMonthTests {
    @Test func monthGridContainsAtLeastOneFullCalendarPage() throws {
        let calendar = Calendar(identifier: .gregorian)
        let june2026 = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 8)))
        let month = CalendarMonth(containing: june2026, calendar: calendar)

        #expect(month.days.count >= 35)
        #expect(month.days.count.isMultiple(of: 7))
        #expect(month.days.contains { $0.dayNumber == 8 && $0.isInDisplayedMonth })
    }
}
```

- [ ] **步骤 2：实现月份辅助工具**

添加 `DayGlyph/Utilities/CalendarMonth.swift`：

```swift
import Foundation

struct CalendarDay: Identifiable, Equatable {
    var date: Date
    var isInDisplayedMonth: Bool
    var dayNumber: Int

    var id: Date { date }
}

struct CalendarMonth: Equatable {
    var displayedMonth: Date
    var days: [CalendarDay]

    init(containing date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstOfMonth = calendar.date(from: components) ?? calendar.startOfDay(for: date)
        self.displayedMonth = firstOfMonth

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingDays = (weekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: firstOfMonth) ?? firstOfMonth
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<31
        let total = max(35, Int(ceil(Double(leadingDays + range.count) / 7.0)) * 7)

        self.days = (0..<total).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            let isSameMonth = calendar.component(.month, from: day) == calendar.component(.month, from: firstOfMonth)
                && calendar.component(.year, from: day) == calendar.component(.year, from: firstOfMonth)
            return CalendarDay(date: calendar.startOfDay(for: day), isInDisplayedMonth: isSameMonth, dayNumber: calendar.component(.day, from: day))
        }
    }

    func addingMonths(_ value: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }
}
```

- [ ] **步骤 3：运行日历测试**

运行：

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/CalendarMonthTests
```

预期：日历测试通过。

- [ ] **步骤 4：提交日历辅助工具**

运行：

```bash
git add DayGlyph/Utilities/CalendarMonth.swift DayGlyphTests/CalendarMonthTests.swift
git commit -m "Add calendar month helper"
```

---

### 任务 6：共享样式和 App 外壳

**文件：**
- 创建：`DayGlyph/Views/DayGlyphStyle.swift`
- 创建：`DayGlyph/Views/AppRootView.swift`

- [ ] **步骤 1：添加共享样式**

添加 `DayGlyph/Views/DayGlyphStyle.swift`：

```swift
import SwiftUI

enum DayGlyphStyle {
    static let ink = Color(red: 0.08, green: 0.13, blue: 0.12)
    static let mutedInk = Color(red: 0.36, green: 0.43, blue: 0.40)
    static let paper = Color(red: 0.97, green: 0.94, blue: 0.88)
    static let mist = Color(red: 0.86, green: 0.91, blue: 0.87)

    static var background: LinearGradient {
        LinearGradient(
            colors: [paper, mist],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CapsuleLabel: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(DayGlyphStyle.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.18), in: Capsule())
    }
}
```

- [ ] **步骤 2：添加标签页外壳**

添加 `DayGlyph/Views/AppRootView.swift`：

```swift
import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("今日", systemImage: "sparkle")
            }

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("月历", systemImage: "calendar")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "slider.horizontal.3")
            }
        }
        .tint(DayGlyphStyle.ink)
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
```

- [ ] **步骤 3：构建并提交**

运行：

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
git add DayGlyph/Views/DayGlyphStyle.swift DayGlyph/Views/AppRootView.swift
git commit -m "Add DayGlyph app shell"
```

预期：在 `TodayView`、`CalendarView` 和 `SettingsView` 存在之前，构建可能会失败。如果失败，继续执行任务 7，再将任务 6 和 7 一起提交。

---

### 任务 7：今日记录流程

**文件：**
- 创建：`DayGlyph/Views/TodayView.swift`

- [ ] **步骤 1：实现今日视图**

添加 `DayGlyph/Views/TodayView.swift`，包含：

- `@Environment(\.modelContext)`
- `@Query(sort: \DayEntry.date, order: .reverse)`
- `@State private var entryText = ""`
- `@State private var latestEntry: DayEntry?`
- 本地 `EmotionAnalyzer`
- 使用 `Calendar.current.isDate(_:inSameDayAs:)` 匹配今天的保存/更新逻辑

使用这些精确可见字符串：

```swift
Text("一划")
Text("今天留下些什么？")
Text("一句话也可以，一小段也很好。")
Text("生成今日一划")
Text("可以更轻一点")
```

保存动作必须为：

```swift
let analysis = analyzer.analyze(entryText)
let seed = GlyphSignature.seed(for: entryText, date: .now)
if let existing = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: .now) }) {
    existing.update(text: entryText, analysis: analysis, glyphSeed: seed)
    latestEntry = existing
} else {
    let entry = DayEntry(date: .now, text: entryText, emotion: analysis.emotion, energy: analysis.energy, theme: analysis.theme, keywords: analysis.keywords, glyphSeed: seed)
    modelContext.insert(entry)
    latestEntry = entry
}
try? modelContext.save()
```

- [ ] **步骤 2：包含结果渲染**

生成后的结果区域必须展示：

- `GlyphCanvasView(signature: GlyphSignature(analysis: EmotionAnalysis(...), seed: entry.glyphSeed))`
- 情绪标签
- 主题标签
- 能量百分比
- 保存状态文本 `已保存为今天的一划`

- [ ] **步骤 3：构建并提交**

运行：

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
git add DayGlyph/Views/TodayView.swift DayGlyph/Views/AppRootView.swift DayGlyph/Views/DayGlyphStyle.swift
git commit -m "Add today glyph entry flow"
```

预期：在 `CalendarView` 和 `SettingsView` 存在之前，构建可能仍会失败。如果失败，继续执行任务 8 再提交。

---

### 任务 8：日历和详情流程

**文件：**
- 创建：`DayGlyph/Views/CalendarView.swift`
- 创建：`DayGlyph/Views/EntryDetailView.swift`

- [ ] **步骤 1：实现详情视图**

添加 `DayGlyph/Views/EntryDetailView.swift`：

```swift
import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var entry: DayEntry

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                GlyphCanvasView(signature: signature, lineWidth: 5)
                    .frame(maxWidth: 260)
                    .padding(.top, 20)

                VStack(spacing: 10) {
                    Text(entry.date, format: .dateTime.year().month().day())
                        .font(.headline)
                    HStack {
                        CapsuleLabel(text: entry.emotion.title, color: signature.primaryColor)
                        CapsuleLabel(text: entry.theme.title, color: signature.secondaryColor)
                        CapsuleLabel(text: "\(Int(entry.energy * 100))%", color: .white)
                    }
                }

                Text(entry.text)
                    .font(.body)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))

                Button(role: .destructive) {
                    modelContext.delete(entry)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Label("删除这一天", systemImage: "trash")
                }
            }
            .padding(22)
        }
        .background(DayGlyphStyle.background.ignoresSafeArea())
        .navigationTitle("一划详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var signature: GlyphSignature {
        GlyphSignature(
            analysis: EmotionAnalysis(emotion: entry.emotion, theme: entry.theme, energy: entry.energy, keywords: entry.keywords),
            seed: entry.glyphSeed
        )
    }
}
```

- [ ] **步骤 2：实现月份网格**

添加 `DayGlyph/Views/CalendarView.swift`，包含：

- `@Query(sort: \DayEntry.date, order: .forward)`
- `@State private var displayedDate = Date()`
- `CalendarMonth(containing: displayedDate)`
- 7 列 `LazyVGrid`
- 对有记录的日期包裹 `NavigationLink`
- 用于记录的小型 `GlyphCanvasView`
- 使用 `chevron.left` 和 `chevron.right` 的月份切换按钮

使用这些精确可见字符串：

```swift
Text("情绪月历")
Text("日 一 二 三 四 五 六")
Text("还没有记录")
```

- [ ] **步骤 3：构建并提交日历流程**

运行：

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
git add DayGlyph/Views/CalendarView.swift DayGlyph/Views/EntryDetailView.swift
git commit -m "Add glyph calendar and detail views"
```

预期：在 `SettingsView` 存在之前，构建可能仍会失败。如果失败，继续执行任务 9 再提交。

---

### 任务 9：提醒和演示数据

**文件：**
- 创建：`DayGlyph/Services/ReminderService.swift`
- 创建：`DayGlyph/Services/DemoDataSeeder.swift`
- 创建：`DayGlyph/Views/SettingsView.swift`

- [ ] **步骤 1：添加提醒服务**

添加 `DayGlyph/Services/ReminderService.swift`：

```swift
import Foundation
import UserNotifications

@MainActor
final class ReminderService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dayglyph.daily"])

        let content = UNMutableNotificationContent()
        content.title = "今天的一划"
        content.body = "留一点今天给自己。"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dayglyph.daily", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dayglyph.daily"])
    }
}
```

- [ ] **步骤 2：添加演示数据填充器**

添加 `DayGlyph/Services/DemoDataSeeder.swift`：

```swift
import Foundation
import SwiftData

enum DemoDataSeeder {
    static let samples = [
        "今天终于把拖了很久的项目收尾了，心里松了一口气。",
        "和朋友聊了很久，发现自己其实被理解着。",
        "睡得不好，一整天都有点累，只想早点休息。",
        "早上散步的时候很平静，风吹过来的时候觉得刚刚好。",
        "会议有点多，压力也上来了，但我还是撑住了。",
        "看完一本书，突然对接下来的方向更清楚了。",
        "和家人吃饭，很普通，但很安心。",
        "今天灵感很好，画了几个之前一直想做的草图。",
        "有一点低落，说不上原因，只是想慢一点。",
        "收到客户确认，大家一起努力终于有结果了。"
    ]

    static func seed(into context: ModelContext, calendar: Calendar = .current) {
        clearDemoEntries(in: context)
        let analyzer = EmotionAnalyzer()

        for offset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
            let text = samples[offset % samples.count]
            let analysis = analyzer.analyze(text)
            let seed = GlyphSignature.seed(for: text, date: date, calendar: calendar)
            let entry = DayEntry(date: date, text: text, emotion: analysis.emotion, energy: analysis.energy, theme: analysis.theme, keywords: analysis.keywords, glyphSeed: seed, isDemo: true)
            context.insert(entry)
        }
        try? context.save()
    }

    static func clearDemoEntries(in context: ModelContext) {
        let descriptor = FetchDescriptor<DayEntry>(predicate: #Predicate { $0.isDemo == true })
        let entries = (try? context.fetch(descriptor)) ?? []
        entries.forEach(context.delete)
        try? context.save()
    }

    static func clearAllEntries(in context: ModelContext) {
        let descriptor = FetchDescriptor<DayEntry>()
        let entries = (try? context.fetch(descriptor)) ?? []
        entries.forEach(context.delete)
        try? context.save()
    }
}
```

- [ ] **步骤 3：添加设置视图**

添加 `DayGlyph/Views/SettingsView.swift`：

- `@Environment(\.modelContext)`
- `@AppStorage("reminderEnabled")`
- `@AppStorage("reminderHour")`
- `@AppStorage("reminderMinute")`
- `@StateObject private var reminderService = ReminderService()`
- 一个用于提醒时间的 `DatePicker`
- 一个 `Toggle("每日提醒", isOn: $reminderEnabled)`
- 按钮 `填充演示月` 和 `清空全部记录`
- 隐私文案 `记录与分析保存在本机。`

当提醒开启时：

```swift
Task {
    let granted = await reminderService.requestAuthorization()
    if granted {
        await reminderService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
    } else {
        reminderEnabled = false
    }
}
```

当提醒关闭时：

```swift
reminderService.cancelDailyReminder()
```

- [ ] **步骤 4：构建并提交设置**

运行：

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
git add DayGlyph/Services/ReminderService.swift DayGlyph/Services/DemoDataSeeder.swift DayGlyph/Views/SettingsView.swift
git commit -m "Add reminders and demo data controls"
```

预期：构建通过。

---

### 任务 10：端到端验证

**文件：**
- 如有需要，仅修改前面任务中的文件。

- [ ] **步骤 1：运行完整测试**

运行：

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

预期：所有单元测试通过。如果模拟器名称不可用，使用 `xcrun simctl list devices available`，并用最新可用的 iPhone 模拟器重新运行。

- [ ] **步骤 2：使用 XcodeBuildMCP 在模拟器中构建并运行**

使用 Build iOS Apps 调试器工作流：

1. 调用 `session_show_defaults`。
2. 如果默认值缺失，发现项目并将默认值设为 `DayGlyph.xcodeproj`、scheme `DayGlyph` 和一个已启动的 iPhone 模拟器。
3. 调用 `build_run_sim`。
4. 调用 `describe_ui` 或捕获截图。

预期：app 启动到“今日”标签页，并显示“今天留下些什么？”。

- [ ] **步骤 3：手动演示检查清单**

在运行中的 app 内：

1. 确认“今日”标签页出现。
2. 确认空输入无法生成。
3. 输入 `今天终于把拖了很久的项目收尾了，心里松了一口气，也很感谢同事。`
4. 点击 `生成今日一划`。
5. 确认出现一个大型符文，并带有情绪/主题标签。
6. 打开“设置”。
7. 点击 `填充演示月`。
8. 打开“月历”。
9. 确认许多日期显示符文。
10. 点击某个有记录的日期。
11. 确认详情页显示大型符文和原始文本。
12. 返回“设置”并打开提醒开关。
13. 确认通知权限弹窗行为或权限状态文本。

- [ ] **步骤 4：提交最终修复**

如果需要最终编译或 UI 修复：

```bash
git add DayGlyph DayGlyphTests
git commit -m "Polish DayGlyph demo flow"
```

预期：最终的 `git status --short` 只显示之前就存在的无关 Xcode 用户数据。

---

## 自查

- 规格覆盖：今日输入、本地分析、Canvas 符文、SwiftData 持久化、同日更新、日历、详情、提醒、演示数据填充、清空数据、本地优先隐私文案和验证，都已映射到具体任务。
- 占位扫描：没有任何实现步骤依赖未定义的未来任务。唯一有意保留的未来扩展说明是架构中的 Foundation Models 接口；当前实现使用本地分析器。
- 类型一致性：`DayEmotion`、`DayTheme`、`EmotionAnalysis`、`DayEntry`、`GlyphSignature`、`GlyphCanvasView`、`CalendarMonth`、`ReminderService` 和 `DemoDataSeeder` 在各任务中命名保持一致。
