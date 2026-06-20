import Foundation

/// 客户端高风险第一层短路规则（spec 第 9 节）。
///
/// 在调用模型前用少量明确规则初筛；命中即暂停艺术生图、走安全支持。
/// 第二层由 Seed 返回的结构化 `SafetyAssessment` 判断。
/// 刻意保守：只匹配明确的自伤/自杀/即时危险表达，普通低落焦虑疲惫不触发。
enum SafetyPrescreen {

    /// 明确高风险短语。匹配中文直白表达，避免把普通负面情绪误判为危机。
    private static let highRiskPhrases: [String] = [
        "自杀", "想死", "不想活", "活不下去", "结束自己", "结束生命",
        "了结自己", "轻生", "自残", "自伤", "割腕", "跳楼", "跳下去",
        "吃药结束", "离开这个世界", "消失算了", "解脱算了", "没有我会更好",
        "活着没意义", "撑不下去了想结束"
    ]

    /// 否定语境，降低误判（如“我不会自杀”“别担心我不想死”）。
    private static let negationCues: [String] = ["不会", "不想再", "别担心", "没有要", "不是想"]

    static func isHighRisk(_ text: String) -> Bool {
        let normalized = text.replacingOccurrences(of: " ", with: "")
        for phrase in highRiskPhrases where normalized.contains(phrase) {
            // 简单否定上下文检查：短语紧邻否定词时不触发。
            if hasNegationContext(normalized, around: phrase) { continue }
            return true
        }
        return false
    }

    private static func hasNegationContext(_ text: String, around phrase: String) -> Bool {
        guard let range = text.range(of: phrase) else { return false }
        let prefixStart = text.index(range.lowerBound, offsetBy: -6, limitedBy: text.startIndex) ?? text.startIndex
        let window = String(text[prefixStart..<range.lowerBound])
        return negationCues.contains { window.contains($0) }
    }
}
