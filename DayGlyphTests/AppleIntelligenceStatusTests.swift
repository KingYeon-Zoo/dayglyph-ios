import Testing
@testable import DayGlyph

@MainActor
struct AppleIntelligenceStatusTests {
    @Test func availableStatusCanUseFoundationModels() {
        let status = AppleIntelligenceStatus.available

        #expect(status.canUseFoundationModels)
        #expect(status.title == "Apple Intelligence 已就绪")
    }

    @Test func deviceNotEligibleExplainsLocalFallback() {
        let status = AppleIntelligenceStatus.deviceNotEligible

        #expect(status.canUseFoundationModels == false)
        #expect(status.title == "此设备不符合运行条件")
        #expect(status.detail.contains("本地分析"))
    }

    @Test func modelNotReadyDoesNotClaimAvailability() {
        let status = AppleIntelligenceStatus.modelNotReady

        #expect(status.canUseFoundationModels == false)
        #expect(status.detail.contains("准备"))
    }
}
