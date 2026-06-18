import Testing
@testable import DayGlyph

struct OnboardingCopyTests {
    @Test func onboardingHasExactlyThreeSkippablePages() {
        #expect(OnboardingPage.allCases.count == 3)
        #expect(OnboardingPage.value.title == "把今天的感受，留成一颗星球")
        #expect(OnboardingPage.privacy.points.contains("公开前由你再次确认"))
        #expect(OnboardingPage.preferences.primaryActionTitle == "完成")
    }
}
