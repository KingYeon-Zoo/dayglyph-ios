import Foundation
import Testing
@testable import DayGlyph

struct UniverseRenderingPolicyTests {
    @Test func accessibilityAndLowPowerUseTheTwoDimensionalPath() {
        #expect(UniverseRenderingPolicy.mode(voiceOver: true, lowPower: false) == .accessible2D)
        #expect(UniverseRenderingPolicy.mode(voiceOver: false, lowPower: true) == .accessible2D)
    }

    @Test func ordinaryEnvironmentUsesStarMap() {
        #expect(UniverseRenderingPolicy.mode(voiceOver: false, lowPower: false) == .starMap)
    }
}

struct StarMapLayoutTests {
    private func date(_ day: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: 2026, month: 6, day: day))!
    }

    @Test func placesOneStarPerRecordedDay() {
        let dates = [date(2), date(8), date(18), date(25)]
        let placements = StarMapLayout.placements(dates: dates, seed: 42)
        #expect(placements.count == dates.count)
        #expect(Set(placements.map(\.date)) == Set(dates))
    }

    @Test func layoutIsDeterministicForSameSeedAndDates() {
        let dates = [date(2), date(8), date(18)]
        let first = StarMapLayout.placements(dates: dates, seed: 42)
        let second = StarMapLayout.placements(dates: dates, seed: 42)
        #expect(first == second)
    }

    @Test func everyStarStaysWithinCanvasBounds() {
        let dates = (1 ... 28).map { date($0) }
        let placements = StarMapLayout.placements(dates: dates, seed: 7)
        #expect(placements.allSatisfy { $0.unitPosition.x >= 0 && $0.unitPosition.x <= 1 })
        #expect(placements.allSatisfy { $0.unitPosition.y >= 0 && $0.unitPosition.y <= 1 })
    }

    @Test func emptyInputProducesNoPlacements() {
        #expect(StarMapLayout.placements(dates: [], seed: 1).isEmpty)
    }
}
