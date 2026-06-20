import Foundation
import SwiftData
import Testing
@testable import DayGlyph

struct DemoDataSeederTests {
    /// 构造一组内存中的演示资产，避开 bundle 依赖。复用现成的丰富降级样本作为 manifest。
    private func makeAssets(count: Int) throws -> [DemoAssetCatalog.Entry] {
        let response = try #require(DemoFallbackCatalog.validatedRichSample())
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let pixel = Data([0xFF, 0xD8, 0xFF, 0xD9]) // 占位 JPEG 字节
        return try (0 ..< count).map { index in
            let cocktail = tmp.appendingPathComponent("c\(index).jpeg")
            let planet = tmp.appendingPathComponent("p\(index).jpeg")
            try pixel.write(to: cocktail)
            try pixel.write(to: planet)
            return DemoAssetCatalog.Entry(
                slug: "demo-\(index)",
                text: "演示记录 \(index)：今天交织着欣慰与疲惫。",
                response: response,
                cocktailURL: cocktail,
                planetURL: planet
            )
        }
    }

    @Test func seedPreservesRealEntriesAndCreatesDemoFixtures() throws {
        let container = try ModelContainer(
            for: DayEntry.self, AIGenerationRecord.self,
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

        DemoDataSeeder.seed(into: context, calendar: calendar, assets: try makeAssets(count: 8))

        let entries = try context.fetch(FetchDescriptor<DayEntry>())
        let demos = entries.filter(\.isDemo)
        let preserved = try #require(entries.first(where: { $0.date == today }))

        #expect(preserved.persistentModelID == realEntry.persistentModelID)
        #expect(preserved.text == "这是一条真实记录。")
        #expect(preserved.isDemo == false)
        #expect(demos.count == 8)
        #expect(demos.allSatisfy { $0.analysisVersion == 2 })
        #expect(demos.allSatisfy { $0.analysisSource == .demoFixture })
    }

    @Test func seedCreatesGenerationRecordWithSavedImages() throws {
        let container = try ModelContainer(
            for: DayEntry.self, AIGenerationRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        DemoDataSeeder.seed(into: context, assets: try makeAssets(count: 3))

        let records = try context.fetch(FetchDescriptor<AIGenerationRecord>())
        #expect(records.count == 3)
        #expect(records.allSatisfy { $0.isDemoFallback })
        #expect(records.allSatisfy { $0.cocktailStatus == .saved && $0.planetStatus == .saved })
        #expect(records.allSatisfy { $0.status == .completed })

        // 清理：删除演示记录应连带删图片目录与生成记录。
        DemoDataSeeder.clearDemoEntries(in: context)
        #expect(try context.fetch(FetchDescriptor<AIGenerationRecord>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<DayEntry>()).filter(\.isDemo).isEmpty)
    }

    @Test func clearingDemoEntriesNeverDeletesRealEntries() throws {
        let container = try ModelContainer(
            for: DayEntry.self, AIGenerationRecord.self,
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
