# DayGlyph Intelligence Apple Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade DayGlyph from a rule-only visual demo into an Apple-platform demo with stronger emotion understanding, Apple-style deterministic Glyphs, real App Icon assets, and Apple Intelligence-facing integration through Foundation Models and App Intents.

**Architecture:** Keep the app local-first and deterministic. Introduce one unified analysis service that tries Foundation Models when available and falls back to enhanced local rules, then route all UI, demo seeding, and App Intents through shared analysis/save logic. Replace random Canvas strokes with a stable geometric signature and renderer, and expose only three high-value system actions through App Intents.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing, SwiftUI Canvas, FoundationModels, AppIntents, Xcode 26.5 iOS Simulator.

---

## File Structure

- Modify `DayGlyph/Models/Emotion.swift`: add `AnalysisSource`, confidence, explanation, display titles, and generated-output helper types.
- Modify `DayGlyph/Models/DayEntry.swift`: persist `confidence`, `analysisSourceRawValue`, and `explanation`; update initializer and `update`.
- Create `DayGlyph/Services/DayEntryStore.swift`: shared save/update logic used by Today UI, demo seeding, and App Intents.
- Modify `DayGlyph/Services/EmotionAnalyzer.swift`: turn it into the enhanced local rules analyzer.
- Create `DayGlyph/Services/FoundationEmotionAnalyzer.swift`: Foundation Models adapter with structured output and availability errors.
- Create `DayGlyph/Services/UnifiedEmotionAnalyzer.swift`: async orchestration layer that tries Foundation Models first and falls back to local rules.
- Modify `DayGlyph/Services/DemoDataSeeder.swift`: use the enhanced local analyzer and shared store.
- Modify `DayGlyph/Views/TodayView.swift`: call async unified analyzer, show explanation/source, and use shared store.
- Modify `DayGlyph/Views/EntryDetailView.swift`: show explanation and source.
- Modify `DayGlyph/Glyph/GlyphSignature.swift`: replace motif/stroke model with geometric badge parameters.
- Modify `DayGlyph/Glyph/GlyphCanvasView.swift`: replace random-line drawing with ordered Apple-style geometry.
- Create `DayGlyph/Intents/DayGlyphIntents.swift`: App Intents for recording today, opening today, and opening calendar.
- Create `DayGlyph/Intents/DayGlyphShortcuts.swift`: `AppShortcutsProvider`.
- Modify `DayGlyph/Assets.xcassets/AppIcon.appiconset/Contents.json`: reference actual icon files.
- Create `tools/generate_dayglyph_app_icons.py`: generate default, dark, and tinted 1024 PNG icons using Python standard library plus system `sips` if needed.
- Modify `DayGlyphTests/EmotionAnalyzerTests.swift`: stronger local-rule coverage.
- Create `DayGlyphTests/UnifiedEmotionAnalyzerTests.swift`: fallback coverage.
- Modify `DayGlyphTests/GlyphSignatureTests.swift`: geometric signature stability/constraints.
- Create `DayGlyphTests/DayEntryStoreTests.swift`: same-day update behavior with new fields.
- Create `DayGlyphTests/AppIntentCompileTests.swift`: lightweight compile-time coverage for intent titles/parameters.

This repository uses Xcode file-system-synchronized groups, so new files under `DayGlyph/` and `DayGlyphTests/` are picked up without editing `DayGlyph.xcodeproj/project.pbxproj`.

---

### Task 1: Analysis Model And Shared Entry Store

**Files:**
- Modify: `DayGlyph/Models/Emotion.swift`
- Modify: `DayGlyph/Models/DayEntry.swift`
- Create: `DayGlyph/Services/DayEntryStore.swift`
- Create: `DayGlyphTests/DayEntryStoreTests.swift`

- [ ] **Step 1: Write the DayEntry store tests**

Create `DayGlyphTests/DayEntryStoreTests.swift`:

```swift
import Foundation
import SwiftData
import Testing
@testable import DayGlyph

struct DayEntryStoreTests {
    @Test func saveCreatesEntryWithAnalysisMetadata() throws {
        let container = try ModelContainer(
            for: DayEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 9)))
        let analysis = EmotionAnalysis(
            emotion: .calm,
            theme: .work,
            energy: 0.42,
            keywords: ["收尾", "工作"],
            confidence: 0.74,
            explanation: "完成后的放松感更明显。",
            source: .localRules
        )

        let entry = try DayEntryStore.saveEntry(
            text: "今天很早就把事情搞完了，松了一口气。",
            date: date,
            analysis: analysis,
            context: context,
            calendar: calendar
        )

        #expect(entry.emotion == .calm)
        #expect(entry.theme == .work)
        #expect(entry.confidence == 0.74)
        #expect(entry.analysisSource == .localRules)
        #expect(entry.explanation == "完成后的放松感更明显。")
    }

    @Test func saveUpdatesSameDayEntryInsteadOfDuplicating() throws {
        let container = try ModelContainer(
            for: DayEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 9)))
        let first = EmotionAnalysis(
            emotion: .tired,
            theme: .rest,
            energy: 0.2,
            keywords: ["休息"],
            confidence: 0.7,
            explanation: "疲惫感明显。",
            source: .localRules
        )
        let second = EmotionAnalysis(
            emotion: .grateful,
            theme: .relationship,
            energy: 0.58,
            keywords: ["朋友"],
            confidence: 0.82,
            explanation: "被支持后的感恩更明显。",
            source: .foundationModel
        )

        _ = try DayEntryStore.saveEntry(text: "很累，只想睡。", date: date, analysis: first, context: context, calendar: calendar)
        let updated = try DayEntryStore.saveEntry(text: "朋友帮了我很多。", date: date, analysis: second, context: context, calendar: calendar)

        let entries = try context.fetch(FetchDescriptor<DayEntry>())
        #expect(entries.count == 1)
        #expect(updated.text == "朋友帮了我很多。")
        #expect(updated.emotion == .grateful)
        #expect(updated.analysisSource == .foundationModel)
    }
}
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/DayEntryStoreTests
```

Expected: fails because `confidence`, `AnalysisSource`, `analysisSource`, `explanation`, and `DayEntryStore` do not exist.

- [ ] **Step 3: Expand analysis model types**

Modify `DayGlyph/Models/Emotion.swift` so the full file is:

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
        case .unknown: "日常"
        }
    }
}

enum AnalysisSource: String, Codable, CaseIterable, Identifiable {
    case foundationModel
    case localRules
    case fallback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .foundationModel: "Apple Intelligence"
        case .localRules: "本地理解"
        case .fallback: "本地回退"
        }
    }
}

