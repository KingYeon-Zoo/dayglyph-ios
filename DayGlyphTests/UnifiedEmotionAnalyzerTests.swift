import Testing
@testable import DayGlyph

struct UnifiedEmotionAnalyzerTests {
    @Test func fallbackCopyDoesNotClaimAppleIntelligenceParticipation() {
        #expect(AnalysisSource.fallback.title == "已使用本地回退")
        #expect(AnalysisSource.fallback.title.contains("已参与") == false)
    }

    @MainActor
    @Test func propagatesFoundationModelFailureInsteadOfUsingKeywordRules() async {
        let analyzer = UnifiedEmotionAnalyzer(
            foundationAnalyzer: UnavailableFoundationAnalyzer()
        )

        do {
            _ = try await analyzer.analyze("今天很早就把事情搞完了，松了一口气。")
            Issue.record("Foundation Models 失败时不应静默退回关键词规则。")
        } catch {
            #expect(error is FoundationEmotionAnalyzerError)
        }
    }
}

private struct UnavailableFoundationAnalyzer: FoundationEmotionAnalyzing {
    func analyze(_ text: String) async throws -> EmotionAnalysis {
        throw FoundationEmotionAnalyzerError.unavailable("测试中模拟 Foundation Models 不可用。")
    }
}
