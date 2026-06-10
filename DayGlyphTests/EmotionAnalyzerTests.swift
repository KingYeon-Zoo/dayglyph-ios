import Testing
@testable import DayGlyph

struct EmotionAnalyzerTests {
    @Test func detectsCompletionReliefWithoutUnknown() {
        let result = EmotionAnalyzer().analyze("今天很早就把那个事情搞完了，整个人松了一口气。")

        #expect(result.emotion == .calm || result.emotion == .joy)
        #expect(result.theme == .work)
        #expect(result.confidence >= 0.55)
        #expect(result.explanation.isEmpty == false)
        #expect(result.source == .localRules)
    }

    @Test func detectsFoggyMixedState() {
        let result = EmotionAnalyzer().analyze("说不上来，脑子很乱，但还是把今天撑过去了。")

        #expect(result.emotion == .anxious || result.emotion == .mixed)
        #expect(result.theme.title.isEmpty == false)
        #expect(result.confidence >= 0.45)
        #expect(result.energy >= 0.45)
    }

    @Test func detectsGratefulWorkEntry() {
        let result = EmotionAnalyzer().analyze("今天终于完成了项目，特别感谢同事帮我一起收尾。")

        #expect(result.emotion == .grateful)
        #expect(result.theme == .work)
        #expect(result.energy >= 0.45)
        #expect(result.keywords.contains("项目") || result.keywords.contains("感谢"))
    }

    @Test func detectsTiredLowEnergyEntry() {
        let result = EmotionAnalyzer().analyze("今天很累，睡得不好，什么都提不起劲。")

        #expect(result.emotion == .tired)
        #expect(result.theme == .rest)
        #expect(result.energy < 0.5)
    }

    @Test func ordinaryTextDoesNotFallBackToUnknownEmotion() {
        let result = EmotionAnalyzer().analyze("今天去拿了快递，回来的路上买了杯热咖啡。")

        #expect(result.emotion != .mixed || result.confidence >= 0.4)
        #expect(result.theme.title.isEmpty == false)
        #expect(result.explanation.isEmpty == false)
    }

    @Test func emptyTextFallsBackToMixedUnknown() {
        let result = EmotionAnalyzer().analyze("   ")

        #expect(result.emotion == .mixed)
        #expect(result.theme == .unknown)
        #expect(result.energy == 0.3)
        #expect(result.keywords.isEmpty)
        #expect(result.source == .fallback)
    }

    @Test func legacyAnalyzerProducesNormalizedEmotionWeights() {
        let result = EmotionAnalyzer().analyze("今天很累，也有一点焦虑。")

        #expect(abs(result.emotionWeights.reduce(0) { $0 + $1.value } - 1) < 0.000_001)
        #expect(result.topEmotionWeights.isEmpty == false)
        #expect((-1...1).contains(result.valence))
        #expect((0...1).contains(result.arousal))
        #expect((-1...1).contains(result.dominance))
    }
}