struct EmotionAnalysis: Equatable {
    var emotion: DayEmotion
    var theme: DayTheme
    var energy: Double
    var keywords: [String]
    var confidence: Double
    var explanation: String
    var source: AnalysisSource

    init(
        emotion: DayEmotion,
        theme: DayTheme,
        energy: Double,
        keywords: [String],
        confidence: Double = 0.55,
        explanation: String = "根据文字中的状态和语气做出的本地理解。",
        source: AnalysisSource = .localRules
    ) {
        self.emotion = emotion
        self.theme = theme
        self.energy = min(max(energy, 0), 1)
        self.keywords = Array(keywords.prefix(4))
        self.confidence = min(max(confidence, 0), 1)
        self.explanation = explanation
        self.source = source
    }
}
```

- [ ] **Step 4: Persist analysis metadata on DayEntry**

Modify `DayGlyph/Models/DayEntry.swift` by adding stored fields and updating initializer/update:

```swift
var confidence: Double
var analysisSourceRawValue: String
var explanation: String
```

Initializer assignments:

```swift
self.confidence = min(max(confidence, 0), 1)
self.analysisSourceRawValue = analysisSource.rawValue
self.explanation = explanation
```

Computed property:

```swift
var analysisSource: AnalysisSource {
    AnalysisSource(rawValue: analysisSourceRawValue) ?? .fallback
}
```

`update` assignments:

```swift
self.confidence = min(max(analysis.confidence, 0), 1)
self.analysisSourceRawValue = analysis.source.rawValue
self.explanation = analysis.explanation
```

Keep the old initializer signature source-compatible by adding defaulted parameters:

```swift
confidence: Double = 0.55,
analysisSource: AnalysisSource = .localRules,
explanation: String = "根据文字中的状态和语气做出的本地理解。",
```

- [ ] **Step 5: Add the shared store**

Create `DayGlyph/Services/DayEntryStore.swift`:

```swift
import Foundation
import SwiftData

enum DayEntryStore {
    static func saveEntry(
        text: String,
        date: Date = .now,
        analysis: EmotionAnalysis,
        context: ModelContext,
        calendar: Calendar = .current,
        isDemo: Bool = false
    ) throws -> DayEntry {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DayEntryStoreError.emptyText
        }

        let startOfDay = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        let seed = GlyphSignature.seed(for: trimmed, date: startOfDay, calendar: calendar)

        if let existing = try context.fetch(descriptor).first {
            existing.update(text: trimmed, analysis: analysis, glyphSeed: seed, date: .now)
            existing.isDemo = isDemo
            try context.save()
            return existing
        }

        let entry = DayEntry(
            date: startOfDay,
            text: trimmed,
            emotion: analysis.emotion,
            energy: analysis.energy,
            theme: analysis.theme,
            keywords: analysis.keywords,
            glyphSeed: seed,
            confidence: analysis.confidence,
            analysisSource: analysis.source,
            explanation: analysis.explanation,
            isDemo: isDemo
        )
        context.insert(entry)
        try context.save()
        return entry
    }
}

enum DayEntryStoreError: LocalizedError, Equatable {
    case emptyText

    var errorDescription: String? {
        switch self {
        case .emptyText: "记录内容不能为空。"
        }
    }
}
```

- [ ] **Step 6: Run store tests and commit**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/DayEntryStoreTests
```

Expected: `DayEntryStoreTests` pass.

Commit:

```bash
git add DayGlyph/Models/Emotion.swift DayGlyph/Models/DayEntry.swift DayGlyph/Services/DayEntryStore.swift DayGlyphTests/DayEntryStoreTests.swift
git commit -m "Add analysis metadata to day entries"
```

---

### Task 2: Enhanced Local Emotion Analyzer

**Files:**
- Modify: `DayGlyph/Services/EmotionAnalyzer.swift`
- Modify: `DayGlyphTests/EmotionAnalyzerTests.swift`

- [ ] **Step 1: Replace analyzer tests with stronger behavior coverage**

Modify `DayGlyphTests/EmotionAnalyzerTests.swift`:

```swift
import Testing
@testable import DayGlyph

struct EmotionAnalyzerTests {
    @Test func detectsCompletionReliefWithoutUnknown() {
        let result = EmotionAnalyzer().analyze("今天很早就把那个事情搞完了，整个人松了一口气。")

        #expect(result.emotion == .calm || result.emotion == .joy)
        #expect(result.theme == .work)
        #expect(result.confidence >= 0.55)
        #expect(result.explanation.isEmpty == false)
        #expect(result.source == .localRules)
    }

    @Test func detectsFoggyMixedState() {
        let result = EmotionAnalyzer().analyze("说不上来，脑子很乱，但还是把今天撑过去了。")

        #expect(result.emotion == .anxious || result.emotion == .mixed)
        #expect(result.theme.title.isEmpty == false)
        #expect(result.confidence >= 0.45)
        #expect(result.energy >= 0.45)
    }

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

    @Test func ordinaryTextDoesNotFallBackToUnknownEmotion() {
        let result = EmotionAnalyzer().analyze("今天去拿了快递，回来的路上买了杯热咖啡。")

        #expect(result.emotion != .mixed || result.confidence >= 0.4)
        #expect(result.theme.title.isEmpty == false)
        #expect(result.explanation.isEmpty == false)
    }

    @Test func emptyTextFallsBackToMixedUnknown() {
        let result = EmotionAnalyzer().analyze("   ")

        #expect(result.emotion == .mixed)
        #expect(result.theme == .unknown)
        #expect(result.energy == 0.3)
        #expect(result.keywords.isEmpty)
        #expect(result.source == .fallback)
    }
}
```

- [ ] **Step 2: Run tests to verify current analyzer fails**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/EmotionAnalyzerTests
```

Expected: failures for completion relief, foggy mixed state, ordinary text metadata, and new fields if Task 1 is not complete.

- [ ] **Step 3: Replace `EmotionAnalyzer` with weighted local rules**

Modify `DayGlyph/Services/EmotionAnalyzer.swift` to use weighted dictionaries:

```swift
import Foundation

