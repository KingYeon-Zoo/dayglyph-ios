import Foundation
import Testing
@testable import DayGlyph

struct UniverseRenderingPolicyTests {
    @Test func accessibilityAndFailureStatesUseTheCompleteTwoDimensionalPath() {
        #expect(UniverseRenderingPolicy.mode(voiceOver: true, reduceMotion: false, lowPower: false, sceneFailed: false) == .accessible2D)
        #expect(UniverseRenderingPolicy.mode(voiceOver: false, reduceMotion: true, lowPower: false, sceneFailed: false) == .accessible2D)
        #expect(UniverseRenderingPolicy.mode(voiceOver: false, reduceMotion: false, lowPower: true, sceneFailed: false) == .accessible2D)
        #expect(UniverseRenderingPolicy.mode(voiceOver: false, reduceMotion: false, lowPower: false, sceneFailed: true) == .accessible2D)
    }

    @Test func ordinaryEnvironmentUsesRealityKit() {
        #expect(UniverseRenderingPolicy.mode(voiceOver: false, reduceMotion: false, lowPower: false, sceneFailed: false) == .realityKit)
    }

    @Test func sceneDescriptorCreatesOneStableTargetForEveryRecordedDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let dates = [
            try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 2))),
            try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 8))),
            try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 18)))
        ]
        let visual = MonthlyPlanetVisual(
            seed: 42,
            baseHue: 350,
            secondaryHue: 20,
            textureComplexity: 0.5,
            glow: 0.7,
            sizeScale: 1,
            rings: 2,
            satellites: 1,
            rotationSpeed: 0.04,
            recordDots: dates
        )

        let first = UniverseSceneDescriptor.make(visual: visual, calendar: calendar)
        let second = UniverseSceneDescriptor.make(visual: visual, calendar: calendar)

        #expect(first == second)
        #expect(first.recordDots.count == dates.count)
        #expect(Set(first.recordDots.map(\.entityName)).count == dates.count)
        #expect(first.recordDots.allSatisfy { $0.hitRadius >= 0.12 })
    }
}
