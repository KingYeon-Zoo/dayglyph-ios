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