struct EmotionAnalyzer {
    func analyze(_ text: String) -> EmotionAnalysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return EmotionAnalysis(
                emotion: .mixed,
                theme: .unknown,
                energy: 0.3,
                keywords: [],
                confidence: 0.1,
                explanation: "还没有足够内容可以理解。",
                source: .fallback
            )
        }

        let normalized = normalize(trimmed)
        let emotionScores = scoreEmotion(in: normalized)
        let themeScores = scoreTheme(in: normalized)
        let emotion = strongestEmotion(from: emotionScores, text: normalized)
        let theme = strongestTheme(from: themeScores, text: normalized)
        let energy = energyScore(in: normalized, emotion: emotion)
        let confidence = confidenceScore(emotionScores: emotionScores, themeScores: themeScores, text: normalized)
        let keywords = extractKeywords(from: normalized, theme: theme, emotion: emotion)
        let explanation = explanation(for: emotion, theme: theme, text: normalized, confidence: confidence)

        return EmotionAnalysis(
            emotion: emotion,
            theme: theme,
            energy: energy,
            keywords: keywords,
            confidence: confidence,
            explanation: explanation,
            source: .localRules
        )
    }

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "搞定", with: "搞完")
            .replacingOccurrences(of: "搞好了", with: "搞完")
            .replacingOccurrences(of: "处理好了", with: "搞完")
            .replacingOccurrences(of: "完事", with: "搞完")
    }

    private func scoreEmotion(in text: String) -> [DayEmotion: Double] {
        let table: [(DayEmotion, Double, [String])] = [
            (.grateful, 1.4, ["感谢", "感恩", "谢谢", "被理解", "帮我", "幸运", "珍惜", "grateful", "thanks"]),
            (.joy, 1.2, ["开心", "快乐", "高兴", "满足", "好棒", "喜欢", "顺利", "搞完", "完成", "终于", "happy"]),
            (.calm, 1.2, ["平静", "安静", "放松", "散步", "呼吸", "松了一口气", "轻松", "安心", "刚刚好", "calm"]),
            (.tired, 1.3, ["累", "疲惫", "困", "睡不好", "提不起劲", "不想动", "撑不住", "tired", "exhausted"]),
            (.anxious, 1.3, ["焦虑", "担心", "紧张", "害怕", "压力", "脑子很乱", "很乱", "慌", "卡住", "anxious"]),
            (.low, 1.25, ["难过", "低落", "沮丧", "失望", "孤独", "说不上来", "空空的", "没意思", "sad", "down"]),
            (.excited, 1.15, ["激动", "兴奋", "冲刺", "突破", "太好了", "thrilled", "excited"])
        ]

        var scores: [DayEmotion: Double] = [:]
        for (emotion, weight, keywords) in table {
            for keyword in keywords where text.contains(keyword) {
                scores[emotion, default: 0] += weight
            }
        }
        if text.contains("但") || text.contains("不过") || text.contains("可是") {
            scores[.mixed, default: 0] += 0.45
        }
        return scores
    }

    private func scoreTheme(in text: String) -> [DayTheme: Double] {
        let table: [(DayTheme, Double, [String])] = [
            (.work, 1.2, ["工作", "项目", "会议", "客户", "同事", "deadline", "收尾", "事情", "任务", "搞完", "work"]),
            (.relationship, 1.2, ["朋友", "伴侣", "关系", "聊天", "沟通", "同事帮", "被理解", "friend", "love"]),
            (.growth, 1.0, ["学习", "成长", "复盘", "进步", "读书", "方向", "learn"]),
            (.rest, 1.0, ["休息", "睡", "散步", "放空", "累", "咖啡", "rest", "sleep"]),
            (.family, 1.0, ["家", "父母", "孩子", "妈妈", "爸爸", "family"]),
            (.health, 1.0, ["身体", "运动", "跑步", "健康", "病", "health"]),
            (.creativity, 1.0, ["画", "写", "设计", "创作", "灵感", "create"])
        ]

        var scores: [DayTheme: Double] = [:]
        for (theme, weight, keywords) in table {
            for keyword in keywords where text.contains(keyword) {
                scores[theme, default: 0] += weight
            }
        }
        return scores
    }

    private func strongestEmotion(from scores: [DayEmotion: Double], text: String) -> DayEmotion {
        let sorted = scores.sorted { $0.value > $1.value }
        guard let best = sorted.first, best.value > 0 else {
            return text.count <= 6 ? .mixed : .calm
        }
        if let second = sorted.dropFirst().first, second.value >= best.value * 0.82 {
            return .mixed
        }
        return best.key
    }

    private func strongestTheme(from scores: [DayTheme: Double], text: String) -> DayTheme {
        scores.max { $0.value < $1.value }?.key ?? .unknown
    }

    private func energyScore(in text: String, emotion: DayEmotion) -> Double {
        var score: Double = switch emotion {
        case .excited: 0.78
        case .joy, .grateful: 0.62
        case .anxious: 0.68
        case .calm: 0.38
        case .low, .tired: 0.28
        case .mixed: 0.52
        }
        score += Double(text.filter { $0 == "!" || $0 == "！" }.count) * 0.05
        if text.contains("很") || text.contains("特别") || text.contains("太") { score += 0.06 }
        if text.contains("终于") || text.contains("撑") { score += 0.05 }
        score += min(Double(text.count) / 700.0, 0.08)
        return min(max(score, 0), 1)
    }

    private func confidenceScore(emotionScores: [DayEmotion: Double], themeScores: [DayTheme: Double], text: String) -> Double {
        let emotionStrength = emotionScores.values.max() ?? 0
        let themeStrength = themeScores.values.max() ?? 0
        let lengthBonus = min(Double(text.count) / 80.0, 0.18)
        return min(max(0.38 + emotionStrength * 0.14 + themeStrength * 0.08 + lengthBonus, 0.25), 0.92)
    }

    private func extractKeywords(from text: String, theme: DayTheme, emotion: DayEmotion) -> [String] {
        let candidates = [
            "项目", "感谢", "同事", "朋友", "学习", "家人", "运动", "创作", "完成", "搞完",
            "压力", "睡", "咖啡", "脑子很乱", "松了一口气", theme.title, emotion.title
        ]
        var result: [String] = []
        for candidate in candidates where text.contains(candidate) && !result.contains(candidate) {
            result.append(candidate)
            if result.count == 4 { break }
        }
        if result.isEmpty {
            result.append(theme == .unknown ? emotion.title : theme.title)
        }
        return result
    }

    private func explanation(for emotion: DayEmotion, theme: DayTheme, text: String, confidence: Double) -> String {
        if confidence < 0.45 {
            return "这段话比较含蓄，先按整体语气保留为\(emotion.title)。"
        }
        if text.contains("搞完") || text.contains("完成") || text.contains("松了一口气") {
            return "文字里有完成和释放感，整体更接近\(emotion.title)。"
        }
        if theme == .unknown {
            return "根据语气和状态词，今天更接近\(emotion.title)。"
        }
        return "结合\(theme.title)相关内容和语气，今天更接近\(emotion.title)。"
    }
}
```

- [ ] **Step 4: Run analyzer tests and commit**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/EmotionAnalyzerTests
```

