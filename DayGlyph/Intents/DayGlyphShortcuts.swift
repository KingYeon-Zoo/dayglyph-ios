import AppIntents

struct DayGlyphShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordTodayGlyphIntent(),
            phrases: [
                "用\(.applicationName)记录今日情绪",
                "在\(.applicationName)写下今天"
            ],
            shortTitle: "记录情绪",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: OpenTodayIntent(),
            phrases: [
                "打开\(.applicationName)",
                "查看\(.applicationName)今日情绪"
            ],
            shortTitle: "打开今日",
            systemImageName: "square.and.pencil"
        )

        AppShortcut(
            intent: OpenGlyphCalendarIntent(),
            phrases: [
                "查看\(.applicationName)情绪宇宙",
                "打开\(.applicationName)宇宙"
            ],
            shortTitle: "情绪宇宙",
            systemImageName: "calendar"
        )
    }
}
