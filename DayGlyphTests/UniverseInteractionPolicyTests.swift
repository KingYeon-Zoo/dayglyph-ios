import Foundation
import Testing
@testable import DayGlyph

struct UniverseInteractionPolicyTests {
    @Test func monthSwipeOnlyChangesMonthAfterDistanceOrVelocityThreshold() {
        #expect(UniverseInteractionPolicy.monthOffset(translation: 40, velocity: 120) == 0)
        #expect(UniverseInteractionPolicy.monthOffset(translation: -57, velocity: 120) == 1)
        #expect(UniverseInteractionPolicy.monthOffset(translation: 20, velocity: 381) == -1)
    }

    @Test func adjacentRecordedDateStopsAtMonthBoundaries() throws {
        let calendar = Calendar(identifier: .gregorian)
        let dates = [
            try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 2))),
            try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 8))),
            try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 18)))
        ]

        #expect(UniverseInteractionPolicy.adjacentDate(to: dates[0], direction: .previous, in: dates) == nil)
        #expect(UniverseInteractionPolicy.adjacentDate(to: dates[0], direction: .next, in: dates) == dates[1])
        #expect(UniverseInteractionPolicy.adjacentDate(to: dates[2], direction: .next, in: dates) == nil)
    }
}