Expected: `EmotionAnalyzerTests` pass.

Commit:

```bash
git add DayGlyph/Services/EmotionAnalyzer.swift DayGlyphTests/EmotionAnalyzerTests.swift
git commit -m "Improve local emotion analysis"
```

---

### Task 3: Foundation Models Adapter And Unified Analyzer

**Files:**
- Create: `DayGlyph/Services/FoundationEmotionAnalyzer.swift`
- Create: `DayGlyph/Services/UnifiedEmotionAnalyzer.swift`
- Create: `DayGlyphTests/UnifiedEmotionAnalyzerTests.swift`

- [ ] **Step 1: Write fallback tests for unified analyzer**

Create `DayGlyphTests/UnifiedEmotionAnalyzerTests.swift`:

```swift
import Testing
@testable import DayGlyph

struct UnifiedEmotionAnalyzerTests {
    @Test func fallsBackToLocalRulesWhenFoundationAnalyzerUnavailable() async {
        let analyzer = UnifiedEmotionAnalyzer(
            foundationAnalyzer: UnavailableFoundationAnalyzer(),
            localAnalyzer: EmotionAnalyzer()
        )

        let result = await analyzer.analyze("今天很早就把事情搞完了，松了一口气。")

        #expect(result.source == .localRules || result.source == .fallback)
        #expect(result.emotion != .mixed || result.confidence >= 0.45)
        #expect(result.explanation.isEmpty == false)
    }
}

private struct UnavailableFoundationAnalyzer: FoundationEmotionAnalyzing {
    func analyze(_ text: String) async throws -> EmotionAnalysis {
        throw FoundationEmotionAnalyzerError.unavailable("测试中模拟 Foundation Models 不可用。")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/UnifiedEmotionAnalyzerTests
```

Expected: fails because unified/Foundation analyzer protocols do not exist.

- [ ] **Step 3: Add Foundation Models adapter**

Create `DayGlyph/Services/FoundationEmotionAnalyzer.swift`:

```swift
import Foundation
import FoundationModels

protocol FoundationEmotionAnalyzing: Sendable {
    func analyze(_ text: String) async throws -> EmotionAnalysis
}

enum FoundationEmotionAnalyzerError: LocalizedError, Equatable {
    case unavailable(String)
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason): reason
        case .invalidOutput: "Apple Intelligence 返回了无法使用的分析结果。"
        }
    }
}

struct FoundationEmotionAnalyzer: FoundationEmotionAnalyzing {
    func analyze(_ text: String) async throws -> EmotionAnalysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FoundationEmotionAnalyzerError.invalidOutput
        }

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw FoundationEmotionAnalyzerError.unavailable(String(describing: reason))
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            你是 DayGlyph 的本机情绪理解模块。只根据用户写下的当天记录做轻量分类，不做医疗、心理诊断或绝对判断。
            emotionRawValue 只能是 calm, joy, low, anxious, excited, tired, grateful, mixed。
            themeRawValue 只能是 work, relationship, growth, rest, family, health, creativity, unknown。
            energy 和 confidence 必须是 0 到 1 的小数。
            explanation 使用简体中文，限制在 32 个汉字左右。
            keywords 返回 1 到 4 个简体中文关键词。
            """
        )

        let response = try await session.respond(
            to: "分析这段 DayGlyph 记录：\(trimmed)",
            generating: FoundationEmotionOutput.self
        )
        return response.content.analysis
    }
}

@Generable
struct FoundationEmotionOutput {
    @Guide(description: "情绪 raw value，只能是 calm, joy, low, anxious, excited, tired, grateful, mixed")
    var emotionRawValue: String

    @Guide(description: "主题 raw value，只能是 work, relationship, growth, rest, family, health, creativity, unknown")
    var themeRawValue: String

    @Guide(description: "0 到 1 之间的能量值")
    var energy: Double

    @Guide(description: "1 到 4 个关键词")
    var keywords: [String]

    @Guide(description: "0 到 1 之间的置信度")
    var confidence: Double

    @Guide(description: "简短中文解释，不超过 32 个汉字")
    var explanation: String

    var analysis: EmotionAnalysis {
        EmotionAnalysis(
            emotion: DayEmotion(rawValue: emotionRawValue) ?? .mixed,
            theme: DayTheme(rawValue: themeRawValue) ?? .unknown,
            energy: energy,
            keywords: keywords,
            confidence: confidence,
            explanation: explanation,
            source: .foundationModel
        )
    }
}
```

- [ ] **Step 4: Add unified async analyzer**

Create `DayGlyph/Services/UnifiedEmotionAnalyzer.swift`:

```swift
import Foundation

struct UnifiedEmotionAnalyzer {
    var foundationAnalyzer: any FoundationEmotionAnalyzing
    var localAnalyzer: EmotionAnalyzer

    init(
        foundationAnalyzer: any FoundationEmotionAnalyzing = FoundationEmotionAnalyzer(),
        localAnalyzer: EmotionAnalyzer = EmotionAnalyzer()
    ) {
        self.foundationAnalyzer = foundationAnalyzer
        self.localAnalyzer = localAnalyzer
    }

    func analyze(_ text: String) async -> EmotionAnalysis {
        do {
            return try await foundationAnalyzer.analyze(text)
        } catch {
            var local = localAnalyzer.analyze(text)
            if local.source == .localRules {
                local.source = .fallback
            }
            return local
        }
    }
}
```

- [ ] **Step 5: Run unified analyzer tests and build**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/UnifiedEmotionAnalyzerTests
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: test and build pass. If the `@Guide` macro signature differs, adjust only according to the local SDK swiftinterface in `FoundationModels.swiftmodule`.

- [ ] **Step 6: Commit**

```bash
git add DayGlyph/Services/FoundationEmotionAnalyzer.swift DayGlyph/Services/UnifiedEmotionAnalyzer.swift DayGlyphTests/UnifiedEmotionAnalyzerTests.swift
git commit -m "Add Foundation Models emotion analyzer"
```

---

### Task 4: Wire Analysis Into UI And Demo Data

