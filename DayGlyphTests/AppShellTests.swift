import SwiftUI
import Testing
@testable import DayGlyph

struct AppShellTests {
    @Test func appTabsMatchV2ProductNavigation() {
        #expect(AppTab.allCases.map(\.title) == ["今日", "宇宙", "回声", "我的"])
        #expect(AppTab.allCases.map(\.systemImage) == [
            "house.fill",
            "sparkles",
            "dot.radiowaves.left.and.right",
            "person.crop.circle"
        ])
    }

    @Test func onlyUniverseRequestsDarkAppearance() {
        #expect(AppTab.today.preferredColorScheme == .light)
        #expect(AppTab.universe.preferredColorScheme == .dark)
        #expect(AppTab.echo.preferredColorScheme == .light)
        #expect(AppTab.mine.preferredColorScheme == .light)
    }
}
