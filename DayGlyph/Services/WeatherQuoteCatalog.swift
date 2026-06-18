import Foundation

nonisolated struct MoodWeatherPresentation: Equatable {
    var symbolName: String
    var title: String
    var accessibilityDescription: String
}

nonisolated struct SupportQuote: Equatable, Identifiable {
    var id: String
    var text: String
    var attribution: String?
    var matchExplanation: String
    var isProductCopy: Bool
}

nonisolated enum WeatherQuoteCatalog {
    static func presentation(for weather: MoodWeather) -> MoodWeatherPresentation {
        let symbol: String
        switch weather.type {
        case "晴光", "晨曦": symbol = "sun.max.fill"
        case "微风": symbol = "wind"
        case "细雨": symbol = "cloud.drizzle.fill"
        case "阵雨": symbol = "cloud.rain.fill"
        case "闷雷": symbol = "cloud.bolt.rain.fill"
        case "夜雾": symbol = "cloud.moon.fill"
        case "阴天", "无风阴天": symbol = "cloud.fill"
        default: symbol = "cloud.fog.fill"
        }
        let title = "\(weather.intensityBand)的\(weather.type)"
        return MoodWeatherPresentation(
            symbolName: symbol,
            title: title,
            accessibilityDescription: "今天的情绪天气是\(title)。\(weather.explanation)"
        )
    }

    static func quote(
        for anchor: EmotionVisualAnchor,
        date: Date,
        switchCount: Int,
        calendar: Calendar = .current
    ) -> SupportQuote {
        let candidates = quotes[anchor] ?? []
        guard candidates.isEmpty == false else {
            return SupportQuote(
                id: "product-fallback-\(anchor.rawValue)",
                text: fallbackCopy(for: anchor),
                attribution: nil,
                matchExplanation: "这是一句 DayGlyph 自有支持文案，用来回应今天较难命名的感受。",
                isProductCopy: true
            )
        }
        let day = Int(calendar.startOfDay(for: date).timeIntervalSinceReferenceDate / 86_400)
        let index = abs(day + switchCount) % candidates.count
        return candidates[index]
    }

    static func canSwitch(currentCount: Int) -> Bool {
        currentCount < 3
    }

    private static let quotes: [EmotionVisualAnchor: [SupportQuote]] = [
        .joy: productQuotes("喜悦", ["让这份明亮在今天多停留一会儿。", "值得记住的轻松，不需要额外证明。"]),
        .calm: productQuotes("平静", ["安静不是空白，它也在承接今天。", "慢一点的时候，细节会重新出现。"]),
        .anticipation: productQuotes("期待", ["不必立刻抵达，方向感已经是一种开始。", "允许期待和一点不确定同时存在。"]),
        .moved: productQuotes("感动", ["被触动的瞬间，说明你认真接住了这份在意。", "温柔被看见时，也会在心里留下回声。"]),
        .proud: productQuotes("自豪", ["把完成的这一刻留给自己，不急着奔向下一件事。", "你可以承认这一步确实不容易。"]),
        .tired: productQuotes("疲惫", ["今天可以少承担一点，先把力气留给自己。", "休息不是落后，它是身体给出的具体消息。"]),
        .sad: productQuotes("难过", ["不急着让雨停，先给这份难过一个位置。", "今天的低落不需要被解释成失败。"]),
        .anxious: productQuotes("焦虑", ["先回到眼前这一分钟，不必一次想完所有以后。", "担心很多时，只处理最近的一小步就够了。"]),
        .angry: productQuotes("愤怒", ["愤怒有时是在提醒：某条边界值得被认真看见。", "先允许这份力度存在，再决定要把它带向哪里。"]),
        .lonely: productQuotes("孤独", ["此刻感到孤单，不等于你只能独自承受。", "想要连接是一种需要，不是负担。"]),
        .confused: productQuotes("困惑", ["暂时说不清也可以，答案不必今天全部出现。", "几种感受重叠时，先保留它们各自的位置。"])
    ]

    private static func productQuotes(_ anchor: String, _ texts: [String]) -> [SupportQuote] {
        texts.enumerated().map { index, text in
            SupportQuote(
                id: "dayglyph-\(anchor)-\(index)",
                text: text,
                attribution: "DayGlyph",
                matchExplanation: "这句话与今天配方里的“\(anchor)”关键词相呼应。",
                isProductCopy: true
            )
        }
    }

    private static func fallbackCopy(for anchor: EmotionVisualAnchor) -> String {
        switch anchor {
        case .numb: "感受暂时不明显也可以，先从身体和周围的小细节开始。"
        default: "今天不必得出结论，留下这份观察就已经足够。"
        }
    }
}
