import Foundation

enum UniverseInteractionPolicy {
    static func monthOffset(translation: Double, velocity: Double) -> Int {
        let shouldMove = abs(translation) >= 56 || abs(velocity) > 380
        guard shouldMove else { return 0 }
        let direction = abs(translation) >= 1 ? translation : velocity
        return direction < 0 ? 1 : -1
    }

    static func adjacentDate(
        to date: Date,
        direction: UniverseDateDirection,
        in dates: [Date]
    ) -> Date? {
        let sorted = dates.sorted()
        guard let index = sorted.firstIndex(of: date) else { return nil }
        switch direction {
        case .previous:
            guard index > sorted.startIndex else { return nil }
            return sorted[sorted.index(before: index)]
        case .next:
            let nextIndex = sorted.index(after: index)
            guard nextIndex < sorted.endIndex else { return nil }
            return sorted[nextIndex]
        }
    }
}
