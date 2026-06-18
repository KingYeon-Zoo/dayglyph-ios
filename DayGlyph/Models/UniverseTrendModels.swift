import Foundation

nonisolated enum UniverseTrendRange: String, CaseIterable, Identifiable {
    case month
    case quarter
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: "月"
        case .quarter: "季"
        case .year: "年"
        }
    }
}

nonisolated struct UniverseEmotionComposition: Identifiable, Equatable {
    var anchor: EmotionVisualAnchor
    var proportion: Double

    var id: EmotionVisualAnchor { anchor }
}

nonisolated struct UniverseTrendSummary: Equatable {
    var range: UniverseTrendRange
    var startDate: Date
    var endDate: Date
    var days: [UniverseDaySummary]
    var emotionComposition: [UniverseEmotionComposition]
    var weatherTypes: [String: Int]
    var keywords: [String]
    var arousalRange: ClosedRange<Double>

    var recordDayCount: Int { days.count }
    var hasEnoughDataForPatterns: Bool { recordDayCount >= 7 }
    var guidance: String {
        hasEnoughDataForPatterns
            ? "这些构成只用于回看，不代表情绪好坏。"
            : "至少记录 7 天后显示趋势"
    }
}

nonisolated struct UniverseExportMetadata: Equatable {
    var title: String
    var sampleDescription: String
    var sourceNotice: String

    init(summary: UniverseTrendSummary, calendar: Calendar = .current) {
        let chineseDate = Date.FormatStyle(
            date: .long,
            time: .omitted,
            locale: Locale(identifier: "zh_CN")
        )
        let start = summary.startDate.formatted(chineseDate)
        let end = summary.endDate.formatted(chineseDate)
        title = "情绪宇宙 · \(summary.range.title)度回顾"
        sampleDescription = "基于 \(start) 至 \(end) 的 \(summary.recordDayCount) 个记录日"
        sourceNotice = "仅基于你的记录"
    }
}
