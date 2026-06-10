import Testing
@testable import DayGlyph

@MainActor
struct EmotionAnalysisTests {
    @Test func clampsContinuousDimensionsAndConfidence() {
        let analysis = EmotionAnalysis(
            valence: -2,
            arousal: 1.4,
            dominance: 3,
            emotionWeights: [
                EmotionWeight(anchor: .angry, value: 1)
            ],
            theme: .work,
            keywords: ["冲突"],
            confidence: 1.5,
            explanation: "情绪张力较高。",
            source: .foundationModel
        )

        #expect(analysis.valence == -1)
        #expect(analysis.arousal == 1)
        #expect(analysis.dominance == 1)
        #expect(analysis.confidence == 1)
    }

    @Test func normalizesWeightsAndSortsTopThree() {
        let analysis = EmotionAnalysis(
            valence: -0.4,
            arousal: 0.8,
            dominance: 0.2,
            emotionWeights: [
                EmotionWeight(anchor: .anxious, value: 2),
                EmotionWeight(anchor: .angry, value: 4),
                EmotionWeight(anchor: .confused, value: 1),
                EmotionWeight(anchor: .calm, value: -1)
            ],
            theme: .relationship,
            keywords: ["沟通"],
            confidence: 0.8,
            explanation: "生气与焦虑交织。",
            source: .foundationModel
        )

        #expect(abs(analysis.emotionWeights.reduce(0) { $0 + $1.value } - 1) < 0.000_001)
        #expect(analysis.primaryEmotion == .angry)
        #expect(analysis.topEmotionWeights.map(\.anchor) == [.angry, .anxious, .confused])
        #expect(analysis.emotionWeights.first(where: { $0.anchor == .calm })?.value == 0)
    }

    @Test func zeroWeightsFallBackToConfusedWithLowConfidence() {
        let analysis = EmotionAnalysis(
            valence: 0,
            arousal: 0.3,
            dominance: 0,
            emotionWeights: EmotionAnchor.allCases.map {
                EmotionWeight(anchor: $0, value: 0)
            },
            theme: .unknown,
            keywords: [],
            confidence: 0.8,
            explanation: "信息不足。",
            source: .fallback
        )

        #expect(analysis.primaryEmotion == .confused)
        #expect(analysis.topEmotionWeights == [EmotionWeight(anchor: .confused, value: 1)])
        #expect(analysis.confidence <= 0.35)
    }
}
