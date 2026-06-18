import Foundation

nonisolated struct UniverseDaySummary: Identifiable, Equatable {
    var id: UUID { entryID }

    var entryID: UUID
    var date: Date
    var cocktailName: String
    var weatherType: String
    var keywords: [String]
    var planet: PlanetVisual
    var recipeParts: [RecipePart]
    var arousal: Double
}

nonisolated struct MonthlyPlanetVisual: Equatable {
    var seed: Int
    var baseHue: Double
    var secondaryHue: Double
    var textureComplexity: Double
    var glow: Double
    var sizeScale: Double
    var rings: Int
    var satellites: Int
    var rotationSpeed: Double
    var recordDots: [Date]
}

nonisolated struct MonthlyUniverseSummary: Identifiable, Equatable {
    var id: Date { monthStart }

    var monthStart: Date
    var days: [UniverseDaySummary]
    var visual: MonthlyPlanetVisual
    var keywords: [String]
    var weatherTypes: [String: Int]
    var averageArousal: Double
    var arousalRange: ClosedRange<Double>

    var recordCount: Int { days.count }
}

nonisolated enum UniverseDateDirection {
    case previous
    case next
}
