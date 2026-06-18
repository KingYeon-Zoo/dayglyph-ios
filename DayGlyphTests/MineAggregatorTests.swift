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

        #expect(achievements.first(where: { $0.id == "first-planet" })?.isUnlocked == true)
        #expect(achievements.first(where: { $0.id == "seven-days" })?.isUnlocked == true)
        #expect(achievements.first(where: { $0.id == "seven-days" })?.description.contains("连续") == false)
    }

    @Test func historySearchMatchesTextRecipeAndKeywords() {
        let entry = DayEntry(date: .now, text: "今天在公园散步", analysis: EmotionAnalyzer().analyze("今天很平静"), glyphSeed: 1)
        #expect(MineAggregator.filteredEntries([entry], query: "公园").count == 1)
        #expect(MineAggregator.filteredEntries([entry], query: "不存在").isEmpty)
    }
}
