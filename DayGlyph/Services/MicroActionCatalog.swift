import Foundation

nonisolated enum MicroActionCatalog {
    static let all: [MicroAction] = [
        MicroAction(id: "one-slow-breath", category: .breathing, title: "慢慢呼吸三次", estimatedMinutes: 1, constraints: ["可以坐着完成", "不需要准备"], difficultyBand: .easiest),
        MicroAction(id: "warm-water", category: .sensory, title: "喝几口温水，留意温度", estimatedMinutes: 2, constraints: ["室内即可", "不需要社交"], difficultyBand: .easiest),
        MicroAction(id: "shoulder-release", category: .movement, title: "放松肩膀，再轻轻转动脖子", estimatedMinutes: 2, constraints: ["原地完成", "动作幅度由你决定"], difficultyBand: .easiest),
        MicroAction(id: "quiet-minute", category: .rest, title: "给自己一分钟不处理任何事", estimatedMinutes: 1, constraints: ["安静片刻", "随时可以结束"], difficultyBand: .easiest),
        MicroAction(id: "name-one-thing", category: .writing, title: "写下一件此刻最占注意力的事", estimatedMinutes: 3, constraints: ["只写给自己", "一句就够"], difficultyBand: .gentle),
        MicroAction(id: "notice-five", category: .sensory, title: "找出眼前五个不同颜色", estimatedMinutes: 3, constraints: ["室内即可", "不需要闭眼"], difficultyBand: .gentle),
        MicroAction(id: "small-stretch", category: .movement, title: "做一次不追求标准的伸展", estimatedMinutes: 4, constraints: ["原地完成", "觉得不适就停止"], difficultyBand: .gentle),
        MicroAction(id: "window-air", category: .outdoors, title: "到门口或窗边感受一会儿空气", estimatedMinutes: 5, constraints: ["可能需要走到室外", "无需运动"], difficultyBand: .gentle),
        MicroAction(id: "send-dot", category: .social, title: "给信任的人发一句简单问候", estimatedMinutes: 3, constraints: ["需要联系他人", "无需解释近况"], difficultyBand: .moderate),
        MicroAction(id: "short-walk", category: .outdoors, title: "走到一个熟悉的地方再回来", estimatedMinutes: 8, constraints: ["需要外出", "不要求步数"], difficultyBand: .moderate),
        MicroAction(id: "kind-note", category: .writing, title: "写一句今天愿意留给自己的话", estimatedMinutes: 5, constraints: ["只写给自己", "不评价好坏"], difficultyBand: .moderate),
        MicroAction(id: "listen-track", category: .rest, title: "完整听一首熟悉的歌", estimatedMinutes: 5, constraints: ["需要声音环境", "不用同时做别的事"], difficultyBand: .gentle)
    ]

    static func recommendations(
        for anchor: EmotionVisualAnchor?,
        disabledCategories: Set<MicroActionCategory>,
        seed: Int,
        limit: Int = 3
    ) -> [MicroAction] {
        let preferred = preferredCategories(for: anchor)
        return all
            .filter { disabledCategories.contains($0.category) == false }
            .sorted { lhs, rhs in
                let lhsRank = preferred.firstIndex(of: lhs.category) ?? preferred.count
                let rhsRank = preferred.firstIndex(of: rhs.category) ?? preferred.count
                if lhsRank != rhsRank { return lhsRank < rhsRank }
                if lhs.difficultyBand != rhs.difficultyBand { return lhs.difficultyBand < rhs.difficultyBand }
                return stableOrder(lhs.id, seed: seed) < stableOrder(rhs.id, seed: seed)
            }
            .prefix(limit)
            .map { $0 }
    }

    static func easierReplacement(
        for current: MicroAction,
        anchor: EmotionVisualAnchor?,
        excluding excludedIDs: Set<String>,
        disabledCategories: Set<MicroActionCategory>,
        seed: Int
    ) -> MicroAction? {
        let available = all.filter {
            excludedIDs.contains($0.id) == false
                && disabledCategories.contains($0.category) == false
                && $0.difficultyBand <= current.difficultyBand
        }
        let preferred = preferredCategories(for: anchor)
        return available.sorted { lhs, rhs in
            if lhs.difficultyBand != rhs.difficultyBand { return lhs.difficultyBand < rhs.difficultyBand }
            let lhsRank = preferred.firstIndex(of: lhs.category) ?? preferred.count
            let rhsRank = preferred.firstIndex(of: rhs.category) ?? preferred.count
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return stableOrder(lhs.id, seed: seed + 17) < stableOrder(rhs.id, seed: seed + 17)
        }.first
    }

    private static func preferredCategories(for anchor: EmotionVisualAnchor?) -> [MicroActionCategory] {
        switch anchor {
        case .anxious, .angry, .confused: [.breathing, .sensory, .movement, .rest]
        case .tired, .sad, .numb: [.rest, .sensory, .movement, .writing]
        case .lonely: [.social, .sensory, .writing, .movement]
        case .joy, .anticipation, .moved, .proud: [.movement, .writing, .outdoors, .social]
        case .calm, nil: [.sensory, .movement, .writing, .rest]
        }
    }

    private static func stableOrder(_ value: String, seed: Int) -> Int {
        value.utf8.reduce(seed &* 31) { partial, byte in
            (partial &* 16777619) ^ Int(byte)
        }
    }
}
