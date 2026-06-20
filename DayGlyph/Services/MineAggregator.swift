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
        liveAchievements(entries: entries, actions: actions, responses: responses, calendar: calendar)
            + showcaseAchievements
    }

    /// 接真实统计、可真触发的成就（约 6 个）。演示数据进来即可真解锁。
    static func liveAchievements(
        entries: [DayEntry],
        actions: [ActionInstance],
        responses: [ActionResponse],
        calendar: Calendar = .current
    ) -> [EmotionAchievement] {
        let days = Set(entries.map { calendar.startOfDay(for: $0.date) }).count
        let anchors = Set(entries.map { $0.primaryEmotion.rawValue }).count
        let completedActions = actions.filter { $0.state == .completed }.count
        return [
            EmotionAchievement(id: "first-planet", title: "第一颗星球", description: "完成第一条情绪记录", symbol: "sparkles", category: .record, rarity: .common, progress: days, target: 1),
            EmotionAchievement(id: "seven-days", title: "七日足迹", description: "累计记录 7 天，不计较中间是否间断", symbol: "circle.hexagongrid.fill", category: .record, rarity: .rare, progress: days, target: 7),
            EmotionAchievement(id: "four-anchors", title: "完整体验者", description: "记录覆盖 4 类情绪锚点", symbol: "circle.grid.2x2.fill", category: .explore, rarity: .rare, progress: anchors, target: 4),
            EmotionAchievement(id: "spectrum-five", title: "情绪光谱", description: "记录覆盖 5 类情绪锚点", symbol: "circle.hexagongrid.circle.fill", category: .explore, rarity: .epic, progress: anchors, target: 5),
            EmotionAchievement(id: "small-steps", title: "小步收藏家", description: "累计完成 8 个微行动", symbol: "figure.walk", category: .growth, rarity: .common, progress: completedActions, target: 8),
            EmotionAchievement(id: "echoes", title: "回声记录者", description: "累计留下 3 次行动感受", symbol: "dot.radiowaves.left.and.right", category: .connection, rarity: .common, progress: responses.count, target: 3)
        ]
    }

    /// 纯前端展示成就（约 15 个）：不接真实统计，按预设解锁态呈现，凑足成就墙张力。
    static let showcaseAchievements: [EmotionAchievement] = [
        .init(id: "full-moon", title: "满月轨迹", description: "累计记录满 30 天", symbol: "moon.stars.fill", category: .record, rarity: .rare, kind: .showcase, showcaseUnlocked: true),
        .init(id: "hundred-steps", title: "百步旅人", description: "累计完成 100 个微行动", symbol: "shoeprints.fill", category: .growth, rarity: .epic, kind: .showcase, showcaseUnlocked: false),
        .init(id: "night-writer", title: "深夜记录者", description: "在深夜留下 10 次记录", symbol: "moon.zzz.fill", category: .record, rarity: .rare, kind: .showcase, showcaseUnlocked: true),
        .init(id: "dawn-writer", title: "晨光记录者", description: "在清晨留下 10 次记录", symbol: "sunrise.fill", category: .record, rarity: .rare, kind: .showcase, showcaseUnlocked: false),
        .init(id: "four-seasons", title: "四季轮转", description: "记录跨越春夏秋冬四季", symbol: "leaf.fill", category: .explore, rarity: .epic, kind: .showcase, showcaseUnlocked: false),
        .init(id: "calmest-day", title: "最平静的一天", description: "捕捉到一次极致的平静", symbol: "wind", category: .rareMoment, rarity: .rare, kind: .showcase, showcaseUnlocked: true),
        .init(id: "highest-day", title: "最高涨的一天", description: "捕捉到一次能量的顶点", symbol: "bolt.fill", category: .rareMoment, rarity: .rare, kind: .showcase, showcaseUnlocked: true),
        .init(id: "all-themes", title: "万象主题", description: "记录覆盖全部生活主题", symbol: "square.grid.3x3.fill", category: .explore, rarity: .epic, kind: .showcase, showcaseUnlocked: false),
        .init(id: "star-collector", title: "星海收藏家", description: "收集 50 颗日星球", symbol: "sparkles.rectangle.stack.fill", category: .explore, rarity: .epic, kind: .showcase, showcaseUnlocked: false),
        .init(id: "echo-resonance", title: "回声共鸣者", description: "累计留下 30 次行动感受", symbol: "waveform.path.ecg", category: .connection, rarity: .rare, kind: .showcase, showcaseUnlocked: false),
        .init(id: "warm-keeper", title: "温暖收集者", description: "记录 20 次温暖与被理解的时刻", symbol: "heart.circle.fill", category: .connection, rarity: .rare, kind: .showcase, showcaseUnlocked: true),
        .init(id: "streak-30", title: "坚持里程碑", description: "连续记录 30 天", symbol: "flame.fill", category: .growth, rarity: .epic, kind: .showcase, showcaseUnlocked: false),
        .init(id: "rainbow-week", title: "情绪彩虹", description: "一周内体验 7 种不同情绪", symbol: "rainbow", category: .explore, rarity: .rare, kind: .showcase, showcaseUnlocked: true),
        .init(id: "letter-keeper", title: "岁月寄信人", description: "写下并收到一封时光信", symbol: "envelope.open.fill", category: .growth, rarity: .epic, kind: .showcase, showcaseUnlocked: false),
        .init(id: "year-promise", title: "一年之约", description: "陪伴 DayGlyph 走过一整年", symbol: "crown.fill", category: .rareMoment, rarity: .legendary, kind: .showcase, showcaseUnlocked: false)
    ]
}
