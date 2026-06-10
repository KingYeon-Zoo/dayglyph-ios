import Testing
@testable import DayGlyph

struct FoundationEmotionOutputTests {
    @Test func convertsDimensionalScoresAndEmotionWeights() {
        let output = FoundationEmotionOutput(
            valence: -0.72,
            arousal: 0.86,
            dominance: 0.48,
            calmWeight: 0,
            joyWeight: 0,
            gratefulWeight: 0,
            reliefWeight: 0,
            hopefulWeight: 0,
            excitedWeight: 0.08,
            angryWeight: 0.62,
            anxiousWeight: 0.30,
            sadWeight: 0,
            tiredWeight: 0,
            lonelyWeight: 0,
            confusedWeight: 0,
            themeRawValue: "work",
            keywords: ["冲突", "进度"],
            confidence: 0.84,
            explanation: "受阻后的愤怒伴随明显焦虑。"
        )

        let analysis = output.analysis

        #expect(analysis.valence == -0.72)
        #expect(analysis.arousal == 0.86)
        #expect(analysis.dominance == 0.48)
        #expect(analysis.primaryEmotion == .angry)
        #expect(analysis.topEmotionWeights.map(\.anchor) == [.angry, .anxious, .excited])
        #expect(analysis.theme == .work)
        #expect(analysis.source == .foundationModel)
    }
}
