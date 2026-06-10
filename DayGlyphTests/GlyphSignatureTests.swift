import Foundation
import Testing
@testable import DayGlyph

@MainActor
struct GlyphSignatureTests {
    @Test func sameInputsProduceSameSeed() {
        let date = Date(timeIntervalSince1970: 1_780_876_800)
        let first = GlyphSignature.seed(for: "今天很平静", date: date)
        let second = GlyphSignature.seed(for: "今天很平静", date: date)

        #expect(first == second)
    }

    @Test func sameAnalysisAndSeedProduceSameSignature() {
        let analysis = makeAnalysis(
            valence: -0.72,
            arousal: 0.86,
            dominance: 0.55,
            weights: [.angry: 0.7, .anxious: 0.3]
        )

        let first = GlyphSignature(analysis: analysis, seed: 42)
        let second = GlyphSignature(analysis: analysis, seed: 42)

        #expect(first == second)
    }

    @Test func angerAndAnxietyHaveDifferentStructuralGrammar() {
        let anger = GlyphSignature(
            analysis: makeAnalysis(
                valence: -0.7,
                arousal: 0.85,
                dominance: 0.5,
                weights: [.angry: 1]
            ),
            seed: 42
        )
        let anxiety = GlyphSignature(
            analysis: makeAnalysis(
                valence: -0.7,
                arousal: 0.85,
                dominance: -0.5,
                weights: [.anxious: 1]
            ),
            seed: 42
        )

        #expect(anger.boundary.angularity > anxiety.boundary.angularity)
        #expect(anger.rhythm.burst > anxiety.rhythm.burst)
        #expect(anxiety.boundary.eccentricity > anger.boundary.eccentricity)
        #expect(anxiety.trajectory.oscillation > anger.trajectory.oscillation)
    }

    @Test func excitementRisesWhileSadnessSinks() {
        let excitement = GlyphSignature(
            analysis: makeAnalysis(
                valence: 0.78,
                arousal: 0.88,
                dominance: 0.42,
                weights: [.excited: 1]
            ),
            seed: 12
        )
        let sadness = GlyphSignature(
            analysis: makeAnalysis(
                valence: -0.78,
                arousal: 0.28,
                dominance: -0.55,
                weights: [.sad: 1]
            ),
            seed: 12
        )

        #expect(excitement.trajectory.verticalBias > 0)
        #expect(excitement.rhythm.burst > sadness.rhythm.burst)
        #expect(sadness.trajectory.verticalBias < 0)
        #expect(sadness.core.offsetY > excitement.core.offsetY)
    }

    @Test func arousalControlsRhythmDensityWithinBounds() {
        let low = GlyphSignature(
            analysis: makeAnalysis(
                valence: 0.1,
                arousal: 0.1,
                dominance: 0.1,
                weights: [.calm: 1]
            ),
            seed: 1
        )
        let high = GlyphSignature(
            analysis: makeAnalysis(
                valence: 0.1,
                arousal: 0.95,
                dominance: 0.1,
                weights: [.excited: 1]
            ),
            seed: 1
        )

        #expect(low.rhythm.count >= 2)
        #expect(high.rhythm.count <= 12)
        #expect(high.rhythm.count > low.rhythm.count)
    }

    @Test func seedOnlyChangesBoundedMicroVariation() {
        let analysis = makeAnalysis(
            valence: 0.35,
            arousal: 0.5,
            dominance: 0.4,
            weights: [.relief: 0.7, .calm: 0.3]
        )
        let first = GlyphSignature(analysis: analysis, seed: 10)
        let second = GlyphSignature(analysis: analysis, seed: 999)

        #expect(first.boundary.angularity == second.boundary.angularity)
        #expect(first.trajectory.oscillation == second.trajectory.oscillation)
        #expect(abs(first.microRotation - second.microRotation) <= 6)
        #expect(abs(first.microOffset - second.microOffset) <= 0.04)
    }

    private func makeAnalysis(
        valence: Double,
        arousal: Double,
        dominance: Double,
        weights: [EmotionAnchor: Double]
    ) -> EmotionAnalysis {
        EmotionAnalysis(
            valence: valence,
            arousal: arousal,
            dominance: dominance,
            emotionWeights: weights.map { EmotionWeight(anchor: $0.key, value: $0.value) },
            theme: .unknown,
            keywords: [],
            confidence: 0.8,
            explanation: "测试夹具。",
            source: .foundationModel
        )
    }
}
