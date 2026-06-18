import Foundation
import SwiftData
import Testing
@testable import DayGlyph

@MainActor
struct TodaySupportPersistenceTests {
    @Test func actionInstancePersistsStartAndCompletion() throws {
        let container = try ModelContainer(
            for: ActionInstance.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let startedAt = Date(timeIntervalSince1970: 1_750_000_000)
        let completedAt = startedAt.addingTimeInterval(180)
        let instance = ActionInstance(
            actionId: "quiet-water",
            entryId: UUID(),
            startedAt: startedAt,
            state: .started
        )
        context.insert(instance)
        instance.complete(at: completedAt)
        try context.save()

        let saved = try #require(context.fetch(FetchDescriptor<ActionInstance>()).first)
        #expect(saved.state == .completed)
        #expect(saved.startedAt == startedAt)
        #expect(saved.completedAt == completedAt)
    }

    @Test func skippedActionDoesNotPretendToBeCompleted() throws {
        let instance = ActionInstance(
            actionId: "skip-today",
            entryId: nil,
            startedAt: nil,
            state: .skipped
        )

        #expect(instance.state == .skipped)
        #expect(instance.completedAt == nil)
    }

    @Test func futureLetterRequiresBodyAndAtLeastSevenDays() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 18)))

        #expect(throws: TimeLetterError.emptyBody) {
            try TimeLetterStore.makeFuture(body: "   ", delayDays: 7, now: now, calendar: calendar)
        }
        #expect(throws: TimeLetterError.tooSoon) {
            try TimeLetterStore.makeFuture(body: "给未来的一句话", delayDays: 6, now: now, calendar: calendar)
        }

        let letter = try TimeLetterStore.makeFuture(
            body: "给未来的一句话",
            delayDays: 7,
            now: now,
            calendar: calendar
        )
        #expect(letter.body == "给未来的一句话")
        #expect(letter.notBefore == calendar.date(byAdding: .day, value: 7, to: now))
        #expect(letter.state == .waiting)
    }

    @Test func futureLetterRejectsMoreThanFiveHundredCharacters() {
        #expect(throws: TimeLetterError.tooLong) {
            try TimeLetterStore.makeFuture(body: String(repeating: "字", count: 501), delayDays: 7)
        }
    }

    @Test func onlyOneDueLetterIsSelectedPerDay() {
        let older = TimeLetter(
            sourceType: .future,
            body: "较早的来信",
            notBefore: Date(timeIntervalSince1970: 100),
            createdAt: Date(timeIntervalSince1970: 10),
            state: .waiting
        )
        let newer = TimeLetter(
            sourceType: .past,
            body: "较新的来信",
            notBefore: Date(timeIntervalSince1970: 200),
            createdAt: Date(timeIntervalSince1970: 20),
            state: .waiting
        )

        let selected = TimeLetterStore.dueLetter(from: [newer, older], at: Date(timeIntervalSince1970: 300))

        #expect(selected?.body == "较早的来信")
    }

    @Test func letterCanBeKeptOrHiddenForToday() {
        let letter = TimeLetter(
            sourceType: .future,
            body: "一封来信",
            notBefore: .now,
            state: .waiting
        )

        letter.keep()
        #expect(letter.state == .kept)
        letter.hideForToday()
        #expect(letter.state == .hiddenToday)
    }
}
