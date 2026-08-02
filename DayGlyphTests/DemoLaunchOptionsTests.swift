import Testing
@testable import DayGlyph

@MainActor
struct DemoLaunchOptionsTests {
    @Test func normalLaunchDoesNotEnableDemoBehavior() {
        let options = DemoLaunchOptions(arguments: ["/path/to/DayGlyph"])

        #expect(options.seedsDemoData == false)
        #expect(options.skipsOnboarding == false)
    }

    @Test func demoArgumentsEnableSeedingAndSkipOnboarding() {
        let options = DemoLaunchOptions(arguments: [
            "/path/to/DayGlyph",
            DemoLaunchOptions.seedArgument,
            DemoLaunchOptions.skipOnboardingArgument,
        ])

        #expect(options.seedsDemoData)
        #expect(options.skipsOnboarding)
    }
}
