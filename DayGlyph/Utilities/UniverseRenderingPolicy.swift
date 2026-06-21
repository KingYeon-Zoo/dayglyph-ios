nonisolated enum UniverseRenderingMode: Equatable {
    case starMap
    case accessible2D
}

enum UniverseRenderingPolicy {
    static func mode(
        voiceOver: Bool,
        lowPower: Bool
    ) -> UniverseRenderingMode {
        if voiceOver || lowPower {
            return .accessible2D
        }
        return .starMap
    }
}
