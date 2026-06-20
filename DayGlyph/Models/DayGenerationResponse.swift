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

    // MARK: - 即时情境个性化扩展（contextual personalization spec 第 5 节）
    //
    // 以下字段全部可选：任一缺失或非法都不得阻塞核心情绪 + 双图结果（spec 第 10 节）。
    // 解码层只做结构化；合法性与降级由 `GenerationExtrasValidator` 非抛错清洗。

    /// 双图生成阶段的过程文案（spec 5.1）。缺失时客户端用固定阶段文案。
    var experienceCopy: ExperienceCopySpec?
    /// 结果叙事：连接情绪分析与双图视觉的命名与解释（spec 5.2）。
    var resultNarrative: ResultNarrativeSpec?
    /// 轻量 / 标准 / 主动三档微行动（spec 5.3）。必须恰好三档且档位唯一，否则整组丢弃回退本地目录。
    var actionOptions: [ActionOptionSpec]?
    /// 当日分享卡内容规格（spec 5.4）。AI 只给内容，不控制像素排版。
    var shareCard: ShareCardSpec?

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
        case experienceCopy = "experience_copy"
        case resultNarrative = "result_narrative"
        case actionOptions = "action_options"
        case shareCard = "share_card"
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

// MARK: - 即时情境个性化扩展规格（contextual personalization spec 第 5 节）

/// 过程文案（spec 5.1）：只描述正在进行的生成动作，不声称知道未表达的原因、不显示虚假百分比。
nonisolated struct ExperienceCopySpec: Codable, Equatable, Sendable {
    var imageGenerationTitle: String
    var cocktailProgress: String
    var planetProgress: String

    enum CodingKeys: String, CodingKey {
        case imageGenerationTitle = "image_generation_title"
        case cocktailProgress = "cocktail_progress"
        case planetProgress = "planet_progress"
    }
}

/// 结果叙事（spec 5.2）：鸡尾酒名与星球名同语义方向但不相同；标题表达当下状态，不写成稳定人格。
nonisolated struct ResultNarrativeSpec: Codable, Equatable, Sendable {
    var cocktailName: String
    var planetName: String
    var headline: String
    var explanation: String

    enum CodingKeys: String, CodingKey {
        case cocktailName = "cocktail_name"
        case planetName = "planet_name"
        case headline
        case explanation
    }
}

/// 三档微行动之一（spec 5.3）。`level` 必须为 light / standard / active，三档差异真实。
nonisolated struct ActionOptionSpec: Codable, Equatable, Sendable {
    /// 档位：light / standard / active。
    var level: String
    var title: String
    var instruction: String
    var durationMinutes: Int
    /// 难度 1～5。
    var difficulty: Int
    /// 环境标签，如 ["室内", "独处"]。
    var environment: [String]
    var reason: String
    /// 仅针对该行动的回声问题（spec 5.3、第 9 节）。
    var echoQuestion: String

    enum CodingKeys: String, CodingKey {
        case level, title, instruction
        case durationMinutes = "duration_minutes"
        case difficulty, environment, reason
        case echoQuestion = "echo_question"
    }
}

/// 当日分享卡内容规格（spec 5.4）。`visual_focus` / `layout_variant` / `privacy_level` 来自受控枚举。
nonisolated struct ShareCardSpec: Codable, Equatable, Sendable {
    var title: String
    var caption: String
    /// 主视觉：cocktail / planet。
    var visualFocus: String
    /// 版式：portrait_centered / square_centered / minimal。
    var layoutVariant: String
    /// 隐私层级：emotion_only（默认仅情绪向）。
    var privacyLevel: String

    enum CodingKeys: String, CodingKey {
        case title, caption
        case visualFocus = "visual_focus"
        case layoutVariant = "layout_variant"
        case privacyLevel = "privacy_level"
    }
}
