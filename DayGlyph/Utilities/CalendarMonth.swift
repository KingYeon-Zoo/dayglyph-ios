import Foundation

struct CalendarDay: Identifiable, Equatable {
    var date: Date
    var isInDisplayedMonth: Bool
    var dayNumber: Int

    var id: Date { date }
}

struct CalendarMonth: Equatable {
    var displayedMonth: Date
    var days: [CalendarDay]

    init(containing date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstOfMonth = calendar.date(from: components) ?? calendar.startOfDay(for: date)
        self.displayedMonth = firstOfMonth

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingDays = (weekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: firstOfMonth) ?? firstOfMonth
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<31
        let total = max(35, Int(ceil(Double(leadingDays + range.count) / 7.0)) * 7)

        self.days = (0..<total).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            let isSameMonth = calendar.component(.month, from: day) == calendar.component(.month, from: firstOfMonth)
                && calendar.component(.year, from: day) == calendar.component(.year, from: firstOfMonth)
            return CalendarDay(
                date: calendar.startOfDay(for: day),
                isInDisplayedMonth: isSameMonth,
                dayNumber: calendar.component(.day, from: day)
            )
        }
    }

    func addingMonths(_ value: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }
}
