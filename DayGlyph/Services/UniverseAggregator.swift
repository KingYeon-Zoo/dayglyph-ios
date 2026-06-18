import Foundation

enum UniverseAggregator {
    static func months(
        from entries: [DayEntry],
        calendar: Calendar = .current
    ) -> [MonthlyUniverseSummary] {
        let latestByDay = entries.reduce(into: [Date: DayEntry]()) { result, entry in
            let day = calendar.startOfDay(for: entry.date)
            if let existing = result[day], existing.updatedAt >= entry.updatedAt {
                return
            }
            result[day] = entry
        }

        let grouped = Dictionary(grouping: latestByDay.values) { entry in
            monthStart(containing: entry.date, calendar: calendar)
        }

        return grouped.keys.sorted().compactMap { monthStart in
            let monthEntries = (grouped[monthStart] ?? []).sorted { $0.date < $1.date }
            guard monthEntries.isEmpty == false else { return nil }
            return makeMonth(monthStart: monthStart, entries: monthEntries, calendar: calendar)
        }
    }

    private static func makeMonth(
        monthStart: Date,
        entries: [DayEntry],
        calendar: Calendar
    ) -> MonthlyUniverseSummary {
        let days = entries.map { entry in
            UniverseDaySummary(
                entryID: entry.entryID,
                date: calendar.startOfDay(for: entry.date),
                cocktailName: entry.emotionRecipe.name,
                weatherType: entry.moodWeather.type,
                keywords: entry.emotionRecipe.keywords,
                planet: entry.planetVisual,
                recipeParts: entry.emotionRecipe.parts,
                arousal: entry.arousal
            )
        }
        let arousalValues = days.map(\.arousal)
        let minimumArousal = arousalValues.min() ?? 0
        let maximumArousal = arousalValues.max() ?? 0
        let keywordCounts = counts(days.flatMap(\.keywords))
        let keywords = keywordCounts
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .prefix(5)
            .map(\.key)
        let planets = days.map(\.planet)
        let visual = MonthlyPlanetVisual(
            seed: stableSeed(monthStart: monthStart, days: days, calendar: calendar),
            baseHue: circularMean(planets.map(\.baseHue)),
            secondaryHue: circularMean(planets.map(\.secondaryHue)),
            textureComplexity: clamp(
                planets.map(\.textureComplexity).average,
                lower: 0.20,
                upper: 0.85
            ),
            glow: clamp(planets.map(\.glow).average, lower: 0.25, upper: 0.90),
            sizeScale: 0.88 + min(Double(days.count), 31) / 31 * 0.24,
            rings: min(Set(days.flatMap(\.recipeParts).dropFirst().map(\.anchor)).count, 3),
            satellites: min(keywordCounts.count, 3),
            rotationSpeed: 0.02 + Double(stableSeed(monthStart: monthStart, days: days, calendar: calendar) % 11) / 100,
            recordDots: days.map(\.date)
        )

        return MonthlyUniverseSummary(
            monthStart: monthStart,
            days: days,
            visual: visual,
            keywords: keywords,
            weatherTypes: counts(days.map(\.weatherType)),
            averageArousal: arousalValues.average,
            arousalRange: minimumArousal ... maximumArousal
        )
    }

    private static func monthStart(containing date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    private static func counts(_ values: [String]) -> [String: Int] {
        values.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    private static func circularMean(_ degrees: [Double]) -> Double {
        guard degrees.isEmpty == false else { return 0 }
        let radians = degrees.map { $0 * .pi / 180 }
        let x = radians.map(cos).reduce(0, +) / Double(radians.count)
        let y = radians.map(sin).reduce(0, +) / Double(radians.count)
        let result = atan2(y, x) * 180 / .pi
        return result < 0 ? result + 360 : result
    }

    private static func stableSeed(
        monthStart: Date,
        days: [UniverseDaySummary],
        calendar: Calendar
    ) -> Int {
        let components = calendar.dateComponents([.year, .month], from: monthStart)
        let parts = days.sorted { $0.date < $1.date }.map {
            "\(calendar.component(.day, from: $0.date)):\($0.planet.seed)"
        }
        let value = "\(components.year ?? 0)-\(components.month ?? 0)|\(parts.joined(separator: ","))"
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return max(Int(hash % UInt64(Int.max)), 1)
    }

    private static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard isEmpty == false else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
