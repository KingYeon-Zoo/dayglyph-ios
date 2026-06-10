import Foundation
import SwiftUI

enum DayEmotion: String, CaseIterable, Codable, Identifiable {
    case calm
    case joy
    case low
    case anxious
    case excited
    case tired
    case grateful
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: "平静"
        case .joy: "喜悦"
        case .low: "低落"
        case .anxious: "焦虑"
        case .excited: "激动"
        case .tired: "疲惫"
        case .grateful: "感恩"
        case .mixed: "混合"
        }
    }
}

enum DayTheme: String, CaseIterable, Codable, Identifiable {
    case work
    case relationship
    case growth
    case rest
    case family
    case health
    case creativity
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: "工作"
        case .relationship: "关系"
        case .growth: "成长"
        case .rest: "休息"
        case .family: "家庭"
        case .health: "健康"
        case .creativity: "创造"
        case .unknown: "日常"
        }
    }
}

enum AnalysisSource: String, Codable, CaseIterable, Identifiable {
    case foundationModel
    case localRules
    case fallback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .foundationModel: "Apple Intelligence 已参与理解"
        case .localRules: "本地理解"
        case .fallback: "Apple Intelligence 不可用 · 已本地回退"
        }
    }
}

struct EmotionAnalysis: Equatable {
    var emotion: DayEmotion
    var theme: DayTheme
    var energy: Double
    var keywords: [String]
    var confidence: Double
    var explanation: String
    var source: AnalysisSource

    init(
        emotion: DayEmotion,
        theme: DayTheme,
        energy: Double,
        keywords: [String],
        confidence: Double = 0.55,
        explanation: String = "根据文字中的状态和语气做出的本地理解。",
        source: AnalysisSource = .localRules
    ) {
        self.emotion = emotion
        self.theme = theme
        self.energy = min(max(energy, 0), 1)
        self.keywords = Array(keywords.prefix(4))
        self.confidence = min(max(confidence, 0), 1)
        self.explanation = explanation
        self.source = source
    }
}
