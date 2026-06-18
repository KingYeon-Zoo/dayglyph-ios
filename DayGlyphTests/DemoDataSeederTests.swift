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

    @Test func clearingDemoEntriesNeverDeletesRealEntries() throws {
        let container = try ModelContainer(
            for: DayEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let real = DayEntry(
            date: .now,
            text: "真实记录",
            analysis: EmotionAnalyzer().analyze("真实记录"),
            glyphSeed: 1,
            isDemo: false
        )
        let demo = DayEntry(
            date: .now.addingTimeInterval(-86_400),
            text: "演示记录",
            analysis: EmotionAnalyzer().analyze("演示记录"),
            glyphSeed: 2,
            isDemo: true
        )
        context.insert(real)
        context.insert(demo)
        try context.save()

        DemoDataSeeder.clearDemoEntries(in: context)

        let remaining = try context.fetch(FetchDescriptor<DayEntry>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.text == "真实记录")
        #expect(remaining.first?.isDemo == false)
    }

    @Test func clearingDemoSupportDataPreservesRealActionsAndResponses() throws {
        let container = try ModelContainer(
            for: ActionInstance.self, ActionResponse.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let realAction = ActionInstance(
            actionId: "real",
            entryId: nil,
            actionTitle: "真实行动",
            category: .rest,
            startedAt: .now,
            state: .completed,
            isDemo: false
        )
        let demoAction = ActionInstance(
            actionId: "demo",
            entryId: nil,
            actionTitle: "演示行动",
            category: .sensory,
            startedAt: .now,
            state: .completed,
            isDemo: true
        )
        context.insert(realAction)
        context.insert(demoAction)
        context.insert(ActionResponse(actionInstanceId: realAction.id, kind: .unchanged, isDemo: false))
        context.insert(ActionResponse(actionInstanceId: demoAction.id, kind: .moreSettled, isDemo: true))
        try context.save()

        DemoDataSeeder.clearDemoSupportData(in: context)

        let actions = try context.fetch(FetchDescriptor<ActionInstance>())
        let responses = try context.fetch(FetchDescriptor<ActionResponse>())
        #expect(actions.map(\.actionTitle) == ["真实行动"])
        #expect(responses.count == 1)
        #expect(responses.first?.isDemo == false)
    }
}
