import Foundation

enum EmotionVisualAnchor: String, CaseIterable, Codable, Equatable, Hashable, Identifiable {
    case joy
    case calm
    case anticipation
    case moved
    case proud
    case tired
    case sad
    case anxious
    case angry
    case lonely
    case confused
    case numb

    var id: String { rawValue }

    var title: String {
        switch self {
        case .joy: "喜悦"
        case .calm: "平静"
        case .anticipation: "期待"
        case .moved: "感动"
        case .proud: "自豪"
        case .tired: "疲惫"
        case .sad: "难过"
        case .anxious: "焦虑"
        case .angry: "愤怒"
        case .lonely: "孤独"
        case .confused: "困惑"
        case .numb: "麻木"
        }
    }

    static func map(from anchor: EmotionAnchor) -> EmotionVisualAnchor {
        switch anchor {
        case .calm, .relief: .calm
        case .joy: .joy
        case .grateful: .moved
        case .hopeful: .anticipation
        case .excited: .proud
        case .angry: .angry
        case .anxious: .anxious
        case .sad: .sad
        case .tired: .tired
        case .lonely: .lonely
        case .confused: .confused
        }
    }
}

struct EntryVisuals: Codable, Equatable {
    var recipe: EmotionRecipe
    var cocktail: CocktailVisual
    var planet: PlanetVisual
    var weather: MoodWeather
    var visualVersion: Int
}

struct EmotionRecipe: Codable, Equatable {
    var primary: EmotionVisualAnchor
    var secondary: [EmotionVisualAnchor]
    var parts: [RecipePart]
    var keywords: [String]
    var confidenceBand: ConfidenceBand
    var name: String
    var supportCopy: String
}

struct RecipePart: Codable, Equatable, Identifiable {
    var anchor: EmotionVisualAnchor
    var parts: Int

    var id: EmotionVisualAnchor { anchor }
}

enum ConfidenceBand: String, Codable, Equatable {
    case low
    case medium
    case high
}

struct CocktailVisual: Codable, Equatable {
    var glassType: String
    var liquidLayers: [String]
    var bubbleLevel: Double
    var garnish: String
    var backgroundSeed: Int
}

struct PlanetVisual: Codable, Equatable {
    var seed: Int
    var baseHue: Double
    var secondaryHue: Double
    var textureComplexity: Double
    var glow: Double
    var rings: Int
    var satellites: Int
    var rotationSpeed: Double
}

struct MoodWeather: Codable, Equatable {
    var type: String
    var intensityBand: String
    var animationSeed: Int
    var explanation: String
}
