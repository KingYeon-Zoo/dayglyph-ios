import Foundation

struct EmotionAnalyzer {
    func analyze(_ text: String) -> EmotionAnalysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return EmotionAnalysis(emotion: .mixed, theme: .unknown, energy: 0.3, keywords: [])
        }

        let lowercased = trimmed.lowercased()
        let emotion = strongestEmotion(in: lowercased)
        let theme = strongestTheme(in: lowercased)
        let energy = energyScore(in: trimmed, emotion: emotion)
        let keywords = extractKeywords(from: trimmed, theme: theme, emotion: emotion)

        return EmotionAnalysis(emotion: emotion, theme: theme, energy: energy, keywords: keywords)
    }

    private func strongestEmotion(in text: String) -> DayEmotion {
        let table: [(DayEmotion, [String])] = [
            (.grateful, ["感谢", "感恩", "谢谢", "幸运", "珍惜", "grateful", "thanks"]),
            (.joy, ["开心", "快乐", "高兴", "满足", "好棒", "喜欢", "joy", "happy"]),
            (.tired, ["累", "疲惫", "困", "睡不好", "提不起劲", "tired", "exhausted"]),
            (.anxious, ["焦虑", "担心", "紧张", "害怕", "压力", "anxious", "worried"]),
            (.low, ["难过", "低落", "沮丧", "失望", "孤独", "sad", "down"]),
            (.excited, ["激动", "兴奋", "冲刺", "突破", "终于", "excited", "thrilled"]),
            (.calm, ["平静", "安静", "放松", "散步", "呼吸", "calm", "peace"])
        ]

        var best: (emotion: DayEmotion, score: Int) = (.mixed, 0)
        for row in table {
            let score = row.1.reduce(0) { partial, keyword in
                partial + (text.contains(keyword) ? 1 : 0)
            }
            if score > best.score {
                best = (row.0, score)
            }
        }
        return best.score == 0 ? .mixed : best.emotion
    }

    private func strongestTheme(in text: String) -> DayTheme {
        let table: [(DayTheme, [String])] = [
            (.work, ["工作", "项目", "会议", "客户", "同事", "deadline", "work"]),
            (.relationship, ["朋友", "伴侣", "关系", "聊天", "沟通", "friend", "love"]),
            (.growth, ["学习", "成长", "复盘", "进步", "读书", "learn"]),
            (.rest, ["休息", "睡", "散步", "放空", "累", "rest", "sleep"]),
            (.family, ["家", "父母", "孩子", "妈妈", "爸爸", "family"]),
            (.health, ["身体", "运动", "跑步", "健康", "病", "health"]),
            (.creativity, ["画", "写", "设计", "创作", "灵感", "create"])
        ]

        var best: (theme: DayTheme, score: Int) = (.unknown, 0)
        for row in table {
            let score = row.1.reduce(0) { partial, keyword in
                partial + (text.contains(keyword) ? 1 : 0)
            }
            if score > best.score {
                best = (row.0, score)
            }
        }
        return best.score == 0 ? .unknown : best.theme
    }

    private func energyScore(in text: String, emotion: DayEmotion) -> Double {
        var score: Double = switch emotion {
        case .excited: 0.78
        case .joy, .grateful: 0.62
        case .anxious: 0.68
        case .calm: 0.38
        case .low, .tired: 0.28
        case .mixed: 0.46
        }

        score += Double(text.filter { $0 == "!" || $0 == "！" }.count) * 0.06
        score += min(Double(text.count) / 500.0, 0.12)
        return min(max(score, 0), 1)
    }

    private func extractKeywords(from text: String, theme: DayTheme, emotion: DayEmotion) -> [String] {
        let candidates = [
            "项目", "感谢", "同事", "休息", "朋友", "学习", "家人", "运动", "创作", "完成",
            "压力", "睡", theme.title, emotion.title
        ]

        var result: [String] = []
        for candidate in candidates where text.contains(candidate) && !result.contains(candidate) {
            result.append(candidate)
            if result.count == 4 { break }
        }

        if result.isEmpty {
            result.append(theme == .unknown ? emotion.title : theme.title)
        }
        return Array(result.prefix(4))
    }
}
