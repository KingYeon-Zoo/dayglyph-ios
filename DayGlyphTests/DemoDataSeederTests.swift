import Foundation
import SwiftData
import Testing
@testable import DayGlyph

struct DemoDataSeederTests {
    @Test func seedPreservesRealEntriesAndCreatesVersionTwoFixtures() throws {
        let container = try ModelContainer(
            for: DayEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: .now)
        let realAnalysis = EmotionAnalysis(
            valence: 0.2,
            arousal: 0.3,
            dominance: 0.1,
            emotionWeights: [EmotionWeight(anchor: .calm, value: 1)],
            theme: .unknown,
            keywords: [],
            source: .foundationModel
        )
        let realEntry = try DayEntryStore.saveEntry(
            text: "这是一条真实记录。",
            date: today,
            analysis: realAnalysis,
            context: context,
            calendar: calendar
        )

        DemoDataSeeder.seed(into: context, calendar: calendar)

        let entries = try context.fetch(FetchDescriptor<DayEntry>())
        let demos = entries.filter(\.isDemo)
        let preserved = try #require(entries.first(where: { $0.date == today }))

        #expect(preserved.persistentModelID == realEntry.persistentModelID)
        #expect(preserved.text == "这是一条真实记录。")
        #expect(preserved.isDemo == false)
        #expect(demos.isEmpty == false)
        #expect(demos.allSatisfy { $0.analysisVersion == 2 })
        #expect(demos.allSatisfy { $0.analysisSource == .demoFixture })
    }

    @Test func fixturesCoverEveryEmotionAnchor() throws {
        let container = try ModelContainer(
            for: DayEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        DemoDataSeeder.seed(into: context)

        let demos = try context.fetch(FetchDescriptor<DayEntry>())
            .filter(\.isDemo)
        let anchors = Set(demos.map(\.primaryEmotion))

        #expect(anchors == Set(EmotionAnchor.allCases))
    }
}
