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

/// AI 三档微行动档位（contextual personalization spec 5.3）。
nonisolated enum ActionOptionLevel: String, Codable, CaseIterable {
    case light
    case standard
    case active

    var title: String {
        switch self {
        case .light: "轻量"
        case .standard: "标准"
        case .active: "主动"
        }
    }
}

/// 行动回声缺省问题（spec 第 10 节：回声问题非法时的固定中性问题）。
nonisolated let defaultEchoQuestion = "做完之后，你现在感觉怎么样？"

@Model
final class ActionInstance {
    var id: UUID = UUID()
    var actionId: String
    var entryId: UUID?
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var followUpAt: Date?
    var stateRawValue: String
    var actionTitle: String = "一项小行动"
    var categoryRawValue: String?
    var isDemo: Bool = false

    // MARK: - AI 行动快照（spec 5.3、§9：保存完整快照而非数组索引，离线可用、回声一致）
    // 全部带默认值以兼容旧记录（spec 第 12.1 条 10）。
    /// 行动指令（AI 行动时为模型指令，本地行动时为空）。
    var actionInstruction: String = ""
    /// 推荐原因快照。
    var actionReason: String = ""
    /// 档位 raw value（light/standard/active）；本地目录行动为空。
    var actionLevelRawValue: String?
    /// 仅针对该行动的回声问题快照；为空时由 UI 回退固定中性问题。
    var echoQuestion: String = ""
    /// 预估时长（分钟）。
    var durationMinutes: Int = 0

    init(
        actionId: String,
        entryId: UUID?,
        actionTitle: String = "一项小行动",
        category: MicroActionCategory? = nil,
        createdAt: Date = .now,
        startedAt: Date?,
        completedAt: Date? = nil,
        followUpAt: Date? = nil,
        state: ActionInstanceState,
        actionInstruction: String = "",
        actionReason: String = "",
        actionLevel: ActionOptionLevel? = nil,
        echoQuestion: String = "",
        durationMinutes: Int = 0,
        isDemo: Bool = false
    ) {
        self.actionId = actionId
        self.entryId = entryId
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.followUpAt = followUpAt
        self.actionTitle = actionTitle
        self.categoryRawValue = category?.rawValue
        self.stateRawValue = state.rawValue
        self.actionInstruction = actionInstruction
        self.actionReason = actionReason
        self.actionLevelRawValue = actionLevel?.rawValue
        self.echoQuestion = echoQuestion
        self.durationMinutes = durationMinutes
        self.isDemo = isDemo
    }

    var state: ActionInstanceState {
        get { ActionInstanceState(rawValue: stateRawValue) ?? .started }
        set { stateRawValue = newValue.rawValue }
    }

    var category: MicroActionCategory? {
        categoryRawValue.flatMap(MicroActionCategory.init(rawValue:))
    }

    var actionLevel: ActionOptionLevel? {
        actionLevelRawValue.flatMap(ActionOptionLevel.init(rawValue:))
    }

    /// 展示用回声问题：快照非空则用快照，否则回退固定中性问题（spec 第 10 节）。
    var resolvedEchoQuestion: String {
        let trimmed = echoQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultEchoQuestion : trimmed
    }

    func complete(at date: Date = .now) {
        completedAt = date
        state = .completed
    }

    func cancel() {
        state = .cancelled
    }
}

nonisolated enum TimeLetterSourceType: String, Codable {
    case past
    case future

    var title: String {
        switch self {
        case .past: "来自过去"
        case .future: "写给未来"
        }
    }
}

nonisolated enum TimeLetterState: String, Codable {
    case waiting
    case available
    case kept
    case hiddenToday
}

@Model
final class TimeLetter {
    var id: UUID = UUID()
    var sourceTypeRawValue: String
    var sourceEntryId: UUID?
    var body: String
    var recipeSummary: String?
    var notBefore: Date
    var createdAt: Date
    var hiddenAt: Date?
    var stateRawValue: String

    init(
        sourceType: TimeLetterSourceType,
        sourceEntryId: UUID? = nil,
        body: String,
        recipeSummary: String? = nil,
        notBefore: Date,
        createdAt: Date = .now,
        state: TimeLetterState
    ) {
        self.sourceTypeRawValue = sourceType.rawValue
        self.sourceEntryId = sourceEntryId
        self.body = body
        self.recipeSummary = recipeSummary
        self.notBefore = notBefore
        self.createdAt = createdAt
        self.stateRawValue = state.rawValue
    }

    var sourceType: TimeLetterSourceType {
        TimeLetterSourceType(rawValue: sourceTypeRawValue) ?? .future
    }

    var state: TimeLetterState {
        get { TimeLetterState(rawValue: stateRawValue) ?? .waiting }
        set { stateRawValue = newValue.rawValue }
    }

