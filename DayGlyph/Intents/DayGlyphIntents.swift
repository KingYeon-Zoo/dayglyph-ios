import AppIntents
import Foundation
import SwiftData

struct RecordTodayGlyphIntent: AppIntent {
    static var title: LocalizedStringResource = "记录今天的一划"
    static var description = IntentDescription("写下一段今天的记录，并生成或更新今天的一划。")
    static var supportedModes: IntentModes = .background
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "记录内容", requestValueDialog: "今天留下些什么？")
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .result(dialog: "记录内容不能为空。")
        }

        let schema = Schema([DayEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let analysis = await UnifiedEmotionAnalyzer().analyze(trimmed)
        _ = try DayEntryStore.saveEntry(text: trimmed, analysis: analysis, context: context)

        return .result(dialog: "已记录今天的一划，理解为\(analysis.emotion.title)。")
    }
}

struct OpenTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "打开今日一划"
    static var description = IntentDescription("打开 DayGlyph 的今日记录页面。")
    static var supportedModes: IntentModes = .foreground(.immediate)
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @MainActor
    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct OpenGlyphCalendarIntent: AppIntent {
    static var title: LocalizedStringResource = "打开情绪月历"
    static var description = IntentDescription("打开 DayGlyph 的情绪月历。")
    static var supportedModes: IntentModes = .foreground(.immediate)
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @MainActor
    func perform() async throws -> some IntentResult {
        .result()
    }
}
