import Foundation

nonisolated enum NotificationScheduler {
    static let dailyIdentifier = "dayglyph.daily"

    static func actionIdentifier(_ id: UUID) -> String {
        "dayglyph.echo.\(id.uuidString)"
    }

    static func letterIdentifier(_ id: UUID) -> String {
        "dayglyph.letter.\(id.uuidString)"
    }

    static func dailyPlan(hour: Int, minute: Int) -> NotificationPlan {
        NotificationPlan(
            identifier: dailyIdentifier,
            title: "今天的情绪",
            body: "愿意的话，留一句今天给自己。",
            date: nil,
            hour: hour,
            minute: minute,
            repeats: true
        )
    }

    static func actionEchoPlan(id: UUID, title: String, date: Date) -> NotificationPlan {
        NotificationPlan(
            identifier: actionIdentifier(id),
            title: "一段行动回声",
            body: "「\(title)」之后，如果愿意，可以记下此刻的感受。",
            date: date,
            hour: nil,
            minute: nil,
            repeats: false
        )
    }

    static func timeLetterPlan(id: UUID, date: Date) -> NotificationPlan {
        NotificationPlan(
            identifier: letterIdentifier(id),
            title: "一封时间来信到了",
            body: "过去的你留了一句话，现在可以慢慢打开。",
            date: date,
            hour: nil,
            minute: nil,
            repeats: false
        )
    }

    static func identifiersToCancel(
        dailyEnabled: Bool,
        echoEnabled: Bool,
        lettersEnabled: Bool,
        actionIDs: [UUID],
        letterIDs: [UUID]
    ) -> [String] {
        var identifiers: [String] = []
        if !dailyEnabled { identifiers.append(dailyIdentifier) }
        if !echoEnabled { identifiers.append(contentsOf: actionIDs.map(actionIdentifier)) }
        if !lettersEnabled { identifiers.append(contentsOf: letterIDs.map(letterIdentifier)) }
        return identifiers
    }
}