    func keep() {
        state = .kept
    }

    func hideForToday(at date: Date = .now) {
        hiddenAt = date
        state = .hiddenToday
    }
}

nonisolated enum TimeLetterError: LocalizedError, Equatable {
    case emptyBody
    case tooLong
    case tooSoon

    var errorDescription: String? {
        switch self {
        case .emptyBody: "写下一句话后才能保存。"
        case .tooLong: "来信最多 500 字。"
        case .tooSoon: "时间来信最早会在 7 天后出现。"
        }
    }
}

nonisolated enum TimeLetterStore {
    static func makeFuture(
        body: String,
        delayDays: Int,
        sourceEntryId: UUID? = nil,
        recipeSummary: String? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> TimeLetter {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { throw TimeLetterError.emptyBody }
        guard trimmed.count <= 500 else { throw TimeLetterError.tooLong }
        guard delayDays >= 7 else { throw TimeLetterError.tooSoon }
        let delivery = calendar.date(byAdding: .day, value: delayDays, to: now) ?? now.addingTimeInterval(Double(delayDays) * 86_400)
        return TimeLetter(
            sourceType: .future,
            sourceEntryId: sourceEntryId,
            body: trimmed,
            recipeSummary: recipeSummary,
            notBefore: delivery,
            createdAt: now,
            state: .waiting
        )
    }

    static func dueLetter(
        from letters: [TimeLetter],
        at date: Date = .now,
        calendar: Calendar = .current
    ) -> TimeLetter? {
        letters
            .filter { letter in
                guard letter.notBefore <= date else { return false }
                if letter.state == .waiting || letter.state == .available { return true }
                if letter.state == .hiddenToday, let hiddenAt = letter.hiddenAt {
                    return calendar.isDate(hiddenAt, inSameDayAs: date) == false
                }
                return false
            }
            .sorted { $0.notBefore < $1.notBefore }
            .first
    }

    @MainActor
    static func makePast(from entry: DayEntry, availableAt date: Date = .now) -> TimeLetter {
        TimeLetter(
            sourceType: .past,
            sourceEntryId: entry.entryID,
            body: entry.text,
            recipeSummary: "当时的配方：\(entry.emotionRecipe.name)",
            notBefore: date,
            createdAt: date,
            state: .available
        )
    }
}

nonisolated enum EmpathyReviewState: String, Codable {
    case draft
    case reviewing
    case published
    case responded
    case failed
}

nonisolated enum EmpathyResponseState: String, Codable {
    case none
    case received
}

@Model
final class EmpathyCopy {
    var id: UUID = UUID()
    var copyText: String
    var sourceEntryId: UUID?
    var reviewStateRawValue: String
    var sentAt: Date?
    var responseStateRawValue: String
    var responseText: String?

    init(
        copyText: String,
        sourceEntryId: UUID?,
        reviewState: EmpathyReviewState = .draft,
        sentAt: Date? = nil,
        responseState: EmpathyResponseState = .none,
        responseText: String? = nil
    ) {
        self.copyText = copyText
        self.sourceEntryId = sourceEntryId
        self.reviewStateRawValue = reviewState.rawValue
        self.sentAt = sentAt
        self.responseStateRawValue = responseState.rawValue
        self.responseText = responseText
    }

    var reviewState: EmpathyReviewState {
        get { EmpathyReviewState(rawValue: reviewStateRawValue) ?? .draft }
        set { reviewStateRawValue = newValue.rawValue }
    }

    var responseState: EmpathyResponseState {
        get { EmpathyResponseState(rawValue: responseStateRawValue) ?? .none }
        set { responseStateRawValue = newValue.rawValue }
    }
}

nonisolated enum EmpathyCopyError: LocalizedError, Equatable {
    case emptyBody
    case tooLong

    var errorDescription: String? {
        switch self {
        case .emptyBody: "匿名副本不能为空。"
        case .tooLong: "匿名副本最多 300 字。"
        }
    }
}

nonisolated enum EmpathyCopyStore {
    static func makeDraft(text: String, sourceEntryId: UUID?) throws -> EmpathyCopy {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { throw EmpathyCopyError.emptyBody }
        guard trimmed.count <= 300 else { throw EmpathyCopyError.tooLong }
        return EmpathyCopy(copyText: trimmed, sourceEntryId: sourceEntryId)
    }

    static func submit(_ copy: EmpathyCopy, at date: Date = .now) {
        copy.sentAt = date
        copy.reviewState = .reviewing
    }

    static func completeDemoReview(_ copy: EmpathyCopy) {
        copy.reviewState = .responded
        copy.responseState = .received
        copy.responseText = "谢谢你把这句话放在这里。有人认真读到了它。"
    }
}
