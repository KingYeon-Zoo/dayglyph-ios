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

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw FoundationEmotionAnalyzerError.unavailable(String(describing: reason))
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            你是 DayGlyph 的本机情绪理解模块。只根据用户写下的当天记录做轻量分类，不做医疗、心理诊断或绝对判断。
            emotionRawValue 只能是 calm, joy, low, anxious, excited, tired, grateful, mixed。
            themeRawValue 只能是 work, relationship, growth, rest, family, health, creativity, unknown。
            energy 和 confidence 必须是 0 到 1 的小数。
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
    @Guide(description: "情绪 raw value，只能是 calm, joy, low, anxious, excited, tired, grateful, mixed")
    var emotionRawValue: String

    @Guide(description: "主题 raw value，只能是 work, relationship, growth, rest, family, health, creativity, unknown")
    var themeRawValue: String

    @Guide(description: "0 到 1 之间的能量值")
    var energy: Double

    @Guide(description: "1 到 4 个关键词")
    var keywords: [String]

    @Guide(description: "0 到 1 之间的置信度")
    var confidence: Double

    @Guide(description: "简短中文解释，不超过 32 个汉字")
    var explanation: String

    var analysis: EmotionAnalysis {
        EmotionAnalysis(
            emotion: DayEmotion(rawValue: emotionRawValue) ?? .mixed,
            theme: DayTheme(rawValue: themeRawValue) ?? .unknown,
            energy: energy,
            keywords: keywords,
            confidence: confidence,
            explanation: explanation,
            source: .foundationModel
        )
    }
}
