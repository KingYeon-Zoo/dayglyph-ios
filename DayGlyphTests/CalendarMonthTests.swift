import Foundation
import Testing
@testable import DayGlyph

struct CalendarMonthTests {
    @Test func monthGridContainsAtLeastOneFullCalendarPage() throws {
        let calendar = Calendar(identifier: .gregorian)
        let june2026 = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 8)))
        let month = CalendarMonth(containing: june2026, calendar: calendar)

        #expect(month.days.count >= 35)
        #expect(month.days.count.isMultiple(of: 7))
        #expect(month.days.contains { $0.dayNumber == 8 && $0.isInDisplayedMonth })
    }
}