**Files:**
- Modify: `DayGlyph/Views/TodayView.swift`
- Modify: `DayGlyph/Views/EntryDetailView.swift`
- Modify: `DayGlyph/Services/DemoDataSeeder.swift`

- [ ] **Step 1: Update TodayView to use async unified analysis and shared store**

Modify `DayGlyph/Views/TodayView.swift`:

```swift
@State private var isAnalyzing = false
@State private var errorMessage = ""

private let analyzer = UnifiedEmotionAnalyzer()
```

Update the button label:

```swift
Label(isAnalyzing ? "正在理解今天" : "生成今日一划", systemImage: "wand.and.sparkles")
```

Disable while analyzing:

```swift
.disabled(isAnalyzing || entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
```

Replace `generateTodayGlyph()` with:

```swift
private func generateTodayGlyph() {
    let trimmed = entryText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    isEditorFocused = false
    isAnalyzing = true
    errorMessage = ""

    Task {
        let analysis = await analyzer.analyze(trimmed)
        do {
            let entry = try DayEntryStore.saveEntry(
                text: trimmed,
                analysis: analysis,
                context: modelContext
            )
            await MainActor.run {
                latestEntry = entry
                saveMessage = "已保存为今天的一划"
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAnalyzing = false
            }
        }
    }
}
```

Add result card metadata under the labels:

```swift
Text(entry.explanation)
    .font(.footnote)
    .foregroundStyle(DayGlyphStyle.mutedInk)
    .multilineTextAlignment(.center)

Text(entry.analysisSource.title)
    .font(.caption.weight(.semibold))
    .foregroundStyle(DayGlyphStyle.mutedInk)
```

Show errors after the button:

```swift
if !errorMessage.isEmpty {
    Text(errorMessage)
        .font(.footnote)
        .foregroundStyle(.red)
}
```

- [ ] **Step 2: Update EntryDetailView metadata**

Modify `DayGlyph/Views/EntryDetailView.swift` by adding below the capsule row:

```swift
Text(entry.explanation)
    .font(.callout)
    .foregroundStyle(DayGlyphStyle.mutedInk)
    .multilineTextAlignment(.center)

Text("理解来源：\(entry.analysisSource.title) · 置信度 \(Int(entry.confidence * 100))%")
    .font(.caption.weight(.semibold))
    .foregroundStyle(DayGlyphStyle.mutedInk)
```

- [ ] **Step 3: Update DemoDataSeeder to use shared store**

Modify the loop in `DayGlyph/Services/DemoDataSeeder.swift`:

```swift
for offset in 0..<30 {
    guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
    let text = samples[offset % samples.count]
    let analysis = analyzer.analyze(text)
    _ = try? DayEntryStore.saveEntry(
        text: text,
        date: date,
        analysis: analysis,
        context: context,
        calendar: calendar,
        isDemo: true
    )
}
```

- [ ] **Step 4: Build and commit**

Run:

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: build passes.

Commit:

```bash
git add DayGlyph/Views/TodayView.swift DayGlyph/Views/EntryDetailView.swift DayGlyph/Services/DemoDataSeeder.swift
git commit -m "Use unified analyzer in app flows"
```

---

### Task 5: Apple-Style Geometric Glyphs

**Files:**
- Modify: `DayGlyph/Glyph/GlyphSignature.swift`
- Modify: `DayGlyph/Glyph/GlyphCanvasView.swift`
- Modify: `DayGlyphTests/GlyphSignatureTests.swift`

- [ ] **Step 1: Update GlyphSignature tests**

Modify `DayGlyphTests/GlyphSignatureTests.swift`:

```swift
import Foundation
import Testing
@testable import DayGlyph

struct GlyphSignatureTests {
    @Test func sameInputsProduceSameSeed() {
        let date = Date(timeIntervalSince1970: 1_780_876_800)
        let first = GlyphSignature.seed(for: "今天很平静", date: date)
        let second = GlyphSignature.seed(for: "今天很平静", date: date)

        #expect(first == second)
    }

    @Test func signatureUsesEmotionAndEnergyForGeometry() {
        let analysis = EmotionAnalysis(emotion: .excited, theme: .work, energy: 0.9, keywords: ["项目"], confidence: 0.8, explanation: "能量较高。", source: .localRules)
        let signature = GlyphSignature(analysis: analysis, seed: 42)

        #expect(signature.emotion == .excited)
        #expect(signature.density >= 0.7)
        #expect(signature.baseShape == .radiantSeal)
        #expect(signature.accentCount <= 9)
    }

    @Test func lowEnergyStaysSparse() {
        let analysis = EmotionAnalysis(emotion: .tired, theme: .rest, energy: 0.2, keywords: ["休息"], confidence: 0.7, explanation: "疲惫。", source: .localRules)
        let signature = GlyphSignature(analysis: analysis, seed: 12)

        #expect(signature.density <= 0.45)
        #expect(signature.accentCount <= 5)
    }
}
```

- [ ] **Step 2: Run tests to verify failures**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/GlyphSignatureTests
```

Expected: fails because `density`, `baseShape`, and `accentCount` do not exist.

- [ ] **Step 3: Replace signature model with geometric parameters**

Modify `DayGlyph/Glyph/GlyphSignature.swift`:

```swift
import Foundation
import SwiftUI

enum GlyphBaseShape: String, Equatable {
    case calmRing
    case warmOrbit
    case lowPool
    case offsetOrbit
    case radiantSeal
    case quietBlock
    case heldArc
    case layered
}

enum GlyphAccentShape: String, Equatable {
    case dot
    case capsule
    case arc
    case notch
}

struct GlyphPalette: Equatable {
    var background: Color
    var primary: Color
    var secondary: Color
    var accent: Color
}

struct GlyphSignature: Equatable {
    var emotion: DayEmotion
    var theme: DayTheme
    var energy: Double
    var confidence: Double
    var seed: Int
    var baseShape: GlyphBaseShape
    var accentShape: GlyphAccentShape
    var density: Double
    var accentCount: Int
    var rotation: Double
    var palette: GlyphPalette

