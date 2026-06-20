import Foundation
import SwiftData

@Model
final class DayEntry {
    var entryID: UUID = UUID()
    var date: Date
    var text: String
    var emotionRawValue: String
    var energy: Double
    var themeRawValue: String
    var keywordsBlob: String
    var glyphSeed: Int
    var confidence: Double = 0.55
    var analysisSourceRawValue: String = AnalysisSource.localRules.rawValue
    var explanation: String = "根据文字中的状态和语气做出的本地理解。"
    var valence: Double = 0
    var dominance: Double = 0
    var emotionWeightsData: Data = Data()
    var analysisVersion: Int = 1
    var emotionRecipeData: Data = Data()
    var cocktailVisualData: Data = Data()
    var planetVisualData: Data = Data()
    var moodWeatherData: Data = Data()
    var visualVersion: Int = 0
    var isFavorite: Bool = false
    var createdAt: Date
    var updatedAt: Date
    var isDemo: Bool

    init(
        entryID: UUID = UUID(),
        date: Date,
        text: String,
        analysis: EmotionAnalysis,
        glyphSeed: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isDemo: Bool = false
    ) {
        self.entryID = entryID
        self.date = Calendar.current.startOfDay(for: date)
        self.text = text
        self.emotionRawValue = analysis.primaryEmotion.rawValue
        self.energy = analysis.arousal
        self.themeRawValue = analysis.theme.rawValue
        self.keywordsBlob = analysis.keywords.joined(separator: "|")
        self.glyphSeed = glyphSeed
        self.confidence = analysis.confidence
        self.analysisSourceRawValue = analysis.source.rawValue
        self.explanation = analysis.explanation
        self.valence = analysis.valence
        self.dominance = analysis.dominance
        self.emotionWeightsData = Self.encodeWeights(analysis.emotionWeights)
        self.analysisVersion = 2
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDemo = isDemo
        let visuals = EmotionVisualFactory.makeVisuals(text: text, date: self.date, analysis: analysis)
        applyVisuals(visuals)
    }

    var emotion: DayEmotion {
        primaryEmotion.legacyEmotion
    }

    var primaryEmotion: EmotionAnchor {
        emotionWeights.max { $0.value < $1.value }?.anchor
            ?? EmotionAnchor(rawValue: emotionRawValue)
            ?? DayEmotion(rawValue: emotionRawValue)?.anchor
            ?? .confused
    }

    var arousal: Double {
        energy
    }

    var emotionWeights: [EmotionWeight] {
        if let decoded = try? JSONDecoder().decode([EmotionWeight].self, from: emotionWeightsData),
           decoded.isEmpty == false {
            return decoded
        }
        return [EmotionWeight(anchor: legacyAnchor, value: 1)]
    }

    var theme: DayTheme {
        DayTheme(rawValue: themeRawValue) ?? .unknown
    }

    var keywords: [String] {
        keywordsBlob
            .split(separator: "|")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    var analysisSource: AnalysisSource {
        AnalysisSource(rawValue: analysisSourceRawValue) ?? .fallback
    }

    var analysis: EmotionAnalysis {
        EmotionAnalysis(
            valence: valence,
            arousal: arousal,
            dominance: dominance,
            emotionWeights: emotionWeights,
            theme: theme,
            keywords: keywords,
            confidence: confidence,
            explanation: explanation,
            source: analysisSource
        )
    }

    var emotionRecipe: EmotionRecipe {
        decode(EmotionRecipe.self, from: emotionRecipeData)
            ?? EmotionVisualFactory.makeVisuals(text: text, date: date, analysis: analysis).recipe
    }

    var cocktailVisual: CocktailVisual {
        decode(CocktailVisual.self, from: cocktailVisualData)
            ?? EmotionVisualFactory.makeVisuals(text: text, date: date, analysis: analysis).cocktail
    }

    var planetVisual: PlanetVisual {
        decode(PlanetVisual.self, from: planetVisualData)
            ?? EmotionVisualFactory.makeVisuals(text: text, date: date, analysis: analysis).planet
    }

    var moodWeather: MoodWeather {
        decode(MoodWeather.self, from: moodWeatherData)
            ?? EmotionVisualFactory.makeVisuals(text: text, date: date, analysis: analysis).weather
    }

    func update(text: String, analysis: EmotionAnalysis, glyphSeed: Int, date: Date = .now) {
        self.text = text
        self.emotionRawValue = analysis.primaryEmotion.rawValue
        self.energy = analysis.arousal
        self.themeRawValue = analysis.theme.rawValue
        self.keywordsBlob = analysis.keywords.joined(separator: "|")
        self.glyphSeed = glyphSeed
        self.confidence = analysis.confidence
        self.analysisSourceRawValue = analysis.source.rawValue
        self.explanation = analysis.explanation
        self.valence = analysis.valence
        self.dominance = analysis.dominance
        self.emotionWeightsData = Self.encodeWeights(analysis.emotionWeights)
        self.analysisVersion = 2
        self.updatedAt = date
        let visuals = EmotionVisualFactory.makeVisuals(text: text, date: self.date, analysis: analysis)
        applyVisuals(visuals)
    }

    func applyVisuals(_ visuals: EntryVisuals) {
        emotionRecipeData = encode(visuals.recipe)
        cocktailVisualData = encode(visuals.cocktail)
        planetVisualData = encode(visuals.planet)
        moodWeatherData = encode(visuals.weather)
        visualVersion = visuals.visualVersion
    }

    private var legacyAnchor: EmotionAnchor {
        EmotionAnchor(rawValue: emotionRawValue)
            ?? DayEmotion(rawValue: emotionRawValue)?.anchor
            ?? .confused
    }

    private static func encodeWeights(_ weights: [EmotionWeight]) -> Data {
        (try? JSONEncoder().encode(weights)) ?? Data()
    }

    private func encode<T: Encodable>(_ value: T) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        guard data.isEmpty == false else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
