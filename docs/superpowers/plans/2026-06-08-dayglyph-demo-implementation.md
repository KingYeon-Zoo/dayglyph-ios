# DayGlyph Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete local-first DayGlyph iOS demo that can input a lightweight journal entry, analyze emotion/theme, generate a deterministic Canvas glyph, save entries, show a glyph month calendar, manage reminders, and seed demo data.

**Architecture:** Replace the template SwiftData `Item` flow with a small domain model centered on `DayEntry`. Keep pure logic in testable Swift files (`EmotionAnalyzer`, `GlyphSignature`, calendar helpers), render glyphs with SwiftUI `Canvas`, and keep app-wide UI inside a `TabView` with Today, Calendar, and Settings tabs. Foundation Models remains an internal future seam inside the analyzer; the demo ships with stable local rules.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing, UserNotifications, SwiftUI Canvas, Xcode 26 file-system-synchronized groups.

---

## File Structure

- Modify `DayGlyph/DayGlyphApp.swift`: register `DayEntry` in the SwiftData schema and launch `AppRootView`.
- Delete `DayGlyph/Item.swift`: remove the template model after replacing it.
- Replace `DayGlyph/ContentView.swift`: keep as a thin compatibility wrapper or replace with `AppRootView`.
- Create `DayGlyph/Models/DayEntry.swift`: SwiftData model and computed helpers.
- Create `DayGlyph/Models/Emotion.swift`: emotion/theme enums and `EmotionAnalysis`.
- Create `DayGlyph/Services/EmotionAnalyzer.swift`: deterministic local text analysis.
- Create `DayGlyph/Services/DemoDataSeeder.swift`: seed and clear demo records.
- Create `DayGlyph/Services/ReminderService.swift`: notification permission and scheduling.
- Create `DayGlyph/Glyph/GlyphSignature.swift`: visual parameters derived from a day entry.
- Create `DayGlyph/Glyph/SeededRandom.swift`: stable deterministic random generator.
- Create `DayGlyph/Glyph/GlyphCanvasView.swift`: SwiftUI Canvas renderer.
- Create `DayGlyph/Utilities/CalendarMonth.swift`: month grid/date helper.
- Create `DayGlyph/Views/AppRootView.swift`: `TabView` shell.
- Create `DayGlyph/Views/TodayView.swift`: input, generation, and today result.
- Create `DayGlyph/Views/CalendarView.swift`: month glyph grid.
- Create `DayGlyph/Views/EntryDetailView.swift`: detail and delete flow.
- Create `DayGlyph/Views/SettingsView.swift`: reminders and demo-data actions.
- Create `DayGlyph/Views/DayGlyphStyle.swift`: shared colors, spacing, labels.
- Modify `DayGlyphTests/DayGlyphTests.swift`: remove template placeholder.
- Create `DayGlyphTests/EmotionAnalyzerTests.swift`: analyzer coverage.
- Create `DayGlyphTests/GlyphSignatureTests.swift`: deterministic glyph coverage.
- Create `DayGlyphTests/CalendarMonthTests.swift`: month grid coverage.

The project already uses `PBXFileSystemSynchronizedRootGroup`, so files under `DayGlyph/` and `DayGlyphTests/` are picked up by the app/test targets without manually editing `DayGlyph.xcodeproj/project.pbxproj`.

---

### Task 1: Domain Model And App Wiring

**Files:**
- Create: `DayGlyph/Models/Emotion.swift`
- Create: `DayGlyph/Models/DayEntry.swift`
- Modify: `DayGlyph/DayGlyphApp.swift`
- Modify: `DayGlyph/ContentView.swift`
- Delete: `DayGlyph/Item.swift`

- [ ] **Step 1: Create emotion and analysis types**

Add `DayGlyph/Models/Emotion.swift`:

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

- [ ] **Step 2: Create the SwiftData entry model**

Add `DayGlyph/Models/DayEntry.swift`:

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

- [ ] **Step 3: Wire SwiftData to `DayEntry`**

Modify `DayGlyph/DayGlyphApp.swift` so the schema contains `DayEntry.self` and the root view is `AppRootView()`:

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

