import SwiftUI
import SwiftData

struct AppRootView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayHomeView()
            .tabItem {
                Label(AppTab.today.title, systemImage: AppTab.today.systemImage)
            }
            .tag(AppTab.today)

            NavigationStack {
                UniversePlaceholderView()
            }
            .tabItem {
                Label(AppTab.universe.title, systemImage: AppTab.universe.systemImage)
            }
            .tag(AppTab.universe)

            NavigationStack {
                EchoPlaceholderView()
            }
            .tabItem {
                Label(AppTab.echo.title, systemImage: AppTab.echo.systemImage)
            }
            .tag(AppTab.echo)

            NavigationStack {
                MineHomePlaceholderView()
            }
            .tabItem {
                Label(AppTab.mine.title, systemImage: AppTab.mine.systemImage)
            }
            .tag(AppTab.mine)
        }
        .tint(selectedTab.tint)
        .environment(\.locale, Locale(identifier: "zh_CN"))
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
