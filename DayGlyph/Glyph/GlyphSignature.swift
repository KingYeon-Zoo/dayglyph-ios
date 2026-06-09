import Foundation
import SwiftUI

enum GlyphMotif: String {
    case arcs
    case radiant
    case folded
    case dotted
    case wave
    case hybrid
}

struct GlyphSignature: Equatable {
    var emotion: DayEmotion
    var theme: DayTheme
    var energy: Double
    var seed: Int
    var motif: GlyphMotif
    var strokeCount: Int
    var rotation: Double

    init(analysis: EmotionAnalysis, seed: Int) {
        self.emotion = analysis.emotion
        self.theme = analysis.theme
        self.energy = min(max(analysis.energy, 0), 1)
        self.seed = seed
        self.motif = Self.motif(for: analysis.emotion)
        self.strokeCount = 5 + Int((min(max(analysis.energy, 0), 1) * 9).rounded())
        self.rotation = Double(abs(seed % 360))
    }

    static func seed(for text: String, date: Date, calendar: Calendar = .current) -> Int {
        let day = calendar.startOfDay(for: date).timeIntervalSince1970
        var hash = 5381
        for scalar in text.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        hash = hash &+ Int(day)
        return abs(hash)
    }

    static func motif(for emotion: DayEmotion) -> GlyphMotif {
        switch emotion {
        case .calm: .arcs
        case .joy: .wave
        case .low: .dotted
        case .anxious: .folded
        case .excited: .radiant
        case .tired: .dotted
        case .grateful: .arcs
        case .mixed: .hybrid
        }
    }

    var primaryColor: Color {
        switch emotion {
        case .calm: Color(red: 0.24, green: 0.58, blue: 0.52)
        case .joy: Color(red: 0.89, green: 0.66, blue: 0.24)
        case .low: Color(red: 0.38, green: 0.49, blue: 0.64)
        case .anxious: Color(red: 0.43, green: 0.42, blue: 0.72)
        case .excited: Color(red: 0.78, green: 0.31, blue: 0.29)
        case .tired: Color(red: 0.53, green: 0.49, blue: 0.43)
        case .grateful: Color(red: 0.82, green: 0.51, blue: 0.24)
        case .mixed: Color(red: 0.28, green: 0.48, blue: 0.55)
        }
    }

    var secondaryColor: Color {
        switch emotion {
        case .calm: Color(red: 0.77, green: 0.86, blue: 0.81)
        case .joy: Color(red: 0.96, green: 0.84, blue: 0.48)
        case .low: Color(red: 0.73, green: 0.78, blue: 0.84)
        case .anxious: Color(red: 0.72, green: 0.69, blue: 0.86)
        case .excited: Color(red: 0.91, green: 0.58, blue: 0.43)
        case .tired: Color(red: 0.76, green: 0.71, blue: 0.64)
        case .grateful: Color(red: 0.94, green: 0.75, blue: 0.42)
        case .mixed: Color(red: 0.82, green: 0.74, blue: 0.50)
        }
    }
}
