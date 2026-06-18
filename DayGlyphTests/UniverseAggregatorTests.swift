import Foundation
import Testing
@testable import DayGlyph

struct UniverseAggregatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    @Test func groupsEntriesByMonthAndKeepsLatestEntryForEachDay() throws {
        let june30 = try date(year: 2026, month: 6, day: 30)
        let july1 = try date(year: 2026, month: 7, day: 1)
        let older = makeEntry(date: june30, text: "较早记录", updatedAt: june30)
        let newer = makeEntry(
            date: june30,
            text: "当天更新后的记录",
            updatedAt: june30.addingTimeInterval(60)
        )
        let july = makeEntry(date: july1, text: "七月记录", updatedAt: july1)

        let months = UniverseAggregator.months(
            from: [older, july, newer],
            calendar: calendar
        )

        #expect(months.count == 2)
        let june = try #require(months.first)
        let julyMonth = try #require(months.dropFirst().first)
        #expect(june.days.count == 1)
        #expect(june.days[0].entryID == newer.entryID)
        #expect(julyMonth.days[0].entryID == july.entryID)
    }

    @Test func monthlyVisualIsStableAndUsesCircularHueAveraging() throws {
        let first = makeEntry(date: try date(year: 2026, month: 6, day: 2), text: "第一天")
        let second = makeEntry(date: try date(year: 2026, month: 6, day: 8), text: "第二天")
        first.applyVisuals(visuals(for: first, baseHue: 350, secondaryHue: 20))
        second.applyVisuals(visuals(for: second, baseHue: 10, secondaryHue: 40))

        let firstResult = try #require(
            UniverseAggregator.months(from: [first, second], calendar: calendar).first
        )
        let secondResult = try #require(
            UniverseAggregator.months(from: [second, first], calendar: calendar).first
        )

        #expect(firstResult.visual == secondResult.visual)
        #expect(firstResult.visual.seed > 0)
        #expect(firstResult.visual.baseHue < 20 || firstResult.visual.baseHue > 340)
    }

    @Test func monthlyVisualValuesStayInsideProductBounds() throws {
        let entry = makeEntry(date: try date(year: 2026, month: 6, day: 18), text: "边界记录")
        entry.applyVisuals(visuals(for: entry, complexity: 1.8, glow: -1))

        let month = try #require(
            UniverseAggregator.months(from: [entry], calendar: calendar).first
        )

        #expect((0.20 ... 0.85).contains(month.visual.textureComplexity))
        #expect((0.25 ... 0.90).contains(month.visual.glow))
        #expect((0.88 ... 1.12).contains(month.visual.sizeScale))
        #expect(month.visual.recordDots.count == 1)
    }

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func makeEntry(
        date: Date,
        text: String,
        updatedAt: Date? = nil
    ) -> DayEntry {
        DayEntry(
            date: date,
            text: text,
            analysis: EmotionAnalysis(
                valence: 0.2,
                arousal: 0.5,
                dominance: 0.1,
                emotionWeights: [
                    EmotionWeight(anchor: .calm, value: 0.7),
                    EmotionWeight(anchor: .joy, value: 0.3)
                ],
                theme: .rest,
                keywords: ["呼吸", "傍晚"],
                confidence: 0.8,
                explanation: "测试记录",
                source: .demoFixture
            ),
            glyphSeed: 1,
            createdAt: date,
            updatedAt: updatedAt ?? date
        )
    }

    private func visuals(
        for entry: DayEntry,
        baseHue: Double = 220,
        secondaryHue: Double = 260,
        complexity: Double = 0.5,
        glow: Double = 0.6
    ) -> EntryVisuals {
        EntryVisuals(
            recipe: entry.emotionRecipe,
            cocktail: entry.cocktailVisual,
            planet: PlanetVisual(
                seed: entry.planetVisual.seed,
                baseHue: baseHue,
                secondaryHue: secondaryHue,
                textureComplexity: complexity,
                glow: glow,
                rings: 2,
                satellites: 1,
                rotationSpeed: 0.05
            ),
            weather: entry.moodWeather,
            visualVersion: 1
        )
    }
}
