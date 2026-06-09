import Foundation
import Testing
@testable import DayGlyph

struct GlyphSignatureTests {
    @Test func sameInputsProduceSameSeed() {
        let date = Date(timeIntervalSince1970: 1_780_876_800)
        let first = GlyphSignature.seed(for: "今天很平静", date: date)
        let second = GlyphSignature.seed(for: "今天很平静", date: date)

        #expect(first == second)
    }

    @Test func signatureUsesEmotionAndEnergyForGeometry() {
        let analysis = EmotionAnalysis(
            emotion: .excited,
            theme: .work,
            energy: 0.9,
            keywords: ["项目"],
            confidence: 0.8,
            explanation: "能量较高。",
            source: .localRules
        )
        let signature = GlyphSignature(analysis: analysis, seed: 42)

        #expect(signature.emotion == .excited)
        #expect(signature.density >= 0.7)
        #expect(signature.baseShape == .radiantSeal)
        #expect(signature.accentCount <= 9)
    }

    @Test func lowEnergyStaysSparse() {
        let analysis = EmotionAnalysis(
            emotion: .tired,
            theme: .rest,
            energy: 0.2,
            keywords: ["休息"],
            confidence: 0.7,
            explanation: "疲惫。",
            source: .localRules
        )
        let signature = GlyphSignature(analysis: analysis, seed: 12)

        #expect(signature.density <= 0.45)
        #expect(signature.accentCount <= 5)
    }
}
