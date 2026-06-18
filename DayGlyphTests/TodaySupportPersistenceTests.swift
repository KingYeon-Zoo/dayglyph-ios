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
}
