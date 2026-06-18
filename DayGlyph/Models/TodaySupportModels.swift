import Foundation
import SwiftData

nonisolated enum MicroActionCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case breathing
    case movement
    case sensory
    case rest
    case writing
    case social
    case outdoors

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breathing: "呼吸练习"
        case .movement: "轻微活动"
        case .sensory: "感官觉察"
        case .rest: "安静休息"
        case .writing: "简单书写"
        case .social: "需要联系他人"
        case .outdoors: "需要外出"
        }
    }
}

nonisolated enum MicroActionDifficulty: Int, Codable, Comparable {
    case easiest
    case gentle
    case moderate

    static func < (lhs: MicroActionDifficulty, rhs: MicroActionDifficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .easiest: "很容易"
        case .gentle: "轻量"
        case .moderate: "需要一点精力"
        }
    }
}

nonisolated struct MicroAction: Codable, Equatable, Identifiable {
    var id: String
    var category: MicroActionCategory
    var title: String
    var estimatedMinutes: Int
    var constraints: [String]
    var difficultyBand: MicroActionDifficulty
}

nonisolated enum ActionInstanceState: String, Codable {
    case started
    case completed
    case cancelled
    case skipped
}

@Model
final class ActionInstance {
    var id: UUID = UUID()
    var actionId: String
    var entryId: UUID?
    var startedAt: Date?
    var completedAt: Date?
    var followUpAt: Date?
    var stateRawValue: String

    init(
        actionId: String,
        entryId: UUID?,
        startedAt: Date?,
        completedAt: Date? = nil,
        followUpAt: Date? = nil,
        state: ActionInstanceState
    ) {
        self.actionId = actionId
        self.entryId = entryId
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.followUpAt = followUpAt
        self.stateRawValue = state.rawValue
    }

    var state: ActionInstanceState {
        get { ActionInstanceState(rawValue: stateRawValue) ?? .started }
        set { stateRawValue = newValue.rawValue }
    }

    func complete(at date: Date = .now) {
        completedAt = date
        state = .completed
    }

    func cancel() {
        state = .cancelled
    }
}
