import Foundation
import Testing
@testable import DayGlyph

struct NotificationSchedulerTests {
    @Test func identifiersAreStableAndScoped() {
        let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        #expect(NotificationScheduler.dailyIdentifier == "dayglyph.daily")
        #expect(NotificationScheduler.actionIdentifier(id) == "dayglyph.echo.AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")
        #expect(NotificationScheduler.letterIdentifier(id) == "dayglyph.letter.AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")
    }

    @Test func plansUseNonPressuringCopy() {
        let date = Date(timeIntervalSince1970: 2_000)
        let action = NotificationScheduler.actionEchoPlan(id: UUID(), title: "慢慢呼吸三次", date: date)
        let letter = NotificationScheduler.timeLetterPlan(id: UUID(), date: date)

        #expect(action.title == "一段行动回声")
        #expect(action.body.contains("必须") == false)
        #expect(action.repeats == false)
        #expect(letter.title == "一封时间来信到了")
    }

    @Test func disablingModulesReturnsAllMatchingIdentifiers() {
        let actionID = UUID()
        let letterID = UUID()
        let identifiers = NotificationScheduler.identifiersToCancel(
            dailyEnabled: false,
            echoEnabled: false,
            lettersEnabled: false,
            actionIDs: [actionID],
            letterIDs: [letterID]
        )
        #expect(identifiers.contains(NotificationScheduler.dailyIdentifier))
        #expect(identifiers.contains(NotificationScheduler.actionIdentifier(actionID)))
        #expect(identifiers.contains(NotificationScheduler.letterIdentifier(letterID)))
    }
}
