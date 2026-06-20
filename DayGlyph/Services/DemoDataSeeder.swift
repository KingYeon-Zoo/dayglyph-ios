import Foundation
import SwiftData

enum DemoDataSeeder {

    /// 写入演示数据：每套 = 一条 DayEntry + 一条已完成的 AIGenerationRecord + 两张真图。
    ///
    /// 数据来自 bundle 内 `DemoAssetCatalog`（豆包真实生成的复杂样本与图片）。
    /// 情绪分析由 `GenerationAnalysisMapper` 从 manifest 投影，VAD/锚点权重是 AI 复杂度产物。
    static func seed(into context: ModelContext, calendar: Calendar = .current, assets: [DemoAssetCatalog.Entry]? = nil) {
        let assetStore = GeneratedAssetStore()
        let repository = GenerationRepository(context: context, assetStore: assetStore)

        clearDemoEntries(in: context, assetStore: assetStore)

        let entries = assets ?? DemoAssetCatalog().load()
        guard !entries.isEmpty else { return }

        let realDescriptor = FetchDescriptor<DayEntry>(predicate: #Predicate { $0.isDemo == false })
        let occupiedDays = Set(
            ((try? context.fetch(realDescriptor)) ?? [])
                .map { calendar.startOfDay(for: $0.date) }
        )

        var offset = 0
        for asset in entries {
            // 找到一个未被真实记录占用的日期（从今天往前铺）。
            var day = calendar.startOfDay(for: .now)
            while offset < 365 {
                if let candidate = calendar.date(byAdding: .day, value: -offset, to: .now) {
                    day = calendar.startOfDay(for: candidate)
                    offset += 1
                    if !occupiedDays.contains(day) { break }
                } else {
                    offset += 1
                }
            }

            let analysis = demoAnalysis(from: asset.response)
            guard let entry = try? DayEntryStore.saveEntry(
                text: asset.text,
                date: day,
                analysis: analysis,
                context: context,
                calendar: calendar,
                isDemo: true
            ) else { continue }

            attachGeneration(asset: asset, entry: entry, repository: repository, assetStore: assetStore)
        }
        try? context.save()
    }

    /// 从 manifest 投影成演示用 EmotionAnalysis（复用生产 mapper），source 标记为演示样本。
    private static func demoAnalysis(from response: DayGenerationResponse) -> EmotionAnalysis {
        let mapped = GenerationAnalysisMapper.makeAnalysis(from: response)
        return EmotionAnalysis(
            valence: mapped.valence,
            arousal: mapped.arousal,
            dominance: mapped.dominance,
            emotionWeights: mapped.emotionWeights,
            theme: mapped.theme,
            keywords: mapped.keywords,
            confidence: mapped.confidence,
            explanation: mapped.explanation,
            source: .demoFixture
        )
    }

    /// 为演示记录建一条已完成的 AIGenerationRecord，并把真图拷进 GeneratedAssetStore。
    private static func attachGeneration(
        asset: DemoAssetCatalog.Entry,
        entry: DayEntry,
        repository: GenerationRepository,
        assetStore: GeneratedAssetStore
    ) {
        let configuration = AIConfiguration.demo
        guard let record = try? repository.create(entryID: entry.entryID, configuration: configuration) else { return }
        record.setResponse(asset.response)
        record.isDemoFallback = true

        let cocktailOK = (try? copyImage(from: asset.cocktailURL, entryID: entry.entryID, generationID: record.generationID, slot: .cocktail, assetStore: assetStore)) != nil
        let planetOK = (try? copyImage(from: asset.planetURL, entryID: entry.entryID, generationID: record.generationID, slot: .planet, assetStore: assetStore)) != nil

        record.cocktailStatus = cocktailOK ? .saved : .failed
        record.planetStatus = planetOK ? .saved : .failed
        record.status = (cocktailOK && planetOK) ? .completed : .partiallyReady
        try? repository.save()
    }

    @discardableResult
    private static func copyImage(
        from url: URL,
        entryID: UUID,
        generationID: UUID,
        slot: GeneratedAssetStore.Slot,
        assetStore: GeneratedAssetStore
    ) throws -> URL {
        let data = try Data(contentsOf: url)
        return try assetStore.save(data, entryID: entryID, generationID: generationID, slot: slot)
    }

    static func clearDemoEntries(in context: ModelContext, assetStore: GeneratedAssetStore = GeneratedAssetStore()) {
        let descriptor = FetchDescriptor<DayEntry>(predicate: #Predicate { $0.isDemo == true })
        let entries = (try? context.fetch(descriptor)) ?? []
        let repository = GenerationRepository(context: context, assetStore: assetStore)
        for entry in entries {
            try? repository.deleteAll(for: entry.entryID)
            context.delete(entry)
        }
        try? context.save()
    }

    static func clearAllEntries(in context: ModelContext) {
        let descriptor = FetchDescriptor<DayEntry>()
        let entries = (try? context.fetch(descriptor)) ?? []
        entries.forEach(context.delete)
        try? context.save()
    }

    static func clearAllLocalData(
        entries: [DayEntry],
        actions: [ActionInstance],
        responses: [ActionResponse],
        letters: [TimeLetter],
        empathyCopies: [EmpathyCopy],
        in context: ModelContext
    ) {
        entries.forEach(context.delete)
        actions.forEach(context.delete)
        responses.forEach(context.delete)
        letters.forEach(context.delete)
        empathyCopies.forEach(context.delete)
        try? context.save()
    }

    static func seedSupportData(into context: ModelContext, now: Date = .now) {
        clearDemoSupportData(in: context)
        let fixtures: [(MicroAction, ActionResponseKind?)] = [
            (MicroActionCatalog.all[0], .moreSettled),
            (MicroActionCatalog.all[1], .unchanged),
            (MicroActionCatalog.all[5], .moreSettled),
            (MicroActionCatalog.all[2], nil)
        ]
        for (index, fixture) in fixtures.enumerated() {
            let completedAt = now.addingTimeInterval(Double(-(index + 1) * 86_400))
            let instance = ActionInstance(
                actionId: fixture.0.id,
                entryId: nil,
                actionTitle: fixture.0.title,
                category: fixture.0.category,
                createdAt: completedAt.addingTimeInterval(-300),
                startedAt: completedAt.addingTimeInterval(-240),
                completedAt: completedAt,
                followUpAt: fixture.1 == nil ? now.addingTimeInterval(-60) : completedAt.addingTimeInterval(10_800),
                state: .completed,
                isDemo: true
            )
            context.insert(instance)
            if let kind = fixture.1 {
                context.insert(ActionResponse(
                    actionInstanceId: instance.id,
                    kind: kind,
                    createdAt: completedAt.addingTimeInterval(10_900),
                    isDemo: true
                ))
            }
        }
        try? context.save()
    }

    static func clearDemoSupportData(in context: ModelContext) {
        let actionDescriptor = FetchDescriptor<ActionInstance>(predicate: #Predicate { $0.isDemo == true })
        let responseDescriptor = FetchDescriptor<ActionResponse>(predicate: #Predicate { $0.isDemo == true })
        ((try? context.fetch(actionDescriptor)) ?? []).forEach(context.delete)
        ((try? context.fetch(responseDescriptor)) ?? []).forEach(context.delete)
        try? context.save()
    }
}
