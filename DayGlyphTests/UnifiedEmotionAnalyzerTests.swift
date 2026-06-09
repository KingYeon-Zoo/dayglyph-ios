import Testing
@testable import DayGlyph

struct UnifiedEmotionAnalyzerTests {
    @MainActor
    @Test func fallsBackToLocalRulesWhenFoundationAnalyzerUnavailable() async {
        let analyzer = UnifiedEmotionAnalyzer(
            foundationAnalyzer: UnavailableFoundationAnalyzer(),
            localAnalyzer: EmotionAnalyzer()
        )

        let result = await analyzer.analyze("今天很早就把事情搞完了，松了一口气。")

        #expect(result.source == .localRules || result.source == .fallback)
        #expect(result.emotion != .mixed || result.confidence >= 0.45)
        #expect(result.explanation.isEmpty == false)
    }
}

private struct UnavailableFoundationAnalyzer: FoundationEmotionAnalyzing {
    func analyze(_ text: String) async throws -> EmotionAnalysis {
        throw FoundationEmotionAnalyzerError.unavailable("测试中模拟 Foundation Models 不可用。")
    }
}
