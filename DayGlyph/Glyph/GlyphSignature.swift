import Foundation
import SwiftUI

enum GlyphBaseShape: String, Equatable {
    case calmRing
    case warmOrbit
    case lowPool
    case offsetOrbit
    case radiantSeal
    case quietBlock
    case heldArc
    case layered
}

enum GlyphAccentShape: String, Equatable {
    case dot
    case capsule
    case arc
    case notch
}

struct GlyphPalette: Equatable {
    var background: Color
    var primary: Color
    var secondary: Color
    var accent: Color
}

struct GlyphSignature: Equatable {
    var emotion: DayEmotion
    var theme: DayTheme
    var energy: Double
    var confidence: Double
    var seed: Int
    var baseShape: GlyphBaseShape
    var accentShape: GlyphAccentShape
    var density: Double
    var accentCount: Int
    var rotation: Double
    var palette: GlyphPalette

    init(analysis: EmotionAnalysis, seed: Int) {
        let clampedEnergy = min(max(analysis.energy, 0), 1)
        self.emotion = analysis.emotion
        self.theme = analysis.theme
        self.energy = clampedEnergy
        self.confidence = min(max(analysis.confidence, 0), 1)
        self.seed = seed
        self.baseShape = Self.baseShape(for: analysis.emotion)
        self.accentShape = Self.accentShape(for: analysis.theme)
        self.density = 0.22 + clampedEnergy * 0.68
        self.accentCount = min(max(2 + Int((clampedEnergy * 7).rounded()), 2), 9)
        self.rotation = Double(abs(seed % 360))
        self.palette = Self.palette(for: analysis.emotion)
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

    static func baseShape(for emotion: DayEmotion) -> GlyphBaseShape {
        switch emotion {
        case .calm: .calmRing
        case .joy: .warmOrbit
        case .low: .lowPool
        case .anxious: .offsetOrbit
        case .excited: .radiantSeal
        case .tired: .quietBlock
        case .grateful: .heldArc
        case .mixed: .layered
        }
    }

    static func accentShape(for theme: DayTheme) -> GlyphAccentShape {
        switch theme {
        case .work, .growth: .capsule
        case .relationship, .family: .arc
        case .health, .rest: .dot
        case .creativity: .notch
        case .unknown: .dot
        }
    }

    static func palette(for emotion: DayEmotion) -> GlyphPalette {
        switch emotion {
        case .calm:
            GlyphPalette(
                background: Color(red: 0.91, green: 0.96, blue: 0.93),
                primary: Color(red: 0.10, green: 0.38, blue: 0.34),
                secondary: Color(red: 0.52, green: 0.73, blue: 0.66),
                accent: Color(red: 0.83, green: 0.70, blue: 0.42)
            )
        case .joy:
            GlyphPalette(
                background: Color(red: 1.00, green: 0.96, blue: 0.84),
                primary: Color(red: 0.52, green: 0.34, blue: 0.08),
                secondary: Color(red: 0.93, green: 0.70, blue: 0.22),
                accent: Color(red: 0.96, green: 0.52, blue: 0.32)
            )
        case .low:
            GlyphPalette(
                background: Color(red: 0.91, green: 0.94, blue: 0.97),
                primary: Color(red: 0.25, green: 0.34, blue: 0.48),
                secondary: Color(red: 0.57, green: 0.65, blue: 0.75),
                accent: Color(red: 0.78, green: 0.72, blue: 0.60)
            )
        case .anxious:
            GlyphPalette(
                background: Color(red: 0.93, green: 0.92, blue: 0.98),
                primary: Color(red: 0.30, green: 0.29, blue: 0.58),
                secondary: Color(red: 0.59, green: 0.56, blue: 0.78),
                accent: Color(red: 0.82, green: 0.58, blue: 0.45)
            )
        case .excited:
            GlyphPalette(
                background: Color(red: 1.00, green: 0.92, blue: 0.89),
                primary: Color(red: 0.62, green: 0.18, blue: 0.16),
                secondary: Color(red: 0.89, green: 0.43, blue: 0.32),
                accent: Color(red: 0.96, green: 0.74, blue: 0.36)
            )
        case .tired:
            GlyphPalette(
                background: Color(red: 0.94, green: 0.92, blue: 0.88),
                primary: Color(red: 0.36, green: 0.32, blue: 0.27),
                secondary: Color(red: 0.64, green: 0.59, blue: 0.51),
                accent: Color(red: 0.76, green: 0.70, blue: 0.60)
            )
        case .grateful:
            GlyphPalette(
                background: Color(red: 1.00, green: 0.95, blue: 0.87),
                primary: Color(red: 0.48, green: 0.26, blue: 0.08),
                secondary: Color(red: 0.84, green: 0.51, blue: 0.18),
                accent: Color(red: 0.93, green: 0.70, blue: 0.34)
            )
        case .mixed:
            GlyphPalette(
                background: Color(red: 0.94, green: 0.96, blue: 0.94),
                primary: Color(red: 0.18, green: 0.34, blue: 0.37),
                secondary: Color(red: 0.73, green: 0.62, blue: 0.32),
                accent: Color(red: 0.66, green: 0.35, blue: 0.32)
            )
        }
    }

    var primaryColor: Color { palette.primary }
    var secondaryColor: Color { palette.secondary }
}
