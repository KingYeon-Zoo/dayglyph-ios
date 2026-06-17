import AppIntents
import Testing
@testable import DayGlyph

struct AppIntentCompileTests {
    @MainActor
    @Test func intentTitlesArePresent() {
        #expect(String(localized: RecordTodayGlyphIntent.title) == "记录今日情绪")
        #expect(String(localized: OpenTodayIntent.title) == "打开今日情绪")
        #expect(String(localized: OpenGlyphCalendarIntent.title) == "打开情绪宇宙")
    }
}
