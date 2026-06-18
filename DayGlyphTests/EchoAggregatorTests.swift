import Foundation
import Testing
@testable import DayGlyph

struct EchoAggregatorTests {
    @Test func feedbackOptionsAreNeutralAndComplete() {
        #expect(ActionResponseKind.allCases.map(\.title) == [
            "轻松了一点", "没什么变化", "比想象中困难", "有别的感受"
        ])
    }

    @Test func completedActionBecomesDueOnlyWithoutAResponse() {
        let now = Date(timeIntervalSince1970: 2_000)
        let action = ActionInstance(
            actionId: "warm-water",
            entryId: nil,
            actionTitle: "喝几口温水，留意温度",
            category: .sensory,
            createdAt: Date(timeIntervalSince1970: 1_000),
            startedAt: Date(timeIntervalSince1970: 1_100),
            completedAt: Date(timeIntervalSince1970: 1_200),
            followUpAt: Date(timeIntervalSince1970: 1_800),
            state: .completed
        )

        #expect(EchoAggregator.dueActions(from: [action], responses: [], at: now).map(\.id) == [action.id])

        let response = ActionResponse(actionInstanceId: action.id, kind: .unchanged, createdAt: now)
        #expect(EchoAggregator.dueActions(from: [action], responses: [response], at: now).isEmpty)
    }

    @Test func insightRequiresThreeResponsesInSameCategory() {
        let base = Date(timeIntervalSince1970: 1_000)
        let actions = (0 ..< 3).map { index in
            ActionInstance(
                actionId: "sensory-\(index)",
                entryId: nil,
                actionTitle: "感官行动 \(index)",
                category: .sensory,
                createdAt: base.addingTimeInterval(Double(index)),
                startedAt: base,
                completedAt: base,
                followUpAt: base,
                state: .completed
            )
        }
        let two = actions.prefix(2).map {
            ActionResponse(actionInstanceId: $0.id, kind: .moreSettled, createdAt: base)
        }
        #expect(EchoAggregator.insights(from: actions, responses: two).isEmpty)

        let three = actions.map {
            ActionResponse(actionInstanceId: $0.id, kind: .moreSettled, createdAt: base)
        }
        let insight = EchoAggregator.insights(from: actions, responses: three).first
        #expect(insight?.sampleCount == 3)
        #expect(insight?.summary.contains("3 次") == true)
        #expect(insight?.summary.contains("治愈") == false)
    }
}
