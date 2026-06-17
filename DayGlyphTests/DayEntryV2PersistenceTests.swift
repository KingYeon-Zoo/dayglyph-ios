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

    @Test func updatingSameDayRefreshesV2Visuals() throws {
        let container = try ModelContainer(
            for: DayEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 17)))

        let firstAnalysis = EmotionAnalysis(
            valence: 0.48,
            arousal: 0.36,
            dominance: 0.28,
            emotionWeights: [EmotionWeight(anchor: .calm, value: 1)],
            theme: .rest,
            keywords: ["散步"],
            confidence: 0.8,
            explanation: "平静更明显。",
            source: .localRules
        )
        let secondAnalysis = EmotionAnalysis(
            valence: -0.68,
            arousal: 0.82,
            dominance: -0.44,
            emotionWeights: [EmotionWeight(anchor: .anxious, value: 1)],
            theme: .work,
            keywords: ["汇报"],
            confidence: 0.76,
            explanation: "紧张感更明显。",
            source: .localRules
        )

        let first = try DayEntryStore.saveEntry(
            text: "傍晚很安静。",
            date: date,
            analysis: firstAnalysis,
            context: context,
            calendar: calendar
        )
        let firstSeed = first.planetVisual.seed

        let updated = try DayEntryStore.saveEntry(
            text: "明天要公开汇报，脑子停不下来。",
            date: date,
            analysis: secondAnalysis,
            context: context,
            calendar: calendar
        )

        #expect(updated.visualVersion == 1)
        #expect(updated.emotionRecipe.primary == .anxious)
        #expect(updated.moodWeather.type == "阵雨")
        #expect(updated.planetVisual.seed != firstSeed)
    }
}