    init(analysis: EmotionAnalysis, seed: Int) {
        let clampedEnergy = min(max(analysis.energy, 0), 1)
        self.emotion = analysis.emotion
        self.theme = analysis.theme
        self.energy = clampedEnergy
        self.confidence = min(max(analysis.confidence, 0), 1)
        self.seed = seed
        self.baseShape = Self.baseShape(for: analysis.emotion)
        self.accentShape = Self.accentShape(for: analysis.theme)
        self.density = 0.22 + clampedEnergy * 0.68
        self.accentCount = min(max(2 + Int((clampedEnergy * 7).rounded()), 2), 9)
        self.rotation = Double(abs(seed % 360))
        self.palette = Self.palette(for: analysis.emotion)
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

    static func baseShape(for emotion: DayEmotion) -> GlyphBaseShape {
        switch emotion {
        case .calm: .calmRing
        case .joy: .warmOrbit
        case .low: .lowPool
        case .anxious: .offsetOrbit
        case .excited: .radiantSeal
        case .tired: .quietBlock
        case .grateful: .heldArc
        case .mixed: .layered
        }
    }

    static func accentShape(for theme: DayTheme) -> GlyphAccentShape {
        switch theme {
        case .work, .growth: .capsule
        case .relationship, .family: .arc
        case .health, .rest: .dot
        case .creativity: .notch
        case .unknown: .dot
        }
    }

    static func palette(for emotion: DayEmotion) -> GlyphPalette {
        switch emotion {
        case .calm:
            GlyphPalette(background: Color(red: 0.91, green: 0.96, blue: 0.93), primary: Color(red: 0.10, green: 0.38, blue: 0.34), secondary: Color(red: 0.52, green: 0.73, blue: 0.66), accent: Color(red: 0.83, green: 0.70, blue: 0.42))
        case .joy:
            GlyphPalette(background: Color(red: 1.00, green: 0.96, blue: 0.84), primary: Color(red: 0.52, green: 0.34, blue: 0.08), secondary: Color(red: 0.93, green: 0.70, blue: 0.22), accent: Color(red: 0.96, green: 0.52, blue: 0.32))
        case .low:
            GlyphPalette(background: Color(red: 0.91, green: 0.94, blue: 0.97), primary: Color(red: 0.25, green: 0.34, blue: 0.48), secondary: Color(red: 0.57, green: 0.65, blue: 0.75), accent: Color(red: 0.78, green: 0.72, blue: 0.60))
        case .anxious:
            GlyphPalette(background: Color(red: 0.93, green: 0.92, blue: 0.98), primary: Color(red: 0.30, green: 0.29, blue: 0.58), secondary: Color(red: 0.59, green: 0.56, blue: 0.78), accent: Color(red: 0.82, green: 0.58, blue: 0.45))
        case .excited:
            GlyphPalette(background: Color(red: 1.00, green: 0.92, blue: 0.89), primary: Color(red: 0.62, green: 0.18, blue: 0.16), secondary: Color(red: 0.89, green: 0.43, blue: 0.32), accent: Color(red: 0.96, green: 0.74, blue: 0.36))
        case .tired:
            GlyphPalette(background: Color(red: 0.94, green: 0.92, blue: 0.88), primary: Color(red: 0.36, green: 0.32, blue: 0.27), secondary: Color(red: 0.64, green: 0.59, blue: 0.51), accent: Color(red: 0.76, green: 0.70, blue: 0.60))
        case .grateful:
            GlyphPalette(background: Color(red: 1.00, green: 0.95, blue: 0.87), primary: Color(red: 0.48, green: 0.26, blue: 0.08), secondary: Color(red: 0.84, green: 0.51, blue: 0.18), accent: Color(red: 0.93, green: 0.70, blue: 0.34))
        case .mixed:
            GlyphPalette(background: Color(red: 0.94, green: 0.96, blue: 0.94), primary: Color(red: 0.18, green: 0.34, blue: 0.37), secondary: Color(red: 0.73, green: 0.62, blue: 0.32), accent: Color(red: 0.66, green: 0.35, blue: 0.32))
        }
    }

    var primaryColor: Color { palette.primary }
    var secondaryColor: Color { palette.secondary }
}
```

- [ ] **Step 4: Rewrite Canvas renderer with ordered badge geometry**

Modify `DayGlyph/Glyph/GlyphCanvasView.swift` to:

```swift
import SwiftUI

struct GlyphCanvasView: View {
    var signature: GlyphSignature
    var lineWidth: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(size.width, size.height) * 0.34
            var random = SeededRandom(seed: signature.seed)

            drawBadge(in: rect, context: &context)
            drawBase(center: center, radius: radius, random: &random, context: &context)
            drawAccents(center: center, radius: radius, random: &random, context: &context)
            drawCore(center: center, radius: radius, context: &context)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("\(signature.emotion.title)情绪符号")
    }

    private func drawBadge(in rect: CGRect, context: inout GraphicsContext) {
        let inset = rect.width * 0.08
        let badge = RoundedRectangle(cornerRadius: rect.width * 0.22, style: .continuous)
            .path(in: rect.insetBy(dx: inset, dy: inset))
        context.fill(badge, with: .linearGradient(
            Gradient(colors: [signature.palette.background, signature.palette.background.opacity(0.72)]),
            startPoint: CGPoint(x: rect.minX, y: rect.minY),
            endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
        ))
        context.stroke(badge, with: .color(.white.opacity(0.72)), lineWidth: max(lineWidth * 0.35, 1))
    }

    private func drawBase(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        switch signature.baseShape {
        case .calmRing, .warmOrbit, .heldArc:
            drawRing(center: center, radius: radius, context: &context)
        case .lowPool, .quietBlock:
            drawSoftBlock(center: center, radius: radius, context: &context)
        case .offsetOrbit, .layered:
            drawOffsetRings(center: center, radius: radius, context: &context)
        case .radiantSeal:
            drawRadiantCapsules(center: center, radius: radius, context: &context)
        }
    }

    private func drawRing(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        var outer = Path()
        outer.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.stroke(outer, with: .color(signature.palette.primary), lineWidth: lineWidth * 1.8)

        var arc = Path()
        arc.addArc(center: center, radius: radius * 0.72, startAngle: .degrees(signature.rotation), endAngle: .degrees(signature.rotation + 220), clockwise: false)
        context.stroke(arc, with: .color(signature.palette.secondary), lineWidth: lineWidth * 1.15)
    }

    private func drawSoftBlock(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        let rect = CGRect(x: center.x - radius * 0.78, y: center.y - radius * 0.62, width: radius * 1.56, height: radius * 1.24)
        let block = RoundedRectangle(cornerRadius: radius * 0.34, style: .continuous).path(in: rect)
        context.fill(block, with: .color(signature.palette.secondary.opacity(0.30)))
        context.stroke(block, with: .color(signature.palette.primary), lineWidth: lineWidth * 1.35)
    }

