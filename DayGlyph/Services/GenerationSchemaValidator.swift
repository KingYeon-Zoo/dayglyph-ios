import Foundation

/// 生成契约的确定性语义校验（spec 第 6 节）。
///
/// 解码成功后再做范围、数量、词库合法性、禁止诊断词、风险冲突、视觉参数合法性等检查。
/// 任一硬性错误抛出 `GenerationValidationError`，触发修复性重试（仅一次）。
enum GenerationSchemaValidator {

    /// 禁止出现的诊断/绝对化措辞（spec 第 9 节：不做医疗诊断、人格判断或绝对结论）。
    static let forbiddenDiagnosticTerms: [String] = [
        "抑郁症", "焦虑症", "躁郁", "精神病", "心理疾病", "确诊", "病理",
        "人格障碍", "治愈", "疗效", "药物", "诊断", "你一定会", "永远不会", "注定"
    ]

    static let supportedSchemaVersions: Set<String> = ["1.0"]
    static let validRiskLevels: Set<String> = ["none", "low", "moderate", "medium", "high"]
    static let validDifficulties: Set<String> = ["easy", "medium"]

    static func validate(_ response: DayGenerationResponse) throws {
        try validateSchemaVersion(response.schemaVersion)
        try validateSafety(response.safety)
        try validateEmotions(response.emotionAnalysis)
        try validateDimensions(response.emotionAnalysis.dimensions)
        try validateSharedVisual(response.sharedVisualDirection)
        try validateCocktail(response.cocktail)
        try validatePlanet(response.planet)
        try validateDailyAction(response.dailyAction)
        try validateDailyMessage(response.dailyMessage)
        try validateWeather(response.emotionalWeather)
        try validateNoDiagnosticLanguage(response)
    }

    // MARK: - 各段校验

    private static func validateSchemaVersion(_ version: String) throws {
        guard supportedSchemaVersions.contains(version) else {
            throw GenerationValidationError.unsupportedSchemaVersion(version)
        }
    }

    private static func validateSafety(_ safety: SafetyAssessment) throws {
        guard validRiskLevels.contains(safety.riskLevel.lowercased()) else {
            throw GenerationValidationError.invalidValue("safety.risk_level", safety.riskLevel)
        }
    }

    private static func validateEmotions(_ payload: EmotionAnalysisPayload) throws {
        let emotions = payload.emotions
        guard (1...8).contains(emotions.count) else {
            throw GenerationValidationError.emotionCountOutOfRange(emotions.count)
        }

        var seenTerms = Set<String>()
        for item in emotions {
            guard !item.term.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw GenerationValidationError.emptyField("emotion.term")
            }
            guard EmotionFamily(rawValue: item.family) != nil else {
                throw GenerationValidationError.invalidValue("emotion.family", item.family)
            }
            try requireUnitRange("emotion.intensity", item.intensity)
            try requireUnitRange("emotion.confidence", item.confidence)
            guard !seenTerms.contains(item.term) else {
                throw GenerationValidationError.duplicateEmotion(item.term)
            }
            seenTerms.insert(item.term)
            // 标准情绪词必须在词库内；词库外的词应落在 other_emotions。
            guard EmotionLexicon.isValid(item.term) else {
                throw GenerationValidationError.termNotInLexicon(item.term)
            }
        }

