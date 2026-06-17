import Foundation
import Testing
@testable import DayGlyph

struct EmotionVisualFactoryTests {
    @Test func recipeIsStableForSameAnalysisDateAndText() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 17)))
        let analysis = EmotionAnalysis(
            valence: 0.62,
            arousal: 0.44,
            dominance: 0.32,
            emotionWeights: [
                EmotionWeight(anchor: .joy, value: 0.62),
                EmotionWeight(anchor: .calm, value: 0.28),
                EmotionWeight(anchor: .tired, value: 0.10)
            ],
            theme: .rest,
            keywords: ["散步", "安静"],
            confidence: 0.82,
            explanation: "轻松和安静更明显。",
            source: .localRules
        )

        let first = EmotionVisualFactory.makeVisuals(
            text: "傍晚散步后轻松了一点。",
            date: date,
            analysis: analysis,
            calendar: calendar
        )
        let second = EmotionVisualFactory.makeVisuals(
            text: "傍晚散步后轻松了一点。",
            date: date,
            analysis: analysis,
            calendar: calendar
        )

        #expect(first.recipe == second.recipe)
        #expect(first.cocktail == second.cocktail)
        #expect(first.planet == second.planet)
        #expect(first.weather == second.weather)
        #expect(first.recipe.primary == .joy)
        #expect(first.recipe.parts.reduce(0) { $0 + $1.parts } == 10)
        #expect(first.recipe.parts.count <= 3)
    }

    @Test func legacyEmotionAnchorsMapToProductVisualAnchors() {
        #expect(EmotionVisualAnchor.map(from: .hopeful) == .anticipation)
        #expect(EmotionVisualAnchor.map(from: .grateful) == .moved)
        #expect(EmotionVisualAnchor.map(from: .excited) == .proud)
        #expect(EmotionVisualAnchor.map(from: .relief) == .calm)
    }
}
