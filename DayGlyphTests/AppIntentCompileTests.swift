import AppIntents
import Testing
@testable import DayGlyph

struct AppIntentCompileTests {
    @MainActor
    @Test func intentTitlesArePresent() {
        #expect(String(localized: RecordTodayGlyphIntent.title) == "记录今天的一划")
        #expect(String(localized: OpenTodayIntent.title) == "打开今日一划")
        #expect(String(localized: OpenGlyphCalendarIntent.title) == "打开情绪月历")
    }
}
