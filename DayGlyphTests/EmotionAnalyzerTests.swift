import Testing
@testable import DayGlyph

struct EmotionAnalyzerTests {
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

    @Test func emptyTextFallsBackToMixedUnknown() {
        let result = EmotionAnalyzer().analyze("   ")

        #expect(result.emotion == .mixed)
        #expect(result.theme == .unknown)
        #expect(result.energy == 0.3)
        #expect(result.keywords.isEmpty)
    }
}
