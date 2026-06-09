import Foundation

struct EmotionAnalyzer {
    func analyze(_ text: String) -> EmotionAnalysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return EmotionAnalysis(
                emotion: .mixed,
                theme: .unknown,
                energy: 0.3,
                keywords: [],
                confidence: 0.1,
                explanation: "还没有足够内容可以理解。",
                source: .fallback
            )
        }

        let normalized = normalize(trimmed)
        let emotionScores = scoreEmotion(in: normalized)
        let themeScores = scoreTheme(in: normalized)
        let emotion = strongestEmotion(from: emotionScores, text: normalized)
        let theme = strongestTheme(from: themeScores)
        let energy = energyScore(in: normalized, emotion: emotion)
        let confidence = confidenceScore(emotionScores: emotionScores, themeScores: themeScores, text: normalized)
        let keywords = extractKeywords(from: normalized, theme: theme, emotion: emotion)
        let explanation = explanation(for: emotion, theme: theme, text: normalized, confidence: confidence)

        return EmotionAnalysis(
            emotion: emotion,
            theme: theme,
            energy: energy,
            keywords: keywords,
            confidence: confidence,
            explanation: explanation,
            source: .localRules
        )
    }

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "搞定", with: "搞完")
            .replacingOccurrences(of: "搞好了", with: "搞完")
            .replacingOccurrences(of: "处理好了", with: "搞完")
            .replacingOccurrences(of: "完事", with: "搞完")
    }

    private func scoreEmotion(in text: String) -> [DayEmotion: Double] {
        let table: [(DayEmotion, Double, [String])] = [
            (.grateful, 1.4, ["感谢", "感恩", "谢谢", "被理解", "帮我", "幸运", "珍惜", "grateful", "thanks"]),
            (.joy, 1.2, ["开心", "快乐", "高兴", "满足", "好棒", "喜欢", "顺利", "搞完", "完成", "终于", "happy"]),
            (.calm, 1.2, ["平静", "安静", "放松", "散步", "呼吸", "松了一口气", "轻松", "安心", "刚刚好", "calm"]),
            (.tired, 1.3, ["累", "疲惫", "困", "睡不好", "提不起劲", "不想动", "撑不住", "tired", "exhausted"]),
            (.anxious, 1.3, ["焦虑", "担心", "紧张", "害怕", "压力", "脑子很乱", "很乱", "慌", "卡住", "anxious"]),
            (.low, 1.25, ["难过", "低落", "沮丧", "失望", "孤独", "说不上来", "空空的", "没意思", "sad", "down"]),
            (.excited, 1.15, ["激动", "兴奋", "冲刺", "突破", "太好了", "thrilled", "excited"])
        ]

        var scores: [DayEmotion: Double] = [:]
        for (emotion, weight, keywords) in table {
            for keyword in keywords where text.contains(keyword) {
                scores[emotion, default: 0] += weight
            }
        }
        if text.contains("但") || text.contains("不过") || text.contains("可是") {
            scores[.mixed, default: 0] += 0.45
        }
        return scores
    }

    private func scoreTheme(in text: String) -> [DayTheme: Double] {
        let table: [(DayTheme, Double, [String])] = [
            (.work, 1.2, ["工作", "项目", "会议", "客户", "同事", "deadline", "收尾", "事情", "任务", "搞完", "work"]),
            (.relationship, 1.2, ["朋友", "伴侣", "关系", "聊天", "沟通", "同事帮", "被理解", "friend", "love"]),
            (.growth, 1.0, ["学习", "成长", "复盘", "进步", "读书", "方向", "learn"]),
            (.rest, 1.0, ["休息", "睡", "散步", "放空", "累", "咖啡", "rest", "sleep"]),
            (.family, 1.0, ["家", "父母", "孩子", "妈妈", "爸爸", "family"]),
            (.health, 1.0, ["身体", "运动", "跑步", "健康", "病", "health"]),
            (.creativity, 1.0, ["画", "写", "设计", "创作", "灵感", "create"])
        ]

        var scores: [DayTheme: Double] = [:]
        for (theme, weight, keywords) in table {
            for keyword in keywords where text.contains(keyword) {
                scores[theme, default: 0] += weight
            }
        }
        return scores
    }

    private func strongestEmotion(from scores: [DayEmotion: Double], text: String) -> DayEmotion {
        let sorted = scores.sorted { $0.value > $1.value }
        guard let best = sorted.first, best.value > 0 else {
            return text.count <= 6 ? .mixed : .calm
        }
        let hasContrast = text.contains("但") || text.contains("不过") || text.contains("可是") || text.contains("又")
        if hasContrast, let second = sorted.dropFirst().first, second.value >= best.value * 0.82 {
            return .mixed
        }
        return best.key
    }

    private func strongestTheme(from scores: [DayTheme: Double]) -> DayTheme {
        scores.max { $0.value < $1.value }?.key ?? .unknown
    }

    private func energyScore(in text: String, emotion: DayEmotion) -> Double {
        var score: Double = switch emotion {
        case .excited: 0.78
        case .joy, .grateful: 0.62
        case .anxious: 0.68
        case .calm: 0.38
        case .low, .tired: 0.28
        case .mixed: 0.52
        }
        score += Double(text.filter { $0 == "!" || $0 == "！" }.count) * 0.05
        if text.contains("很") || text.contains("特别") || text.contains("太") {
            score += 0.06
        }
        if text.contains("终于") || text.contains("撑") {
            score += 0.05
        }
        score += min(Double(text.count) / 700.0, 0.08)
        return min(max(score, 0), 1)
    }

    private func confidenceScore(
        emotionScores: [DayEmotion: Double],
        themeScores: [DayTheme: Double],
        text: String
    ) -> Double {
        let emotionStrength = emotionScores.values.max() ?? 0
        let themeStrength = themeScores.values.max() ?? 0
        let lengthBonus = min(Double(text.count) / 80.0, 0.18)
        return min(max(0.38 + emotionStrength * 0.14 + themeStrength * 0.08 + lengthBonus, 0.25), 0.92)
    }

    private func extractKeywords(from text: String, theme: DayTheme, emotion: DayEmotion) -> [String] {
        let candidates = [
            "项目", "感谢", "同事", "朋友", "学习", "家人", "运动", "创作", "完成", "搞完",
            "压力", "睡", "咖啡", "脑子很乱", "松了一口气", theme.title, emotion.title
        ]
        var result: [String] = []
        for candidate in candidates where text.contains(candidate) && !result.contains(candidate) {
            result.append(candidate)
            if result.count == 4 { break }
        }
        if result.isEmpty {
            result.append(theme == .unknown ? emotion.title : theme.title)
        }
        return result
    }

    private func explanation(for emotion: DayEmotion, theme: DayTheme, text: String, confidence: Double) -> String {
        if confidence < 0.45 {
            return "这段话比较含蓄，先按整体语气保留为\(emotion.title)。"
        }
        if text.contains("搞完") || text.contains("完成") || text.contains("松了一口气") {
            return "文字里有完成和释放感，整体更接近\(emotion.title)。"
        }
        if theme == .unknown {
            return "根据语气和状态词，今天更接近\(emotion.title)。"
        }
        return "结合\(theme.title)相关内容和语气，今天更接近\(emotion.title)。"
    }
}
