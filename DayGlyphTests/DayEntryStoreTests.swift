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
            valence: 0.32,
            arousal: 0.42,
            dominance: 0.46,
            emotionWeights: [
                EmotionWeight(anchor: .relief, value: 0.72),
                EmotionWeight(anchor: .calm, value: 0.28)
            ],
            theme: .work,
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

        #expect(entry.primaryEmotion == .relief)
        #expect(entry.valence == 0.32)
        #expect(entry.arousal == 0.42)
        #expect(entry.dominance == 0.46)
        #expect(entry.emotionWeights.map(\.anchor).contains(.relief))
        #expect(entry.analysisVersion == 2)
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
            valence: -0.4,
            arousal: 0.2,
            dominance: -0.5,
            emotionWeights: [EmotionWeight(anchor: .tired, value: 1)],
            theme: .rest,
            keywords: ["休息"],
            confidence: 0.7,
            explanation: "疲惫感明显。",
            source: .localRules
        )
        let second = EmotionAnalysis(
            valence: 0.72,
            arousal: 0.58,
            dominance: 0.42,
            emotionWeights: [
                EmotionWeight(anchor: .grateful, value: 0.8),
                EmotionWeight(anchor: .joy, value: 0.2)
            ],
            theme: .relationship,
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
        #expect(updated.primaryEmotion == .grateful)
        #expect(updated.valence == 0.72)
        #expect(updated.dominance == 0.42)
        #expect(updated.emotionWeights.first(where: { $0.anchor == .grateful })?.value == 0.8)
        #expect(updated.analysisSource == .foundationModel)
    }
}