- [ ] **Step 4: Replace template content with a wrapper**

Replace `DayGlyph/ContentView.swift`:

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

- [ ] **Step 5: Delete the template model**

Delete `DayGlyph/Item.swift`.

- [ ] **Step 6: Commit domain wiring**

Run:

```bash
git add DayGlyph/Models/Emotion.swift DayGlyph/Models/DayEntry.swift DayGlyph/DayGlyphApp.swift DayGlyph/ContentView.swift
git rm DayGlyph/Item.swift
git commit -m "Replace template model with day entries"
```

Expected: commit succeeds and only model/app-wiring files are included.

---

### Task 2: Emotion Analyzer With Tests

**Files:**
- Create: `DayGlyph/Services/EmotionAnalyzer.swift`
- Modify: `DayGlyphTests/DayGlyphTests.swift`
- Create: `DayGlyphTests/EmotionAnalyzerTests.swift`

- [ ] **Step 1: Clear the template test file**

Replace `DayGlyphTests/DayGlyphTests.swift`:

```swift
import Testing
@testable import DayGlyph

struct DayGlyphTests {
    @Test func projectLoads() {
        #expect(DayEmotion.calm.title == "平静")
    }
}
```

- [ ] **Step 2: Write analyzer tests**

Add `DayGlyphTests/EmotionAnalyzerTests.swift`:

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

- [ ] **Step 3: Run tests to verify failure**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: fails because `EmotionAnalyzer` does not exist. If that simulator name is unavailable, run `xcrun simctl list devices available` and use the newest available iPhone simulator.

- [ ] **Step 4: Implement analyzer**

Add `DayGlyph/Services/EmotionAnalyzer.swift`:

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

- [ ] **Step 5: Run analyzer tests**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/EmotionAnalyzerTests
```

Expected: analyzer tests pass.

- [ ] **Step 6: Commit analyzer**

Run:

```bash
git add DayGlyph/Services/EmotionAnalyzer.swift DayGlyphTests/DayGlyphTests.swift DayGlyphTests/EmotionAnalyzerTests.swift
git commit -m "Add local emotion analyzer"
```

---

### Task 3: Deterministic Glyph Signature With Tests

**Files:**
- Create: `DayGlyph/Glyph/SeededRandom.swift`
- Create: `DayGlyph/Glyph/GlyphSignature.swift`
- Create: `DayGlyphTests/GlyphSignatureTests.swift`

- [ ] **Step 1: Write glyph tests**

Add `DayGlyphTests/GlyphSignatureTests.swift`:

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

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/GlyphSignatureTests
```

Expected: fails because `GlyphSignature` does not exist.

- [ ] **Step 3: Add deterministic random**

Add `DayGlyph/Glyph/SeededRandom.swift`:

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

- [ ] **Step 4: Add glyph signature**

Add `DayGlyph/Glyph/GlyphSignature.swift`:

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

- [ ] **Step 5: Run glyph tests**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/GlyphSignatureTests
```

Expected: glyph tests pass.

- [ ] **Step 6: Commit glyph signature**

Run:

```bash
git add DayGlyph/Glyph/SeededRandom.swift DayGlyph/Glyph/GlyphSignature.swift DayGlyphTests/GlyphSignatureTests.swift
git commit -m "Add deterministic glyph signatures"
```

---

### Task 4: Glyph Canvas Renderer

**Files:**
- Create: `DayGlyph/Glyph/GlyphCanvasView.swift`

- [ ] **Step 1: Add Canvas renderer**

Add `DayGlyph/Glyph/GlyphCanvasView.swift` with a scalable renderer that supports arcs, radiant lines, folded lines, dots, waves, and hybrid motifs:

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

- [ ] **Step 2: Build to catch Canvas compile errors**

Run:

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: build passes. If `Angle + Angle` fails on the local Swift version, replace `let end = start + Angle.degrees(...)` with `let end = Angle.degrees(start.degrees + ...)`.

- [ ] **Step 3: Commit renderer**

Run:

```bash
git add DayGlyph/Glyph/GlyphCanvasView.swift
git commit -m "Render glyphs with SwiftUI Canvas"
```

---

### Task 5: Calendar Month Helper With Tests

**Files:**
- Create: `DayGlyph/Utilities/CalendarMonth.swift`
- Create: `DayGlyphTests/CalendarMonthTests.swift`

- [ ] **Step 1: Write calendar tests**

Add `DayGlyphTests/CalendarMonthTests.swift`:

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

- [ ] **Step 2: Implement month helper**

Add `DayGlyph/Utilities/CalendarMonth.swift`:

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

- [ ] **Step 3: Run calendar tests**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/CalendarMonthTests
```

