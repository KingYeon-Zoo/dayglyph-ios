import Testing
import Foundation
@testable import DayGlyph

/// 响应 → EmotionAnalysis 投影测试（spec 5.1、第 10 节）。
@MainActor
struct GenerationAnalysisMapperTests {

    @Test func projectsEmotionsToLegacyAnchorWeights() {
        let response = GenerationFixtures.validResponse()
        let analysis = GenerationAnalysisMapper.makeAnalysis(from: response)

        // 权重归一化后落在 12 锚点空间。
        #expect(analysis.emotionWeights.count == EmotionAnchor.allCases.count)
        let total = analysis.emotionWeights.reduce(0) { $0 + $1.value }
        #expect(abs(total - 1) < 0.001)
        #expect(analysis.source.rawValue == "cloudModel")
        #expect(!analysis.source.title.contains("Apple"))
    }

    @Test func preservesExistingSourceValues() throws {
        for source in AnalysisSource.allCases {
            let data = try JSONEncoder().encode(source)
            #expect(try JSONDecoder().decode(AnalysisSource.self, from: data) == source)
        }
        #expect(AnalysisSource(rawValue: "foundationModel") == .foundationModel)
        #expect(AnalysisSource.foundationModel.title == "Apple Intelligence 已参与理解")
    }

    @Test func carriesDimensionsThrough() {
        let response = GenerationFixtures.validResponse {
            $0.emotionAnalysis.dimensions.valence = 0.3
            $0.emotionAnalysis.dimensions.arousal = 0.7
            $0.emotionAnalysis.dimensions.dominance = -0.2
        }
        let analysis = GenerationAnalysisMapper.makeAnalysis(from: response)
        #expect(abs(analysis.valence - 0.3) < 0.001)
        #expect(abs(analysis.arousal - 0.7) < 0.001)
        #expect(abs(analysis.dominance - (-0.2)) < 0.001)
    }

    @Test func mapsDepletionFamilyToTiredAnchor() {
        let response = GenerationFixtures.validResponse {
            $0.emotionAnalysis.emotions = [
                EmotionItem(term: "疲惫", family: "depletion", intensity: 0.9, confidence: 0.8, evidence: "累")
            ]
        }
        let analysis = GenerationAnalysisMapper.makeAnalysis(from: response)
        #expect(analysis.primaryEmotion == .tired)
    }

    @Test func keepsRichEmotionsWithoutCollapsing() {
        // 6 个情绪不应退化为单一锚点（多个非零权重）。
        let response = GenerationFixtures.validResponse()
        let analysis = GenerationAnalysisMapper.makeAnalysis(from: response)
        let nonZero = analysis.emotionWeights.filter { $0.value > 0 }
        #expect(nonZero.count >= 3)
    }
}
