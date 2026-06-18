nonisolated enum UniverseRenderingMode: Equatable {
    case realityKit
    case accessible2D
}

enum UniverseRenderingPolicy {
    static func mode(
        voiceOver: Bool,
        reduceMotion: Bool,
        lowPower: Bool,
        sceneFailed: Bool
    ) -> UniverseRenderingMode {
        if voiceOver || reduceMotion || lowPower || sceneFailed {
            return .accessible2D
        }
        return .realityKit
    }
}
