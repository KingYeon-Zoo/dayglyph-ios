import Foundation
import FoundationModels

protocol FoundationEmotionAnalyzing: Sendable {
    func analyze(_ text: String) async throws -> EmotionAnalysis
}

enum FoundationEmotionAnalyzerError: LocalizedError, Equatable {
    case unavailable(String)
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason): reason
        case .invalidOutput: "Apple Intelligence 返回了无法使用的分析结果。"
        }
    }
}

struct FoundationEmotionAnalyzer: FoundationEmotionAnalyzing {
    func analyze(_ text: String) async throws -> EmotionAnalysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FoundationEmotionAnalyzerError.invalidOutput
        }

        let status = AppleIntelligenceStatus.current
        guard status.canUseFoundationModels else {
            throw FoundationEmotionAnalyzerError.unavailable(status.detail)
        }

        let model = SystemLanguageModel.default
        let session = LanguageModelSession(
            model: model,
            instructions: """
            你是 DayGlyph 的本机情绪理解模块。只根据用户写下的当天记录做轻量情感量化，不做医疗、心理诊断或绝对判断。
            使用 VAD 连续空间：valence 表示负向到正向，arousal 表示低唤醒到高唤醒，dominance 表示失控到掌控。
            12 个情绪权重允许同时非零，用来表达混合状态；不要强迫文本只有一个情绪。
            生气通常是负向、高唤醒且掌控感相对较高；焦虑通常是负向、高唤醒且掌控感较低；激动通常是正向、高唤醒。
            themeRawValue 只能是 work, relationship, growth, rest, family, health, creativity, unknown。
            valence 和 dominance 必须是 -1 到 1 的小数；arousal、所有权重和 confidence 必须是 0 到 1 的小数。
            explanation 使用简体中文，限制在 32 个汉字左右。
            keywords 返回 1 到 4 个简体中文关键词。
            """
        )

        let response = try await session.respond(
            to: "分析这段 DayGlyph 记录：\(trimmed)",
            generating: FoundationEmotionOutput.self
        )
        return response.content.analysis
    }
}

@Generable
struct FoundationEmotionOutput {
    @Guide(description: "-1 到 1，负向到正向")
    var valence: Double

    @Guide(description: "0 到 1，低唤醒到高唤醒")
    var arousal: Double

    @Guide(description: "-1 到 1，失控到掌控")
    var dominance: Double

    @Guide(description: "平静权重，0 到 1")
    var calmWeight: Double

    @Guide(description: "喜悦权重，0 到 1")
    var joyWeight: Double

    @Guide(description: "感恩权重，0 到 1")
    var gratefulWeight: Double

    @Guide(description: "释然权重，0 到 1")
    var reliefWeight: Double

    @Guide(description: "希望权重，0 到 1")
    var hopefulWeight: Double

    @Guide(description: "激动权重，0 到 1")
    var excitedWeight: Double

    @Guide(description: "生气权重，0 到 1")
    var angryWeight: Double

    @Guide(description: "焦虑权重，0 到 1")
    var anxiousWeight: Double

    @Guide(description: "悲伤权重，0 到 1")
    var sadWeight: Double

    @Guide(description: "疲惫权重，0 到 1")
    var tiredWeight: Double

    @Guide(description: "孤独权重，0 到 1")
    var lonelyWeight: Double

    @Guide(description: "困惑权重，0 到 1")
    var confusedWeight: Double

    @Guide(description: "主题 raw value，只能是 work, relationship, growth, rest, family, health, creativity, unknown")
    var themeRawValue: String

    @Guide(description: "1 到 4 个关键词")
    var keywords: [String]

    @Guide(description: "0 到 1 之间的置信度")
    var confidence: Double

    @Guide(description: "简短中文解释，不超过 32 个汉字")
    var explanation: String

    var analysis: EmotionAnalysis {
        EmotionAnalysis(
            valence: valence,
            arousal: arousal,
            dominance: dominance,
            emotionWeights: [
                EmotionWeight(anchor: .calm, value: calmWeight),
                EmotionWeight(anchor: .joy, value: joyWeight),
                EmotionWeight(anchor: .grateful, value: gratefulWeight),
                EmotionWeight(anchor: .relief, value: reliefWeight),
                EmotionWeight(anchor: .hopeful, value: hopefulWeight),
                EmotionWeight(anchor: .excited, value: excitedWeight),
                EmotionWeight(anchor: .angry, value: angryWeight),
                EmotionWeight(anchor: .anxious, value: anxiousWeight),
                EmotionWeight(anchor: .sad, value: sadWeight),
                EmotionWeight(anchor: .tired, value: tiredWeight),
                EmotionWeight(anchor: .lonely, value: lonelyWeight),
                EmotionWeight(anchor: .confused, value: confusedWeight)
            ],
            theme: DayTheme(rawValue: themeRawValue) ?? .unknown,
            keywords: keywords,
            confidence: confidence,
            explanation: explanation,
            source: .foundationModel
        )
    }
}
