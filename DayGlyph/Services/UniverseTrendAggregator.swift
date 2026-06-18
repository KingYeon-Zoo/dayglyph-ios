import Foundation

enum UniverseTrendAggregator {
    static func summary(
        from entries: [DayEntry],
        anchorDate: Date,
        range: UniverseTrendRange,
        calendar: Calendar = .current
    ) -> UniverseTrendSummary {
        let interval = dateInterval(for: range, anchorDate: anchorDate, calendar: calendar)
        let days = UniverseAggregator.months(from: entries, calendar: calendar)
            .flatMap(\.days)
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .sorted { $0.date < $1.date }

        let recipeParts: [RecipePart] = days.flatMap { day in
            day.recipeParts
        }
        var partCounts: [EmotionVisualAnchor: Double] = [:]
        for part in recipeParts {
            partCounts[part.anchor, default: 0] += Double(part.parts)
        }
        let totalParts = partCounts.values.reduce(0, +)
        var composition: [UniverseEmotionComposition] = []
        for (anchor, parts) in partCounts {
            let proportion = totalParts > 0 ? parts / totalParts : 0
            composition.append(
                UniverseEmotionComposition(anchor: anchor, proportion: proportion)
            )
        }
        composition.sort { lhs, rhs in
            if lhs.proportion == rhs.proportion {
                return lhs.anchor.rawValue < rhs.anchor.rawValue
            }
            return lhs.proportion > rhs.proportion
        }
        let keywordCounts = counts(days.flatMap(\.keywords))
        let arousalValues = days.map(\.arousal)

        return UniverseTrendSummary(
            range: range,
            startDate: interval.start,
            endDate: interval.end.addingTimeInterval(-1),
            days: days,
            emotionComposition: composition,
            weatherTypes: counts(days.map(\.weatherType)),
            keywords: keywordCounts
                .sorted { lhs, rhs in
                    lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
                }
                .prefix(8)
                .map(\.key),
            arousalRange: (arousalValues.min() ?? 0) ... (arousalValues.max() ?? 0)
        )
    }

    private static func dateInterval(
        for range: UniverseTrendRange,
        anchorDate: Date,
        calendar: Calendar
    ) -> DateInterval {
        switch range {
        case .month:
            return calendar.dateInterval(of: .month, for: anchorDate)
                ?? DateInterval(start: anchorDate, duration: 0)
        case .year:
            return calendar.dateInterval(of: .year, for: anchorDate)
                ?? DateInterval(start: anchorDate, duration: 0)
        case .quarter:
            let components = calendar.dateComponents([.year, .month], from: anchorDate)
            let month = components.month ?? 1
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            let start = calendar.date(
                from: DateComponents(year: components.year, month: quarterStartMonth, day: 1)
            ) ?? anchorDate
            let end = calendar.date(byAdding: .month, value: 3, to: start) ?? start
            return DateInterval(start: start, end: end)
        }
    }

    private static func counts(_ values: [String]) -> [String: Int] {
        values.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }
}
