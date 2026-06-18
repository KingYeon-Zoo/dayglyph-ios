import Foundation
import Testing
@testable import DayGlyph

struct UniversePresentationTests {
    @Test func oneRecordedDayUsesDataIsStillSparseCopy() {
        #expect(UniversePresentation.monthSummary(recordCount: 1) == "这个月有 1 个记录日，数据还少。")
    }

    @Test func multipleRecordedDaysUseNeutralDescriptiveCopy() {
        #expect(UniversePresentation.monthSummary(recordCount: 8) == "这个月有 8 个记录日，共同组成了这颗月星球。")
    }

    @Test func complexityDescriptionDoesNotRankEmotions() {
        #expect(UniversePresentation.complexityDescription(0.22) == "内部层次较轻")
        #expect(UniversePresentation.complexityDescription(0.52) == "内部层次交错")
        #expect(UniversePresentation.complexityDescription(0.84) == "内部层次丰富")
    }
}
