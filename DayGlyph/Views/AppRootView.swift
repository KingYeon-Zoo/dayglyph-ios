import SwiftUI
import SwiftData

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("今日", systemImage: "sparkle")
            }

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("月历", systemImage: "calendar")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "slider.horizontal.3")
            }
        }
        .tint(DayGlyphStyle.ink)
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
