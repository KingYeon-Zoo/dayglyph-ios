import Foundation
import Testing
@testable import DayGlyph

struct MineAggregatorTests {
    @Test func achievementsUseCumulativeDaysNotStreaks() {
        let calendar = Calendar(identifier: .gregorian)
        let entries = (0 ..< 7).map { index in
            DayEntry(
                date: calendar.date(byAdding: .day, value: -(index * 3), to: .now)!,
                text: "累计记录 \(index)",
                analysis: EmotionAnalyzer().analyze("平静"),
                glyphSeed: index
            )
        }
        let achievements = MineAggregator.achievements(entries: entries, actions: [], responses: [], calendar: calendar)

        #expect(achievements.count == 21)
        #expect(achievements.first(where: { $0.id == "first-planet" })?.isUnlocked == true)
        #expect(achievements.first(where: { $0.id == "seven-days" })?.isUnlocked == true)
        #expect(achievements.first(where: { $0.id == "seven-days" })?.description.contains("连续") == false)
        // showcase 成就按预设态呈现，不依赖统计。
        #expect(achievements.contains { $0.kind == .showcase })
        #expect(achievements.filter { $0.kind == .live }.count == 6)
    }

    @Test func liveAchievementUnlocksWithAnchorDiversity() {
        let calendar = Calendar(identifier: .gregorian)
        let anchors: [EmotionAnchor] = [.calm, .joy, .sad, .angry, .hopeful]
        let entries = anchors.enumerated().map { index, anchor in
            DayEntry(
                date: calendar.date(byAdding: .day, value: -index, to: .now)!,
                text: "记录 \(index)",
                analysis: EmotionAnalysis(
                    valence: 0, arousal: 0.5, dominance: 0,
                    emotionWeights: [EmotionWeight(anchor: anchor, value: 1)],
                    theme: .unknown, keywords: []
                ),
                glyphSeed: index
            )
        }
        let achievements = MineAggregator.achievements(entries: entries, actions: [], responses: [], calendar: calendar)
        #expect(achievements.first(where: { $0.id == "four-anchors" })?.isUnlocked == true)
        #expect(achievements.first(where: { $0.id == "spectrum-five" })?.isUnlocked == true)
    }

    @Test func historySearchMatchesTextRecipeAndKeywords() {
        let entry = DayEntry(date: .now, text: "今天在公园散步", analysis: EmotionAnalyzer().analyze("今天很平静"), glyphSeed: 1)
        #expect(MineAggregator.filteredEntries([entry], query: "公园").count == 1)
        #expect(MineAggregator.filteredEntries([entry], query: "不存在").isEmpty)
    }
}