Expected: calendar tests pass.

- [ ] **Step 4: Commit calendar helper**

Run:

```bash
git add DayGlyph/Utilities/CalendarMonth.swift DayGlyphTests/CalendarMonthTests.swift
git commit -m "Add calendar month helper"
```

---

### Task 6: Shared Style And App Shell

**Files:**
- Create: `DayGlyph/Views/DayGlyphStyle.swift`
- Create: `DayGlyph/Views/AppRootView.swift`

- [ ] **Step 1: Add shared style**

Add `DayGlyph/Views/DayGlyphStyle.swift`:

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

- [ ] **Step 2: Add tab shell**

Add `DayGlyph/Views/AppRootView.swift`:

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

- [ ] **Step 3: Build and commit**

Run:

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
git add DayGlyph/Views/DayGlyphStyle.swift DayGlyph/Views/AppRootView.swift
git commit -m "Add DayGlyph app shell"
```

Expected: build may fail until `TodayView`, `CalendarView`, and `SettingsView` exist. If so, continue to Task 7 before committing Task 6 and 7 together.

---

### Task 7: Today Entry Flow

**Files:**
- Create: `DayGlyph/Views/TodayView.swift`

- [ ] **Step 1: Implement today view**

Add `DayGlyph/Views/TodayView.swift` with:

- `@Environment(\.modelContext)`
- `@Query(sort: \DayEntry.date, order: .reverse)`
- `@State private var entryText = ""`
- `@State private var latestEntry: DayEntry?`
- local `EmotionAnalyzer`
- save/update logic matching today by `Calendar.current.isDate(_:inSameDayAs:)`

Use these exact visible strings:

```swift
Text("一划")
Text("今天留下些什么？")
Text("一句话也可以，一小段也很好。")
Text("生成今日一划")
Text("可以更轻一点")
```

The save action must:

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

- [ ] **Step 2: Include result rendering**

The generated result section must show:

- `GlyphCanvasView(signature: GlyphSignature(analysis: EmotionAnalysis(...), seed: entry.glyphSeed))`
- emotion label
- theme label
- energy percentage
- saved status text `已保存为今天的一划`

- [ ] **Step 3: Build and commit**

Run:

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
git add DayGlyph/Views/TodayView.swift DayGlyph/Views/AppRootView.swift DayGlyph/Views/DayGlyphStyle.swift
git commit -m "Add today glyph entry flow"
```

Expected: build may still fail until `CalendarView` and `SettingsView` exist. If so, continue to Task 8 before committing.

---

### Task 8: Calendar And Detail Flow

**Files:**
- Create: `DayGlyph/Views/CalendarView.swift`
- Create: `DayGlyph/Views/EntryDetailView.swift`

- [ ] **Step 1: Implement detail view**

Add `DayGlyph/Views/EntryDetailView.swift`:

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

- [ ] **Step 2: Implement month grid**

Add `DayGlyph/Views/CalendarView.swift` with:

- `@Query(sort: \DayEntry.date, order: .forward)`
- `@State private var displayedDate = Date()`
- `CalendarMonth(containing: displayedDate)`
- 7-column `LazyVGrid`
- `NavigationLink` around days with entries
- small `GlyphCanvasView` for entries
- month switching buttons using `chevron.left` and `chevron.right`

Use these exact visible strings:

```swift
Text("情绪月历")
Text("日 一 二 三 四 五 六")
Text("还没有记录")
```

- [ ] **Step 3: Build and commit calendar flow**

