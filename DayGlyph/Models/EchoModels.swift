import Foundation
import SwiftData

nonisolated enum ActionResponseKind: String, CaseIterable, Codable, Identifiable {
    case moreSettled
    case unchanged
    case harder
    case different

    var id: String { rawValue }

    var title: String {
        switch self {
        case .moreSettled: "轻松了一点"
        case .unchanged: "没什么变化"
        case .harder: "比想象中困难"
        case .different: "有别的感受"
        }
    }
}

@Model
final class ActionResponse {
    var id: UUID = UUID()
    var actionInstanceId: UUID
    var kindRawValue: String?
    var note: String
    var createdAt: Date
    var isDemo: Bool = false

    init(
        actionInstanceId: UUID,
        kind: ActionResponseKind? = nil,
        note: String = "",
        createdAt: Date = .now,
        isDemo: Bool = false
    ) {
        self.actionInstanceId = actionInstanceId
        self.kindRawValue = kind?.rawValue
        self.note = note
        self.createdAt = createdAt
        self.isDemo = isDemo
    }

    var kind: ActionResponseKind? {
        get { kindRawValue.flatMap(ActionResponseKind.init(rawValue:)) }
        set { kindRawValue = newValue?.rawValue }
    }
}

nonisolated struct EchoInsight: Identifiable, Equatable {
    var id: String { category.rawValue }
    var category: MicroActionCategory
    var sampleCount: Int
    var startedAt: Date
    var endedAt: Date
    var distribution: [ActionResponseKind: Int]
    var summary: String
}
