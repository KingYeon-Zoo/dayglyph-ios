import Foundation

/// 豆包统一生成响应契约（spec 第 5 节）。
///
/// 一次 Seed 2.0 Lite 调用返回统一 JSON，不拆分多个文本智能体。
/// 字段命名与 spec 的 JSON 示例严格对应（snake_case 经 CodingKeys 映射）。
/// 所有数值范围、数量、词库合法性等语义约束由 `GenerationSchemaValidator` 校验，
/// 本类型只负责结构化解码。
nonisolated struct DayGenerationResponse: Codable, Equatable, Sendable {
    var schemaVersion: String
    var requestID: String
    var safety: SafetyAssessment
    var emotionAnalysis: EmotionAnalysisPayload
    var sharedVisualDirection: SharedVisualDirection
    var cocktail: CocktailSpec
    var planet: PlanetSpec
    var dailyAction: DailyActionSpec
    var dailyMessage: DailyMessageSpec
    var emotionalWeather: EmotionalWeatherSpec

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case requestID = "request_id"
        case safety
        case emotionAnalysis = "emotion_analysis"
        case sharedVisualDirection = "shared_visual_direction"
        case cocktail
        case planet
        case dailyAction = "daily_action"
        case dailyMessage = "daily_message"
        case emotionalWeather = "emotional_weather"
    }
}

// MARK: - 安全（spec 第 9 节）

nonisolated struct SafetyAssessment: Codable, Equatable, Sendable {
    /// AI 风险判断：none / moderate / high。明确高风险时暂停艺术生图。
    var riskLevel: String
    /// 是否检测到自伤、自杀或即时危险。
    var crisisDetected: Bool
    /// 给客户端的简短说明（不诊断、不绝对化）。
    var rationale: String

    enum CodingKeys: String, CodingKey {
        case riskLevel = "risk_level"
        case crisisDetected = "crisis_detected"
        case rationale
    }

    var isHighRisk: Bool {
        crisisDetected || riskLevel.lowercased() == "high"
    }
}

// MARK: - 情绪分析（spec 5.1）

nonisolated struct EmotionAnalysisPayload: Codable, Equatable, Sendable {
    var emotions: [EmotionItem]
    var otherEmotions: [EmotionItem]
    var dimensions: EmotionDimensions
    var relationships: [EmotionRelationship]
    var summary: String
    var uncertainties: [String]

    enum CodingKeys: String, CodingKey {
        case emotions
        case otherEmotions = "other_emotions"
        case dimensions
        case relationships
        case summary
        case uncertainties
    }
}

nonisolated struct EmotionItem: Codable, Equatable, Sendable {
    /// 标准心理词；词库外补充时落在 other_emotions。
    var term: String
    /// 内部情绪族 raw value（EmotionFamily）。
    var family: String
    var intensity: Double
    var confidence: Double
    /// 基于原文的简短依据。
    var evidence: String
}

nonisolated struct EmotionDimensions: Codable, Equatable, Sendable {
    var valence: Double
    var arousal: Double
    var dominance: Double
    var energy: Double
    var tension: Double
    var certainty: Double
    var socialConnection: Double

    enum CodingKeys: String, CodingKey {
        case valence, arousal, dominance, energy, tension, certainty
        case socialConnection = "social_connection"
    }
}

nonisolated struct EmotionRelationship: Codable, Equatable, Sendable {
    var from: String
    var to: String
    /// 关系类型，如 masks / amplifies / conflicts。
    var kind: String
}

// MARK: - 视觉规格（spec 5.2）

nonisolated struct SharedVisualDirection: Codable, Equatable, Sendable {
    var palette: [String]
    var contrast: Double
    var temperature: Double         // 0 冷 … 1 暖
    var lightSoftness: Double       // 0 硬光 … 1 柔光
    var spatialDensity: Double      // 0 极简 … 1 密集
    var motionImpression: String
    var symbols: [String]

    enum CodingKeys: String, CodingKey {
        case palette, contrast, temperature
        case lightSoftness = "light_softness"
        case spatialDensity = "spatial_density"
        case motionImpression = "motion_impression"
        case symbols
    }
}

nonisolated struct CocktailSpec: Codable, Equatable, Sendable {
    /// 仅用于 UI，不进入生图提示词。
    var name: String
    var description: String
    var glass: String               // 杯型
    var glassMaterial: String       // 杯身材质
    var liquidLayers: [LiquidLayer] // 受限数组
    var garnish: [String]
    var particles: String
    var lighting: String
    var camera: String
    var background: String
    var composition: String

    enum CodingKeys: String, CodingKey {
        case name, description, glass
        case glassMaterial = "glass_material"
        case liquidLayers = "liquid_layers"
        case garnish, particles, lighting, camera, background, composition
    }
}

nonisolated struct LiquidLayer: Codable, Equatable, Sendable {
    var color: String
    /// 边界风格，如 soft_diffusion / sharp。
    var boundaryStyle: String

    enum CodingKeys: String, CodingKey {
        case color
        case boundaryStyle = "boundary_style"
    }
}

nonisolated struct PlanetSpec: Codable, Equatable, Sendable {
    var name: String
    var description: String
    var silhouette: String          // 轮廓
    var surface: PlanetSurface      // 表面
    var core: String                // 核心
    var atmosphere: String          // 大气层
    var rings: [String]             // 环带（受限数组）
    var satellites: [String]        // 伴星（受限数组）
    var particles: String
    var lighting: String
    var camera: String
    var background: String
    var composition: String
}

nonisolated struct PlanetSurface: Codable, Equatable, Sendable {
    /// 表面材质，如 translucent_mineral。
    var material: String
    var detail: String
}

// MARK: - 支持内容（spec 5.3）

nonisolated struct DailyActionSpec: Codable, Equatable, Sendable {
    var title: String
    /// 明确指令；必须低压力、具体、可跳过。
    var instruction: String
    var durationMinutes: Int
    /// 难度：easy / medium。
    var difficulty: String
    /// 环境，如 indoor / outdoor / anywhere。
    var environment: String
    var reason: String

    enum CodingKeys: String, CodingKey {
        case title, instruction
        case durationMinutes = "duration_minutes"
        case difficulty, environment, reason
    }
}

nonisolated struct DailyMessageSpec: Codable, Equatable, Sendable {
    var text: String
    /// AI 原创内容统一署名“DayGlyph 今日寄语”，不得冒用真实人物名言。
    var attribution: String
}

nonisolated struct EmotionalWeatherSpec: Codable, Equatable, Sendable {
    var title: String
    var explanation: String
    /// 符号，如 partly_cloudy / clear / drizzle。
    var symbol: String
}
