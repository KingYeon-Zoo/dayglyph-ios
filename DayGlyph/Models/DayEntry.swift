import Foundation
import SwiftData

@Model
final class DayEntry {
    var date: Date
    var text: String
    var emotionRawValue: String
    var energy: Double
    var themeRawValue: String
    var keywordsBlob: String
    var glyphSeed: Int
    var createdAt: Date
    var updatedAt: Date
    var isDemo: Bool

    init(
        date: Date,
        text: String,
        emotion: DayEmotion,
        energy: Double,
        theme: DayTheme,
        keywords: [String],
        glyphSeed: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isDemo: Bool = false
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.text = text
        self.emotionRawValue = emotion.rawValue
        self.energy = min(max(energy, 0), 1)
        self.themeRawValue = theme.rawValue
        self.keywordsBlob = keywords.joined(separator: "|")
        self.glyphSeed = glyphSeed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDemo = isDemo
    }

    var emotion: DayEmotion {
        DayEmotion(rawValue: emotionRawValue) ?? .mixed
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

    func update(text: String, analysis: EmotionAnalysis, glyphSeed: Int, date: Date = .now) {
        self.text = text
        self.emotionRawValue = analysis.emotion.rawValue
        self.energy = min(max(analysis.energy, 0), 1)
        self.themeRawValue = analysis.theme.rawValue
        self.keywordsBlob = analysis.keywords.joined(separator: "|")
        self.glyphSeed = glyphSeed
        self.updatedAt = date
    }
}
