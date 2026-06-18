import Foundation

nonisolated struct UniverseSceneDotDescriptor: Equatable {
    var date: Date
    var entityName: String
    var position: SIMD3<Float>
    var hitRadius: Float
}

nonisolated struct UniverseSceneDescriptor: Equatable {
    var seed: Int
    var baseHue: Double
    var secondaryHue: Double
    var sizeScale: Double
    var glow: Double
    var rings: Int
    var satellites: Int
    var rotationSpeed: Double
    var recordDots: [UniverseSceneDotDescriptor]

    static func make(
        visual: MonthlyPlanetVisual,
        calendar: Calendar = .current
    ) -> UniverseSceneDescriptor {
        let dots = visual.recordDots.sorted().enumerated().map { index, date in
            let count = max(visual.recordDots.count, 1)
            let longitude = Double(index) / Double(count) * 2 * Double.pi
            let latitude = Double((index * 47 + visual.seed) % 120 - 60) * Double.pi / 180
            let radius: Float = Float(1.03 * visual.sizeScale)
            let position = SIMD3<Float>(
                radius * Float(cos(latitude) * cos(longitude)),
                radius * Float(sin(latitude)),
                radius * Float(cos(latitude) * sin(longitude))
            )
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            let name = "day-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
            return UniverseSceneDotDescriptor(
                date: date,
                entityName: name,
                position: position,
                hitRadius: 0.14
            )
        }

        return UniverseSceneDescriptor(
            seed: visual.seed,
            baseHue: visual.baseHue,
            secondaryHue: visual.secondaryHue,
            sizeScale: visual.sizeScale,
            glow: visual.glow,
            rings: visual.rings,
            satellites: visual.satellites,
            rotationSpeed: visual.rotationSpeed,
            recordDots: dots
        )
    }
}
