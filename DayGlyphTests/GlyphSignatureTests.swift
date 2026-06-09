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

    @Test func signatureUsesEmotionAndEnergy() {
        let analysis = EmotionAnalysis(emotion: .excited, theme: .work, energy: 0.9, keywords: ["项目"])
        let signature = GlyphSignature(analysis: analysis, seed: 42)

        #expect(signature.emotion == .excited)
        #expect(signature.strokeCount >= 10)
        #expect(signature.motif == .radiant)
    }
}
