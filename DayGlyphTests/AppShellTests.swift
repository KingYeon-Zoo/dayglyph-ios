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
}
