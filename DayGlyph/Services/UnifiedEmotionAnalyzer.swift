import Foundation

struct UnifiedEmotionAnalyzer {
    var foundationAnalyzer: any FoundationEmotionAnalyzing
    var localAnalyzer: EmotionAnalyzer

    init(
        foundationAnalyzer: any FoundationEmotionAnalyzing = FoundationEmotionAnalyzer(),
        localAnalyzer: EmotionAnalyzer = EmotionAnalyzer()
    ) {
        self.foundationAnalyzer = foundationAnalyzer
        self.localAnalyzer = localAnalyzer
    }

    func analyze(_ text: String) async -> EmotionAnalysis {
        do {
            return try await foundationAnalyzer.analyze(text)
        } catch {
            var local = localAnalyzer.analyze(text)
            if local.source == .localRules {
                local.source = .fallback
            }
            return local
        }
    }
}
