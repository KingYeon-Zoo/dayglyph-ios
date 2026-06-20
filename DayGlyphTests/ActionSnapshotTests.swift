import Testing
import Foundation
import SwiftData
@testable import DayGlyph

/// 行动回声快照与旧数据兼容测试（contextual personalization spec 5.3、§9、12.1）。
@MainActor
struct ActionSnapshotTests {

    // MARK: - 回声问题对应（spec 12.1 条 3）

    @Test func snapshotPreservesEchoQuestion() {
        let instance = ActionInstance(
            actionId: "ai-light",
            entryId: UUID(),
            actionTitle: "松开肩膀",
            startedAt: .now,
            state: .started,
            actionInstruction: "把肩膀抬起再放下三次。",
            actionReason: "紧绷感较高。",
            actionLevel: .light,
            echoQuestion: "做完后肩颈有变化吗？",
            durationMinutes: 1
        )
        #expect(instance.resolvedEchoQuestion == "做完后肩颈有变化吗？")
        #expect(instance.actionLevel == .light)
    }

    // MARK: - 非法/缺失回声问题回退固定中性问题（spec 第 10 节）

    @Test func emptyEchoQuestionFallsBackToDefault() {
        let instance = ActionInstance(
            actionId: "ai-standard",
            entryId: nil,
            actionTitle: "写下一件事",
            startedAt: .now,
            state: .started,
            echoQuestion: "   "
        )
        #expect(instance.resolvedEchoQuestion == defaultEchoQuestion)
    }

    // MARK: - 旧数据兼容（spec 12.1 条 10）

    @Test func legacyInstanceWithoutSnapshotStillReadable() throws {
        // 模拟旧记录：不带任何 AI 快照字段。
        let legacy = ActionInstance(
            actionId: "one-slow-breath",
            entryId: nil,
            actionTitle: "慢慢呼吸三次",
            category: .breathing,
            startedAt: .now,
            state: .started
        )
        #expect(legacy.echoQuestion.isEmpty)
        #expect(legacy.resolvedEchoQuestion == defaultEchoQuestion)
        #expect(legacy.actionLevel == nil)
        #expect(legacy.durationMinutes == 0)
        #expect(legacy.category == .breathing)
    }

    @Test func snapshotPersistsAndReloads() throws {
        let schema = Schema([
            DayEntry.self, ActionInstance.self, TimeLetter.self,
            EmpathyCopy.self, ActionResponse.self, AIGenerationRecord.self,
        ])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
        let context = ModelContext(container)
        let id = UUID()
        let instance = ActionInstance(
            actionId: "ai-active",
            entryId: id,
            actionTitle: "窗边走动",
            startedAt: .now,
            state: .started,
            actionInstruction: "走到窗边再回来。",
            actionLevel: .active,
            echoQuestion: "回来后感觉怎么样？",
            durationMinutes: 10
        )
        context.insert(instance)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ActionInstance>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.echoQuestion == "回来后感觉怎么样？")
        #expect(fetched.first?.actionLevel == .active)
        #expect(fetched.first?.durationMinutes == 10)
    }
}
