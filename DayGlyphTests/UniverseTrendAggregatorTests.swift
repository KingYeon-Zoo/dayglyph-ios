import Foundation
import Testing
@testable import DayGlyph

struct UniverseTrendAggregatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    @Test func monthQuarterAndYearUseCalendarBoundaries() throws {
        let entries = [
            makeEntry(date: try date(2026, 3, 31), anchor: .calm),
            makeEntry(date: try date(2026, 4, 1), anchor: .joy),
            makeEntry(date: try date(2026, 6, 18), anchor: .anxious),
            makeEntry(date: try date(2026, 7, 1), anchor: .proud)
        ]
        let anchor = try date(2026, 6, 18)

        let month = UniverseTrendAggregator.summary(from: entries, anchorDate: anchor, range: .month, calendar: calendar)
        let quarter = UniverseTrendAggregator.summary(from: entries, anchorDate: anchor, range: .quarter, calendar: calendar)
        let year = UniverseTrendAggregator.summary(from: entries, anchorDate: anchor, range: .year, calendar: calendar)

        #expect(month.recordDayCount == 1)
        #expect(quarter.recordDayCount == 2)
        #expect(year.recordDayCount == 4)
    }

    @Test func fewerThanSevenDaysNeverProducesPatternSummary() throws {
        let anchor = try date(2026, 6, 18)
        let entries = (1 ... 6).map {
            makeEntry(date: try! date(2026, 6, $0), anchor: .calm)
        }

        let summary = UniverseTrendAggregator.summary(
            from: entries,
            anchorDate: anchor,
            range: .month,
            calendar: calendar
        )

        #expect(summary.hasEnoughDataForPatterns == false)
        #expect(summary.guidance == "至少记录 7 天后显示趋势")
    }

    @Test func emotionCompositionIsNormalizedAndExportMetadataStatesItsSource() throws {
        let anchor = try date(2026, 6, 18)
        let entries = (1 ... 8).map { day in
            makeEntry(
                date: try! date(2026, 6, day),
                anchor: day.isMultiple(of: 2) ? .joy : .calm
            )
        }
        let summary = UniverseTrendAggregator.summary(
            from: entries,
            anchorDate: anchor,
            range: .month,
            calendar: calendar
        )
        let metadata = UniverseExportMetadata(summary: summary, calendar: calendar)

        #expect(abs(summary.emotionComposition.reduce(0) { $0 + $1.proportion } - 1) < 0.0001)
        #expect(summary.hasEnoughDataForPatterns)
        #expect(metadata.sourceNotice == "仅基于你的记录")
        #expect(metadata.sampleDescription.contains("8 个记录日"))
        #expect(metadata.sampleDescription.contains("2026年6月1日"))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func makeEntry(date: Date, anchor: EmotionVisualAnchor) -> DayEntry {
        let legacyAnchor: EmotionAnchor = switch anchor {
        case .joy: .joy
        case .calm: .calm
        case .anxious: .anxious
        case .proud: .excited
        default: .confused
        }
        return DayEntry(
            date: date,
            text: "趋势测试 \(date.timeIntervalSince1970)",
            analysis: EmotionAnalysis(
                valence: 0.2,
                arousal: 0.5,
                dominance: 0.1,
                emotionWeights: [EmotionWeight(anchor: legacyAnchor, value: 1)],
                theme: .rest,
                keywords: [anchor.title],
                confidence: 0.8,
                explanation: "测试",
                source: .demoFixture
            ),
            glyphSeed: 1,
            createdAt: date,
            updatedAt: date
        )
    }
}
