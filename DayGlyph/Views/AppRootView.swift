import SwiftUI
import SwiftData

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .today
    @State private var todayRecordRequest = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayHomeView(recordRequest: todayRecordRequest)
            .tabItem {
                Label(AppTab.today.title, systemImage: AppTab.today.systemImage)
            }
            .tag(AppTab.today)

            NavigationStack {
                UniverseView {
                    todayRecordRequest += 1
                    selectedTab = .today
                }
            }
            .tabItem {
                Label(AppTab.universe.title, systemImage: AppTab.universe.systemImage)
            }
            .tag(AppTab.universe)

            NavigationStack {
                EchoHomeView()
            }
            .tabItem {
                Label(AppTab.echo.title, systemImage: AppTab.echo.systemImage)
            }
            .tag(AppTab.echo)

            NavigationStack {
                MineHomeView()
            }
            .tabItem {
                Label(AppTab.mine.title, systemImage: AppTab.mine.systemImage)
            }
            .tag(AppTab.mine)
        }
        .tint(selectedTab.tint)
        .environment(\.locale, Locale(identifier: "zh_CN"))
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )) {
            OnboardingView { hasCompletedOnboarding = true }
        }
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