Run:

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
git add DayGlyph/Views/CalendarView.swift DayGlyph/Views/EntryDetailView.swift
git commit -m "Add glyph calendar and detail views"
```

Expected: build may still fail until `SettingsView` exists. If so, continue to Task 9 before committing.

---

### Task 9: Reminders And Demo Data

**Files:**
- Create: `DayGlyph/Services/ReminderService.swift`
- Create: `DayGlyph/Services/DemoDataSeeder.swift`
- Create: `DayGlyph/Views/SettingsView.swift`

- [ ] **Step 1: Add reminder service**

Add `DayGlyph/Services/ReminderService.swift`:

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

- [ ] **Step 2: Add demo seeder**

Add `DayGlyph/Services/DemoDataSeeder.swift`:

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

- [ ] **Step 3: Add settings view**

Add `DayGlyph/Views/SettingsView.swift`:

- `@Environment(\.modelContext)`
- `@AppStorage("reminderEnabled")`
- `@AppStorage("reminderHour")`
- `@AppStorage("reminderMinute")`
- `@StateObject private var reminderService = ReminderService()`
- a `DatePicker` for reminder time
- a `Toggle("每日提醒", isOn: $reminderEnabled)`
- buttons `填充演示月` and `清空全部记录`
- privacy text `记录与分析保存在本机。`

When reminder turns on:

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

When reminder turns off:

```swift
reminderService.cancelDailyReminder()
```

- [ ] **Step 4: Build and commit settings**

Run:

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
git add DayGlyph/Services/ReminderService.swift DayGlyph/Services/DemoDataSeeder.swift DayGlyph/Views/SettingsView.swift
git commit -m "Add reminders and demo data controls"
```

Expected: build passes.

---

### Task 10: End-To-End Verification

**Files:**
- Modify if needed: files from previous tasks only.

- [ ] **Step 1: Run full tests**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: all unit tests pass. If simulator name is unavailable, use `xcrun simctl list devices available` and rerun with the newest available iPhone simulator.

- [ ] **Step 2: Build and run in Simulator using XcodeBuildMCP**

Use the Build iOS Apps debugger workflow:

1. Call `session_show_defaults`.
2. If defaults are missing, discover project and set defaults to `DayGlyph.xcodeproj`, scheme `DayGlyph`, and a booted iPhone simulator.
3. Call `build_run_sim`.
4. Call `describe_ui` or capture a screenshot.

Expected: app launches to the Today tab and shows “今天留下些什么？”.

- [ ] **Step 3: Manual demo checklist**

In the running app:

1. Confirm Today tab appears.
2. Confirm empty input cannot generate.
3. Type `今天终于把拖了很久的项目收尾了，心里松了一口气，也很感谢同事。`
4. Tap `生成今日一划`.
5. Confirm a large Glyph appears with emotion/theme labels.
6. Open Settings.
7. Tap `填充演示月`.
8. Open Calendar.
9. Confirm many days show Glyphs.
10. Tap one recorded day.
11. Confirm detail page shows large Glyph and original text.
12. Return to Settings and toggle reminder on.
13. Confirm notification permission prompt behavior or permission status text.

- [ ] **Step 4: Commit final fixes**

If any final compile or UI fixes are needed:

```bash
git add DayGlyph DayGlyphTests
git commit -m "Polish DayGlyph demo flow"
```

Expected: final `git status --short` only shows unrelated Xcode user data if it existed before.

---

## Self-Review

- Spec coverage: Today input, local analysis, Canvas glyphs, SwiftData persistence, same-day update, calendar, detail, reminders, demo seed, clear data, local-first privacy text, and verification are each mapped to a task.
- Placeholder scan: no implementation step depends on an undefined future task. The only intentional future-facing note is the Foundation Models seam in the architecture; implementation uses the local analyzer.
- Type consistency: `DayEmotion`, `DayTheme`, `EmotionAnalysis`, `DayEntry`, `GlyphSignature`, `GlyphCanvasView`, `CalendarMonth`, `ReminderService`, and `DemoDataSeeder` names are used consistently across tasks.
