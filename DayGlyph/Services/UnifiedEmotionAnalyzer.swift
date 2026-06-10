import Foundation

struct UnifiedEmotionAnalyzer {
    var foundationAnalyzer: any FoundationEmotionAnalyzing

    init(
        foundationAnalyzer: any FoundationEmotionAnalyzing = FoundationEmotionAnalyzer()
    ) {
        self.foundationAnalyzer = foundationAnalyzer
    }

    func analyze(_ text: String) async throws -> EmotionAnalysis {
        try await foundationAnalyzer.analyze(text)
    }
}
