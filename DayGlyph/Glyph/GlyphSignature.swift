import Foundation
import SwiftUI

struct GlyphPalette: Equatable {
    var background: Color
    var primary: Color
    var secondary: Color
    var accent: Color
}

struct GlyphBoundarySignature: Equatable {
    var closure: Double
    var roundness: Double
    var eccentricity: Double
    var thickness: Double
    var angularity: Double
}

struct GlyphTrajectorySignature: Equatable {
    var verticalBias: Double
    var openness: Double
    var curvature: Double
    var oscillation: Double
    var crossing: Double
}

struct GlyphCoreSignature: Equatable {
    var scale: Double
    var offsetX: Double
    var offsetY: Double
    var isolation: Double
}

struct GlyphRhythmSignature: Equatable {
    var count: Int
    var regularity: Double
    var radialSpread: Double
    var burst: Double
}

struct GlyphSignature: Equatable {
    var primaryEmotion: EmotionAnchor
    var energy: Double
    var confidence: Double
    var seed: Int
    var boundary: GlyphBoundarySignature
    var trajectory: GlyphTrajectorySignature
    var core: GlyphCoreSignature
    var rhythm: GlyphRhythmSignature
    var microRotation: Double
    var microOffset: Double
    var palette: GlyphPalette

    init(analysis: EmotionAnalysis, seed: Int) {
        let clampedEnergy = analysis.arousal
        let dominance = (analysis.dominance + 1) / 2
        let calm = Self.weight(.calm, in: analysis)
        let relief = Self.weight(.relief, in: analysis)
        let hopeful = Self.weight(.hopeful, in: analysis)
        let excited = Self.weight(.excited, in: analysis)
        let angry = Self.weight(.angry, in: analysis)
        let anxious = Self.weight(.anxious, in: analysis)
        let sad = Self.weight(.sad, in: analysis)
        let tired = Self.weight(.tired, in: analysis)
        let lonely = Self.weight(.lonely, in: analysis)
        let confused = Self.weight(.confused, in: analysis)

        var random = SeededRandom(seed: seed)
        let microRotation = (random.next() - 0.5) * 6
        let microOffset = (random.next() - 0.5) * 0.04

        self.primaryEmotion = analysis.primaryEmotion
        self.energy = clampedEnergy
        self.confidence = analysis.confidence
        self.seed = seed
        self.boundary = GlyphBoundarySignature(
            closure: Self.clamp(0.54 + analysis.dominance * 0.16 + angry * 0.18 - relief * 0.20),
            roundness: Self.clamp(0.78 + calm * 0.18 + relief * 0.08 - angry * 0.55 - confused * 0.18),
            eccentricity: Self.clamp(0.06 + (1 - dominance) * 0.14 + anxious * 0.48 + confused * 0.18 - calm * 0.05),
            thickness: Self.clamp(0.34 + clampedEnergy * 0.28 + angry * 0.22 + tired * 0.16),
            angularity: Self.clamp(0.06 + angry * 0.78 + confused * 0.22)
        )
        self.trajectory = GlyphTrajectorySignature(
            verticalBias: Self.clampSigned(
                analysis.valence * 0.45 + excited * 0.35 + hopeful * 0.30 - sad * 0.45 - tired * 0.18
            ),
            openness: Self.clamp(0.42 + max(analysis.valence, 0) * 0.22 + relief * 0.34 + hopeful * 0.18 - sad * 0.22),
            curvature: Self.clamp(0.68 + calm * 0.20 + relief * 0.12 - angry * 0.42),
            oscillation: Self.clamp(0.06 + clampedEnergy * 0.12 + anxious * 0.65 + confused * 0.42),
            crossing: Self.clamp(0.04 + confused * 0.72 + anxious * 0.12)
        )
        self.core = GlyphCoreSignature(
            scale: Self.clamp(0.18 + dominance * 0.10 + angry * 0.08 - lonely * 0.06),
            offsetX: Self.clampSigned(microOffset + anxious * 0.30 + confused * 0.12),
            offsetY: Self.clampSigned(sad * 0.38 + tired * 0.18 - excited * 0.18 - hopeful * 0.12),
            isolation: Self.clamp(0.18 + lonely * 0.72 + sad * 0.12)
        )
        let rhythmCount = 2 + Int((clampedEnergy * 7).rounded()) + Int((excited * 2).rounded()) - Int((tired * 2).rounded())
        self.rhythm = GlyphRhythmSignature(
            count: min(max(rhythmCount, 2), 12),
            regularity: Self.clamp(0.84 + calm * 0.12 - anxious * 0.56 - confused * 0.38),
            radialSpread: Self.clamp(0.42 + clampedEnergy * 0.24 + excited * 0.12 - lonely * 0.12),
            burst: Self.clamp(0.08 + clampedEnergy * 0.18 + angry * 0.65 + excited * 0.55 - tired * 0.10)
        )
        self.microRotation = microRotation
        self.microOffset = microOffset
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

    private static func weight(_ anchor: EmotionAnchor, in analysis: EmotionAnalysis) -> Double {
        analysis.emotionWeights.first(where: { $0.anchor == anchor })?.value ?? 0
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private static func clampSigned(_ value: Double) -> Double {
        min(max(value, -1), 1)
    }
}