    private func drawOffsetRings(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        drawRing(center: center, radius: radius, context: &context)
        let offset = radius * 0.16
        var second = Path()
        second.addEllipse(in: CGRect(x: center.x - radius * 0.72 + offset, y: center.y - radius * 0.72 - offset, width: radius * 1.44, height: radius * 1.44))
        context.stroke(second, with: .color(signature.palette.accent.opacity(0.74)), lineWidth: lineWidth)
    }

    private func drawRadiantCapsules(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        for index in 0..<signature.accentCount {
            let angle = (Double(index) / Double(signature.accentCount)) * .pi * 2 + signature.rotation * .pi / 180
            let length = radius * (0.26 + signature.density * 0.12)
            let capsuleCenter = CGPoint(x: center.x + cos(angle) * radius * 0.72, y: center.y + sin(angle) * radius * 0.72)
            let rect = CGRect(x: capsuleCenter.x - lineWidth * 0.75, y: capsuleCenter.y - length / 2, width: lineWidth * 1.5, height: length)
            var copy = context
            copy.translateBy(x: capsuleCenter.x, y: capsuleCenter.y)
            copy.rotate(by: .radians(angle))
            copy.translateBy(x: -capsuleCenter.x, y: -capsuleCenter.y)
            copy.fill(RoundedRectangle(cornerRadius: lineWidth, style: .continuous).path(in: rect), with: .color(signature.palette.primary.opacity(0.86)))
        }
    }

    private func drawAccents(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        for index in 0..<signature.accentCount {
            let progress = Double(index) / Double(max(signature.accentCount, 1))
            let angle = progress * .pi * 2 + signature.rotation * .pi / 180
            let distance = radius * (0.34 + 0.34 * signature.density)
            let point = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
            drawAccent(at: point, angle: angle, radius: radius, context: &context)
        }
    }

    private func drawAccent(at point: CGPoint, angle: Double, radius: CGFloat, context: inout GraphicsContext) {
        switch signature.accentShape {
        case .dot:
            let dot = radius * 0.07
            context.fill(Path(ellipseIn: CGRect(x: point.x - dot, y: point.y - dot, width: dot * 2, height: dot * 2)), with: .color(signature.palette.accent))
        case .capsule:
            let rect = CGRect(x: point.x - radius * 0.045, y: point.y - radius * 0.16, width: radius * 0.09, height: radius * 0.32)
            var copy = context
            copy.translateBy(x: point.x, y: point.y)
            copy.rotate(by: .radians(angle))
            copy.translateBy(x: -point.x, y: -point.y)
            copy.fill(RoundedRectangle(cornerRadius: radius * 0.045, style: .continuous).path(in: rect), with: .color(signature.palette.accent))
        case .arc:
            var arc = Path()
            arc.addArc(center: point, radius: radius * 0.13, startAngle: .degrees(20), endAngle: .degrees(210), clockwise: false)
            context.stroke(arc, with: .color(signature.palette.accent), lineWidth: lineWidth * 0.8)
        case .notch:
            let rect = CGRect(x: point.x - radius * 0.08, y: point.y - radius * 0.08, width: radius * 0.16, height: radius * 0.16)
            context.fill(RoundedRectangle(cornerRadius: radius * 0.035, style: .continuous).path(in: rect), with: .color(signature.palette.accent))
        }
    }

    private func drawCore(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        let coreRadius = radius * (0.16 + signature.confidence * 0.06)
        context.fill(Path(ellipseIn: CGRect(x: center.x - coreRadius, y: center.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2)), with: .color(signature.palette.primary))
        context.fill(Path(ellipseIn: CGRect(x: center.x - coreRadius * 0.42, y: center.y - coreRadius * 0.42, width: coreRadius * 0.84, height: coreRadius * 0.84)), with: .color(signature.palette.background.opacity(0.86)))
    }
}

#Preview {
    GlyphCanvasView(signature: GlyphSignature(analysis: EmotionAnalysis(emotion: .calm, theme: .rest, energy: 0.4, keywords: ["休息"], confidence: 0.7, explanation: "平静。", source: .localRules), seed: 24))
        .padding()
}
```

- [ ] **Step 5: Run tests/build and commit**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/GlyphSignatureTests
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: tests and build pass.

Commit:

```bash
git add DayGlyph/Glyph/GlyphSignature.swift DayGlyph/Glyph/GlyphCanvasView.swift DayGlyphTests/GlyphSignatureTests.swift
git commit -m "Redesign glyphs as geometric badges"
```

---

### Task 6: App Icon Assets

**Files:**
- Create: `tools/generate_dayglyph_app_icons.py`
- Modify: `DayGlyph/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `DayGlyph/Assets.xcassets/AppIcon.appiconset/dayglyph-icon-default.png`
- Create: `DayGlyph/Assets.xcassets/AppIcon.appiconset/dayglyph-icon-dark.png`
- Create: `DayGlyph/Assets.xcassets/AppIcon.appiconset/dayglyph-icon-tinted.png`

- [ ] **Step 1: Add icon generation script**

Create `tools/generate_dayglyph_app_icons.py`:

```python
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "DayGlyph" / "Assets.xcassets" / "AppIcon.appiconset"
OUT.mkdir(parents=True, exist_ok=True)

SVG_TEMPLATE = """<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<rect width="1024" height="1024" rx="224" fill="{bg}"/>
<circle cx="512" cy="512" r="250" fill="none" stroke="{primary}" stroke-width="84"/>
<path d="M348 640 C424 724 602 724 676 538" fill="none" stroke="{secondary}" stroke-width="72" stroke-linecap="round"/>
<rect x="472" y="248" width="88" height="420" rx="44" fill="{accent}" transform="rotate(36 516 458)"/>
<circle cx="670" cy="656" r="58" fill="{dot}"/>
</svg>
"""

VARIANTS = {
    "dayglyph-icon-default.png": {
        "bg": "#F9F6EE",
        "primary": "#174C43",
        "secondary": "#D9B45F",
        "accent": "#C95147",
        "dot": "#174C43",
    },
    "dayglyph-icon-dark.png": {
        "bg": "#101614",
        "primary": "#D8EEE6",
        "secondary": "#D8B762",
        "accent": "#E06A5F",
        "dot": "#F3F0E8",
    },
    "dayglyph-icon-tinted.png": {
        "bg": "#F7F7F7",
        "primary": "#171717",
        "secondary": "#5D5D5D",
        "accent": "#2D2D2D",
        "dot": "#171717",
    },
}

for png_name, colors in VARIANTS.items():
    svg_path = OUT / png_name.replace(".png", ".svg")
    png_path = OUT / png_name
    svg_path.write_text(SVG_TEMPLATE.format(**colors), encoding="utf-8")
    subprocess.run(["/usr/bin/sips", "-s", "format", "png", str(svg_path), "--out", str(png_path)], check=True)
    svg_path.unlink()

print("Generated DayGlyph app icons in", OUT)
```

