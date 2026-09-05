import Foundation

/// 把豆包统一生成响应投影到现有 `EmotionAnalysis`（spec 5.1、第 10 节）。
///
/// 丰富情绪（1～8 个标准词）通过情绪族折叠到旧 12 个 `EmotionAnchor` 隐藏权重，
/// 维持现有统计、RealityKit 聚合与 `GlyphSignature` 视觉公式兼容。
/// VAD 直接采用模型返回的 dimensions（已由校验器确保范围合法）。
enum GenerationAnalysisMapper {

    static func makeAnalysis(from response: DayGenerationResponse) -> EmotionAnalysis {
        let payload = response.emotionAnalysis
        let dimensions = payload.dimensions

        // 1) 情绪 → 12 锚点权重：按强度累加到所属族对应的锚点。
        var anchorWeights: [EmotionAnchor: Double] = [:]
        for item in payload.emotions {
            let anchor = anchorForEmotion(item)
            anchorWeights[anchor, default: 0] += max(item.intensity, 0)
        }
        // 全为 0 时兜底到 confused，交由 EmotionAnalysis 归一化处理。
        let weights = anchorWeights.isEmpty
            ? [EmotionWeight(anchor: .confused, value: 1)]
            : anchorWeights.map { EmotionWeight(anchor: $0.key, value: $0.value) }

        // 2) 主题：从依据与关键词推断，落到旧 DayTheme（统计兼容）。
        let theme = inferTheme(from: response)

        // 3) 关键词：取情绪词 + summary 关键短语，最多 4 个。
        let keywords = Array(payload.emotions.map(\.term).prefix(4))

        // 4) 置信度：所有情绪项置信度均值。
        let confidence = payload.emotions.isEmpty
            ? 0.4
            : payload.emotions.map(\.confidence).reduce(0, +) / Double(payload.emotions.count)

        return EmotionAnalysis(
            valence: dimensions.valence,
            arousal: dimensions.arousal,
            dominance: dimensions.dominance,
            emotionWeights: weights,
            theme: theme,
            keywords: keywords,
            confidence: confidence,
            explanation: payload.summary,
            source: .cloudModel
        )
    }

    /// 单个情绪项的锚点：优先用词库条目的族映射，否则用 payload 里的 family，最后兜底。
    private static func anchorForEmotion(_ item: EmotionItem) -> EmotionAnchor {
        if let entry = EmotionLexicon.entry(for: item.term) {
            return entry.family.anchor
        }
        if let family = EmotionFamily(rawValue: item.family) {
            return family.anchor
        }
        return .confused
    }

    private static func inferTheme(from response: DayGenerationResponse) -> DayTheme {
        let text = ([
            response.emotionAnalysis.summary,
            response.dailyAction.reason
        ] + response.emotionAnalysis.emotions.map(\.evidence)).joined(separator: " ")

        let table: [(DayTheme, [String])] = [
            (.work, ["工作", "项目", "方案", "会议", "客户", "同事", "任务", "deadline", "加班"]),
            (.relationship, ["朋友", "伴侣", "关系", "沟通", "理解", "吵架", "陪伴"]),
            (.family, ["家", "父母", "孩子", "妈妈", "爸爸", "家人"]),
            (.health, ["身体", "运动", "跑步", "健康", "睡眠", "生病"]),
            (.growth, ["学习", "成长", "复盘", "进步", "读书", "方向"]),
            (.creativity, ["画", "写", "设计", "创作", "灵感"]),
            (.rest, ["休息", "放空", "散步", "咖啡", "发呆"])
        ]

        var best: (DayTheme, Int) = (.unknown, 0)
        for (theme, keywords) in table {
            let hits = keywords.reduce(0) { $0 + (text.contains($1) ? 1 : 0) }
            if hits > best.1 { best = (theme, hits) }
        }
        return best.0
    }
}
