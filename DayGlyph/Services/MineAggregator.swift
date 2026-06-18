import Foundation

nonisolated enum MineAggregator {
    static func filteredEntries(_ entries: [DayEntry], query: String) -> [DayEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries.sorted { $0.date > $1.date } }
        return entries.filter {
            [$0.text, $0.emotionRecipe.name, $0.moodWeather.type, $0.keywords.joined(separator: " ")]
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(trimmed)
        }
        .sorted { $0.date > $1.date }
    }

    static func achievements(
        entries: [DayEntry],
        actions: [ActionInstance],
        responses: [ActionResponse],
        calendar: Calendar = .current
    ) -> [EmotionAchievement] {
        let days = Set(entries.map { calendar.startOfDay(for: $0.date) }).count
        let anchors = Set(entries.map { $0.primaryEmotion.rawValue }).count
        let completedActions = actions.filter { $0.state == .completed }.count
        return [
            EmotionAchievement(id: "first-planet", title: "第一颗星球", description: "完成第一条情绪记录", symbol: "sparkles", progress: days, target: 1),
            EmotionAchievement(id: "seven-days", title: "七日足迹", description: "累计记录 7 天，不要求连续", symbol: "circle.hexagongrid.fill", progress: days, target: 7),
            EmotionAchievement(id: "four-anchors", title: "完整体验者", description: "记录覆盖 4 类情绪锚点", symbol: "circle.grid.2x2.fill", progress: anchors, target: 4),
            EmotionAchievement(id: "small-steps", title: "小步收藏家", description: "累计完成 8 个微行动", symbol: "figure.walk", progress: completedActions, target: 8),
            EmotionAchievement(id: "echoes", title: "回声记录者", description: "累计留下 3 次行动感受", symbol: "dot.radiowaves.left.and.right", progress: responses.count, target: 3)
        ]
    }
}