- [ ] **Step 2: Generate icons**

Run:

```bash
python3 tools/generate_dayglyph_app_icons.py
```

Expected: three 1024x1024 PNG files appear in `DayGlyph/Assets.xcassets/AppIcon.appiconset/`.

- [ ] **Step 3: Update AppIcon Contents.json**

Modify `DayGlyph/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [
    {
      "filename" : "dayglyph-icon-default.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "dayglyph-icon-dark.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "filename" : "dayglyph-icon-tinted.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Verify dimensions and build**

Run:

```bash
sips -g pixelWidth -g pixelHeight DayGlyph/Assets.xcassets/AppIcon.appiconset/dayglyph-icon-default.png
sips -g pixelWidth -g pixelHeight DayGlyph/Assets.xcassets/AppIcon.appiconset/dayglyph-icon-dark.png
sips -g pixelWidth -g pixelHeight DayGlyph/Assets.xcassets/AppIcon.appiconset/dayglyph-icon-tinted.png
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: each icon reports `pixelWidth: 1024` and `pixelHeight: 1024`; build passes.

- [ ] **Step 5: Commit**

```bash
git add tools/generate_dayglyph_app_icons.py DayGlyph/Assets.xcassets/AppIcon.appiconset
git commit -m "Add DayGlyph app icon assets"
```

---

### Task 7: App Intents And Shortcuts

**Files:**
- Create: `DayGlyph/Intents/DayGlyphIntents.swift`
- Create: `DayGlyph/Intents/DayGlyphShortcuts.swift`
- Create: `DayGlyphTests/AppIntentCompileTests.swift`

- [ ] **Step 1: Add compile-time intent tests**

Create `DayGlyphTests/AppIntentCompileTests.swift`:

```swift
import AppIntents
import Testing
@testable import DayGlyph

struct AppIntentCompileTests {
    @Test func intentTitlesArePresent() {
        #expect(String(localized: RecordTodayGlyphIntent.title) == "记录今天的一划")
        #expect(String(localized: OpenTodayIntent.title) == "打开今日一划")
        #expect(String(localized: OpenGlyphCalendarIntent.title) == "打开情绪月历")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/AppIntentCompileTests
```

Expected: fails because intent types do not exist.

- [ ] **Step 3: Add App Intents**

Create `DayGlyph/Intents/DayGlyphIntents.swift`:

```swift
import AppIntents
import Foundation
import SwiftData

struct RecordTodayGlyphIntent: AppIntent {
    static var title: LocalizedStringResource = "记录今天的一划"
    static var description = IntentDescription("写下一段今天的记录，并生成或更新今天的一划。")
    static var supportedModes: IntentModes = .background
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "记录内容", requestValueDialog: "今天留下些什么？")
    var text: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .result(dialog: "记录内容不能为空。")
        }

        let schema = Schema([DayEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let analysis = await UnifiedEmotionAnalyzer().analyze(trimmed)
        _ = try DayEntryStore.saveEntry(text: trimmed, analysis: analysis, context: context)

        return .result(dialog: "已记录今天的一划，理解为\(analysis.emotion.title)。")
    }
}

struct OpenTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "打开今日一划"
    static var description = IntentDescription("打开 DayGlyph 的今日记录页面。")
    static var supportedModes: IntentModes = .foreground
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct OpenGlyphCalendarIntent: AppIntent {
    static var title: LocalizedStringResource = "打开情绪月历"
    static var description = IntentDescription("打开 DayGlyph 的情绪月历。")
    static var supportedModes: IntentModes = .foreground
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        .result()
    }
}
```

- [ ] **Step 4: Add App Shortcuts provider**

Create `DayGlyph/Intents/DayGlyphShortcuts.swift`:

```swift
import AppIntents

struct DayGlyphShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordTodayGlyphIntent(),
            phrases: [
                "用\\(.applicationName)记录今天的一划",
                "在\\(.applicationName)写下今天"
            ],
            shortTitle: "记录一划",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: OpenTodayIntent(),
            phrases: [
                "打开\\(.applicationName)",
                "查看\\(.applicationName)今日一划"
            ],
            shortTitle: "打开今日",
            systemImageName: "square.and.pencil"
        )

        AppShortcut(
            intent: OpenGlyphCalendarIntent(),
            phrases: [
                "查看\\(.applicationName)情绪月历",
                "打开\\(.applicationName)月历"
            ],
            shortTitle: "情绪月历",
            systemImageName: "calendar"
        )
    }
}
```

- [ ] **Step 5: Run intent tests/build and commit**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests/AppIntentCompileTests
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: tests and build pass. If `IntentModes` symbols differ, adjust against the local AppIntents swiftinterface.

Commit:

```bash
git add DayGlyph/Intents DayGlyphTests/AppIntentCompileTests.swift
git commit -m "Expose DayGlyph actions with App Intents"
```

---

### Task 8: Final Verification And Polish Pass

**Files:**
- Modify only files required by failing tests/build diagnostics.

- [ ] **Step 1: Run focused test suite**

Run:

```bash
xcodebuild test -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DayGlyphTests
```

Expected: all `DayGlyphTests` pass. If UI tests hang, do not include `DayGlyphUITests` in this verification unless a UI flow fix specifically requires them.

- [ ] **Step 2: Run simulator build**

Run:

```bash
xcodebuild build -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: build succeeds with no errors.

- [ ] **Step 3: Check requirement coverage**

Run:

```bash
rg -n "FoundationModels|LanguageModelSession|SystemLanguageModel|AppIntent|AppShortcutsProvider|confidence|explanation|analysisSource" DayGlyph DayGlyphTests
find DayGlyph/Assets.xcassets/AppIcon.appiconset -maxdepth 1 -name '*.png' -print
```

Expected:

- Foundation Models symbols exist in `FoundationEmotionAnalyzer.swift`.
- App Intent symbols exist in `DayGlyph/Intents`.
- Analysis metadata exists in models/UI/tests.
- Three AppIcon PNG files are present.

- [ ] **Step 4: Commit final fixes if needed**

If Step 1 or Step 2 required fixes:

```bash
git add DayGlyph DayGlyphTests
git commit -m "Polish DayGlyph intelligence upgrade"
```

If no fixes were needed, do not create an empty commit.
