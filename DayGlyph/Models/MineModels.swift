import Foundation

/// 成就分组。
nonisolated enum AchievementCategory: String, CaseIterable, Identifiable, Sendable {
    case record       // 记录
    case explore      // 探索
    case growth       // 成长
    case connection   // 连结
    case rareMoment   // 稀有时刻

    var id: String { rawValue }

    var title: String {
        switch self {
        case .record: "记录"
        case .explore: "探索"
        case .growth: "成长"
        case .connection: "连结"
        case .rareMoment: "稀有时刻"
        }
    }
}

/// 成就稀有度（四档），决定卡片配色与光效强度。
nonisolated enum AchievementRarity: String, CaseIterable, Identifiable, Sendable {
    case common       // 普通
    case rare         // 稀有
    case epic         // 史诗
    case legendary    // 传说

    var id: String { rawValue }

    var title: String {
        switch self {
        case .common: "普通"
        case .rare: "稀有"
        case .epic: "史诗"
        case .legendary: "传说"
        }
    }

    /// 光效强度（0…1），UI 用于描边宽度、光晕半径等。
    var glowStrength: Double {
        switch self {
        case .common: 0.0
        case .rare: 0.35
        case .epic: 0.6
        case .legendary: 1.0
        }
    }
}

/// 成就类型：`live` 接真实统计、可真触发；`showcase` 纯前端展示，按预设解锁态呈现。
nonisolated enum AchievementKind: Sendable, Equatable {
    case live
    case showcase
}

nonisolated struct EmotionAchievement: Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var symbol: String
    var category: AchievementCategory
    var rarity: AchievementRarity
    var kind: AchievementKind
    var progress: Int
    var target: Int
    /// 仅 `showcase` 使用：预设解锁态。
    var showcaseUnlocked: Bool

    init(
        id: String,
        title: String,
        description: String,
        symbol: String,
        category: AchievementCategory,
        rarity: AchievementRarity,
        kind: AchievementKind = .live,
        progress: Int = 0,
        target: Int = 1,
        showcaseUnlocked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.symbol = symbol
        self.category = category
        self.rarity = rarity
        self.kind = kind
        self.progress = progress
        self.target = target
        self.showcaseUnlocked = showcaseUnlocked
    }

    var isUnlocked: Bool {
        switch kind {
        case .live: progress >= target
        case .showcase: showcaseUnlocked
        }
    }

    /// 进度比例（0…1），用于进度条。
    var progressFraction: Double {
        guard target > 0 else { return isUnlocked ? 1 : 0 }
        return min(1, Double(progress) / Double(target))
    }
}
