import Foundation

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

    var anchor: EmotionAnchor {
        switch self {
        case .calm: .calm
        case .joy: .joy
        case .low: .sad
        case .anxious: .anxious
        case .excited: .excited
        case .tired: .tired
        case .grateful: .grateful
        case .mixed: .confused
        }
    }
}

enum EmotionAnchor: String, CaseIterable, Codable, Identifiable {
    case calm
    case joy
    case grateful
    case relief
    case hopeful
    case excited
    case angry
    case anxious
    case sad
    case tired
    case lonely
    case confused

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: "平静"
        case .joy: "喜悦"
        case .grateful: "感恩"
        case .relief: "释然"
        case .hopeful: "希望"
        case .excited: "激动"
        case .angry: "生气"
        case .anxious: "焦虑"
        case .sad: "悲伤"
        case .tired: "疲惫"
        case .lonely: "孤独"
        case .confused: "困惑"
        }
    }

    var legacyEmotion: DayEmotion {
        switch self {
        case .calm, .relief: .calm
        case .joy, .hopeful: .joy
        case .grateful: .grateful
        case .excited, .angry: .excited
        case .anxious: .anxious
        case .confused: .mixed
        case .sad, .lonely: .low
        case .tired: .tired
        }
    }
}

struct EmotionWeight: Codable, Equatable, Identifiable {
    var anchor: EmotionAnchor
    var value: Double

    var id: EmotionAnchor { anchor }
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
    case cloudModel
    case demoFixture
    case localRules
    case fallback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .foundationModel: "Apple Intelligence 已参与理解"
        case .cloudModel: "在线模型已参与理解"
        case .demoFixture: "策展情绪样本"
        case .localRules: "本地理解"
        case .fallback: "已使用本地回退"
        }
    }
}

struct EmotionAnalysis: Equatable {
    var valence: Double
    var arousal: Double
    var dominance: Double
    var emotionWeights: [EmotionWeight]
    var theme: DayTheme
    var keywords: [String]
    var confidence: Double
    var explanation: String
    var source: AnalysisSource

    init(
        valence: Double,
        arousal: Double,
        dominance: Double,
        emotionWeights: [EmotionWeight],
        theme: DayTheme,
        keywords: [String],
        confidence: Double = 0.55,
        explanation: String = "根据文字中的状态和语气做出的本地理解。",
        source: AnalysisSource = .localRules
    ) {
        self.valence = min(max(valence, -1), 1)
        self.arousal = min(max(arousal, 0), 1)
        self.dominance = min(max(dominance, -1), 1)
        let normalizedWeights = Self.normalizedWeights(emotionWeights)
        self.emotionWeights = normalizedWeights.weights
        self.theme = theme
        self.keywords = Array(keywords.prefix(4))
        let clampedConfidence = min(max(confidence, 0), 1)
        self.confidence = normalizedWeights.usedFallback ? min(clampedConfidence, 0.35) : clampedConfidence
        self.explanation = explanation
        self.source = source
    }

    init(
        emotion: DayEmotion,
        theme: DayTheme,
        energy: Double,
        keywords: [String],
        confidence: Double = 0.55,
        explanation: String = "根据文字中的状态和语气做出的本地理解。",
        source: AnalysisSource = .localRules
    ) {
        let vector = Self.legacyVector(for: emotion, energy: energy)
        self.init(
            valence: vector.valence,
            arousal: energy,
            dominance: vector.dominance,
            emotionWeights: [EmotionWeight(anchor: emotion.anchor, value: 1)],
            theme: theme,
            keywords: keywords,
            confidence: confidence,
            explanation: explanation,
            source: source
        )
    }

    var primaryEmotion: EmotionAnchor {
        topEmotionWeights.first?.anchor ?? .confused
    }

    var topEmotionWeights: [EmotionWeight] {
        Array(
            emotionWeights
                .filter { $0.value > 0 }
                .sorted {
                    if $0.value == $1.value {
                        return $0.anchor.rawValue < $1.anchor.rawValue
                    }
                    return $0.value > $1.value
                }
                .prefix(3)
        )
    }

    var emotion: DayEmotion {
        primaryEmotion.legacyEmotion
    }

    var energy: Double {
        arousal
    }

    private static func normalizedWeights(_ weights: [EmotionWeight]) -> (weights: [EmotionWeight], usedFallback: Bool) {
        var values = Dictionary(uniqueKeysWithValues: EmotionAnchor.allCases.map { ($0, 0.0) })
        for weight in weights {
            values[weight.anchor, default: 0] += max(weight.value, 0)
        }

        let total = values.values.reduce(0, +)
        guard total > 0 else {
            return (
                EmotionAnchor.allCases.map {
                    EmotionWeight(anchor: $0, value: $0 == .confused ? 1 : 0)
                },
                true
            )
        }

        return (
            EmotionAnchor.allCases.map {
                EmotionWeight(anchor: $0, value: values[$0, default: 0] / total)
            },
            false
        )
    }

    private static func legacyVector(for emotion: DayEmotion, energy: Double) -> (valence: Double, dominance: Double) {
        switch emotion {
        case .calm: (0.35, 0.35)
        case .joy: (0.78, 0.45)
        case .low: (-0.68, -0.55)
        case .anxious: (-0.62, -0.58)
        case .excited: (0.62, 0.52)
        case .tired: (-0.35, -0.52)
        case .grateful: (0.72, 0.35)
        case .mixed: (0, -0.1)
        }
    }
}
