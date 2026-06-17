import Foundation

enum EmotionVisualFactory {
    static func makeVisuals(
        text: String,
        date: Date,
        analysis: EmotionAnalysis,
        calendar: Calendar = .current
    ) -> EntryVisuals {
        let seed = stableSeed(text: text, date: date, calendar: calendar)
        let topWeights = analysis.topEmotionWeights
        let primary = EmotionVisualAnchor.map(from: topWeights.first?.anchor ?? .confused)
        let parts = recipeParts(from: topWeights)
        let secondary = parts.dropFirst().map(\.anchor)
        let keywords = Array((analysis.keywords + parts.map { $0.anchor.title }).uniqued().prefix(3))

        return EntryVisuals(
            recipe: EmotionRecipe(
                primary: primary,
                secondary: secondary,
                parts: parts,
                keywords: keywords,
                confidenceBand: confidenceBand(for: analysis.confidence),
                name: recipeName(for: primary, seed: seed),
                supportCopy: supportCopy(for: primary, confidence: analysis.confidence)
            ),
            cocktail: CocktailVisual(
                glassType: glassType(for: primary),
                liquidLayers: parts.map { colorToken(for: $0.anchor) },
                bubbleLevel: min(max(analysis.arousal, 0.08), 0.95),
                garnish: garnish(for: primary),
                backgroundSeed: seed
            ),
            planet: PlanetVisual(
                seed: seed,
                baseHue: hue(for: primary),
                secondaryHue: hue(for: secondary.first ?? primary),
                textureComplexity: min(max(Double(analysis.emotionWeights.filter { $0.value > 0.08 }.count) / 4.0, 0.20), 0.85),
                glow: min(max(analysis.arousal, 0.25), 0.90),
                rings: min(secondary.count, 3),
                satellites: min(max(analysis.keywords.count - 1, 0), 3),
                rotationSpeed: 0.02 + Double(seed % 11) / 100.0
            ),
            weather: MoodWeather(
                type: weatherType(for: primary),
                intensityBand: analysis.arousal > 0.66 ? "明显" : "柔和",
                animationSeed: seed,
                explanation: weatherExplanation(for: primary)
            ),
            visualVersion: 1
        )
    }

    private static func stableSeed(text: String, date: Date, calendar: Calendar) -> Int {
        let day = Int(calendar.startOfDay(for: date).timeIntervalSince1970)
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in "\(text)|\(day)".utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return Int(hash % UInt64(Int.max))
    }

    private static func recipeParts(from weights: [EmotionWeight]) -> [RecipePart] {
        let selected = Array(weights.prefix(3))
        guard selected.isEmpty == false else { return [RecipePart(anchor: .confused, parts: 10)] }

        let raw = selected.map { max(1, Int(($0.value * 10).rounded())) }
        let total = raw.reduce(0, +)
        var adjusted = raw
        adjusted[0] += 10 - total

        return zip(selected, adjusted).map {
            RecipePart(anchor: EmotionVisualAnchor.map(from: $0.anchor), parts: max(1, $1))
        }
    }

    private static func confidenceBand(for confidence: Double) -> ConfidenceBand {
        if confidence < 0.45 { return .low }
        if confidence < 0.75 { return .medium }
        return .high
    }

    private static func recipeName(for anchor: EmotionVisualAnchor, seed: Int) -> String {
        let suffixes = ["微光", "余响", "晨雾", "柔风"]
        return "\(anchor.title)\(suffixes[seed % suffixes.count])"
    }

    private static func supportCopy(for anchor: EmotionVisualAnchor, confidence: Double) -> String {
        if confidence < 0.45 { return "如果这份结果与你的感受不完全一致，可以把它当作一次温和的观察。" }
        return "它不是对你的定义，只是为今天留下的一种观察。"
    }

    private static func glassType(for anchor: EmotionVisualAnchor) -> String {
        switch anchor {
        case .calm, .tired, .sad, .lonely, .numb: "lowball"
        case .joy, .moved, .anticipation, .proud: "coupe"
        default: "highball"
        }
    }

    private static func colorToken(for anchor: EmotionVisualAnchor) -> String {
        switch anchor {
        case .joy: "#FF6D8F"
        case .calm: "#61C7B5"
        case .anticipation: "#7C69E8"
        case .moved: "#E678A7"
        case .proud: "#F49B43"
        case .tired: "#8E91B4"
        case .sad: "#5E76C9"
        case .anxious: "#8866D8"
        case .angry: "#E75C6C"
        case .lonely: "#536AAE"
        case .confused: "#6B8FA3"
        case .numb: "#7E858E"
        }
    }

    private static func hue(for anchor: EmotionVisualAnchor) -> Double {
        switch anchor {
        case .joy: 344
        case .calm: 171
        case .anticipation: 252
        case .moved: 329
        case .proud: 33
        case .tired: 232
        case .sad: 222
        case .anxious: 260
        case .angry: 352
        case .lonely: 226
        case .confused: 199
        case .numb: 210
        }
    }

    private static func garnish(for anchor: EmotionVisualAnchor) -> String {
        switch anchor {
        case .joy, .moved: "rose"
        case .calm: "mint"
        case .angry, .anxious: "citrus"
        default: "light"
        }
    }

    private static func weatherType(for anchor: EmotionVisualAnchor) -> String {
        switch anchor {
        case .joy, .moved, .proud: "晴光"
        case .calm: "微风"
        case .sad: "细雨"
        case .anxious: "阵雨"
        case .angry: "闷雷"
        case .lonely: "夜雾"
        case .tired: "阴天"
        case .numb: "无风阴天"
        case .anticipation: "晨曦"
        default: "薄雾"
        }
    }

    private static func weatherExplanation(for anchor: EmotionVisualAnchor) -> String {
        "\(anchor.title)在这份记录里更明显，所以今天的天气被写成一种轻量隐喻。"
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
