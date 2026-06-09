import AppIntents

struct DayGlyphShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordTodayGlyphIntent(),
            phrases: [
                "用\(.applicationName)记录今天的一划",
                "在\(.applicationName)写下今天"
            ],
            shortTitle: "记录一划",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: OpenTodayIntent(),
            phrases: [
                "打开\(.applicationName)",
                "查看\(.applicationName)今日一划"
            ],
            shortTitle: "打开今日",
            systemImageName: "square.and.pencil"
        )

        AppShortcut(
            intent: OpenGlyphCalendarIntent(),
            phrases: [
                "查看\(.applicationName)情绪月历",
                "打开\(.applicationName)月历"
            ],
            shortTitle: "情绪月历",
            systemImageName: "calendar"
        )
    }
}