        // other_emotions 校验（允许词库外，但仍需基本字段与范围）。
        for item in payload.otherEmotions {
            guard !item.term.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw GenerationValidationError.emptyField("other_emotion.term")
            }
            try requireUnitRange("other_emotion.intensity", item.intensity)
            try requireUnitRange("other_emotion.confidence", item.confidence)
        }

        guard payload.summary.count <= 120 else {
            throw GenerationValidationError.textTooLong("summary", payload.summary.count, 120)
        }
    }

    private static func validateDimensions(_ d: EmotionDimensions) throws {
        try requireSignedRange("dimensions.valence", d.valence)
        try requireUnitRange("dimensions.arousal", d.arousal)
        try requireSignedRange("dimensions.dominance", d.dominance)
        try requireUnitRange("dimensions.energy", d.energy)
        try requireUnitRange("dimensions.tension", d.tension)
        try requireUnitRange("dimensions.certainty", d.certainty)
        try requireUnitRange("dimensions.social_connection", d.socialConnection)
    }

    private static func validateSharedVisual(_ v: SharedVisualDirection) throws {
        guard (1...6).contains(v.palette.count) else {
            throw GenerationValidationError.arrayCountOutOfRange("shared_visual_direction.palette", v.palette.count, 1, 6)
        }
        for hex in v.palette {
            guard isHexColor(hex) else {
                throw GenerationValidationError.invalidValue("palette.color", hex)
            }
        }
        try requireUnitRange("shared_visual.contrast", v.contrast)
        try requireUnitRange("shared_visual.temperature", v.temperature)
        try requireUnitRange("shared_visual.light_softness", v.lightSoftness)
        try requireUnitRange("shared_visual.spatial_density", v.spatialDensity)
    }

    private static func validateCocktail(_ c: CocktailSpec) throws {
        try requireNonEmpty("cocktail.glass", c.glass)
        try requireNonEmpty("cocktail.glass_material", c.glassMaterial)
        guard (1...5).contains(c.liquidLayers.count) else {
            throw GenerationValidationError.arrayCountOutOfRange("cocktail.liquid_layers", c.liquidLayers.count, 1, 5)
        }
        for layer in c.liquidLayers where !isColorToken(layer.color) {
            throw GenerationValidationError.invalidValue("cocktail.liquid_layer.color", layer.color)
        }
        guard c.garnish.count <= 4 else {
            throw GenerationValidationError.arrayCountOutOfRange("cocktail.garnish", c.garnish.count, 0, 4)
        }
    }

    private static func validatePlanet(_ p: PlanetSpec) throws {
        try requireNonEmpty("planet.silhouette", p.silhouette)
        try requireNonEmpty("planet.surface.material", p.surface.material)
        guard p.rings.count <= 4 else {
            throw GenerationValidationError.arrayCountOutOfRange("planet.rings", p.rings.count, 0, 4)
        }
        guard p.satellites.count <= 4 else {
            throw GenerationValidationError.arrayCountOutOfRange("planet.satellites", p.satellites.count, 0, 4)
        }
    }

    private static func validateDailyAction(_ a: DailyActionSpec) throws {
        try requireNonEmpty("daily_action.title", a.title)
        try requireNonEmpty("daily_action.instruction", a.instruction)
        guard (1...120).contains(a.durationMinutes) else {
            throw GenerationValidationError.invalidValue("daily_action.duration_minutes", "\(a.durationMinutes)")
        }
        guard validDifficulties.contains(a.difficulty.lowercased()) else {
            throw GenerationValidationError.invalidValue("daily_action.difficulty", a.difficulty)
        }
    }

    private static func validateDailyMessage(_ m: DailyMessageSpec) throws {
        try requireNonEmpty("daily_message.text", m.text)
        guard m.text.count <= 80 else {
            throw GenerationValidationError.textTooLong("daily_message.text", m.text.count, 80)
        }
        // 统一署名，杜绝冒用真实人物名言。
        guard m.attribution.contains("DayGlyph") else {
            throw GenerationValidationError.invalidValue("daily_message.attribution", m.attribution)
        }
    }

    private static func validateWeather(_ w: EmotionalWeatherSpec) throws {
        try requireNonEmpty("emotional_weather.title", w.title)
        try requireNonEmpty("emotional_weather.symbol", w.symbol)
        guard w.explanation.count <= 80 else {
            throw GenerationValidationError.textTooLong("emotional_weather.explanation", w.explanation.count, 80)
        }
    }

    private static func validateNoDiagnosticLanguage(_ response: DayGenerationResponse) throws {
        let haystack = [
            response.emotionAnalysis.summary,
            response.dailyMessage.text,
            response.emotionalWeather.explanation,
            response.dailyAction.reason,
            response.safety.rationale
        ].joined(separator: " ")

        for term in forbiddenDiagnosticTerms where haystack.contains(term) {
            throw GenerationValidationError.forbiddenTerm(term)
        }
    }

    // MARK: - 基础工具

    private static func requireUnitRange(_ field: String, _ value: Double) throws {
        guard value.isFinite, (0.0...1.0).contains(value) else {
            throw GenerationValidationError.valueOutOfRange(field, value, 0, 1)
        }
    }

    private static func requireSignedRange(_ field: String, _ value: Double) throws {
        guard value.isFinite, (-1.0...1.0).contains(value) else {
            throw GenerationValidationError.valueOutOfRange(field, value, -1, 1)
        }
    }

    private static func requireNonEmpty(_ field: String, _ value: String) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GenerationValidationError.emptyField(field)
        }
    }

    private static func isHexColor(_ value: String) -> Bool {
        let s = value.hasPrefix("#") ? String(value.dropFirst()) : value
        guard s.count == 6 || s.count == 3 else { return false }
        return s.allSatisfy { $0.isHexDigit }
    }

    /// 液体层颜色既接受 hex，也接受英文色彩 token（如 amber、deep_blue）。
    private static func isColorToken(_ value: String) -> Bool {
        if isHexColor(value) { return true }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.count <= 32 else { return false }
        return trimmed.allSatisfy { $0.isLetter || $0 == "_" || $0 == " " || $0 == "-" }
    }
}

enum GenerationValidationError: LocalizedError, Equatable {
    case unsupportedSchemaVersion(String)
    case emotionCountOutOfRange(Int)
    case duplicateEmotion(String)
    case termNotInLexicon(String)
    case emptyField(String)
    case textTooLong(String, Int, Int)
    case valueOutOfRange(String, Double, Double, Double)
    case invalidValue(String, String)
    case arrayCountOutOfRange(String, Int, Int, Int)
    case forbiddenTerm(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let v): "不支持的 schema 版本：\(v)"
        case .emotionCountOutOfRange(let n): "情绪数量应为 1～8，实际 \(n)"
        case .duplicateEmotion(let t): "情绪项重复：\(t)"
        case .termNotInLexicon(let t): "情绪词不在受控词库内：\(t)"
        case .emptyField(let f): "字段为空：\(f)"
        case .textTooLong(let f, let n, let max): "\(f) 过长：\(n) 字，上限 \(max)"
        case .valueOutOfRange(let f, let v, let lo, let hi): "\(f) 超出范围 [\(lo), \(hi)]：\(v)"
        case .invalidValue(let f, let v): "\(f) 取值非法：\(v)"
        case .arrayCountOutOfRange(let f, let n, let lo, let hi): "\(f) 数量 \(n) 超出 [\(lo), \(hi)]"
        case .forbiddenTerm(let t): "出现禁止的诊断/绝对化措辞：\(t)"
        }
    }
}
