import Foundation
import Testing
@testable import DayGlyph

struct EmpathySeaDemoTests {
    @Test func publicCopyDoesNotMutateOriginalEntry() throws {
        let analysis = EmotionAnalyzer().analyze("原始日记内容")
        let entry = DayEntry(
            date: .now,
            text: "原始日记内容",
            analysis: analysis,
            glyphSeed: 3
        )

        let copy = try EmpathyCopyStore.makeDraft(
            text: "编辑后的匿名副本",
            sourceEntryId: entry.entryID
        )
        copy.copyText = "再次编辑副本"

        #expect(entry.text == "原始日记内容")
        #expect(copy.copyText == "再次编辑副本")
        #expect(copy.sourceEntryId == entry.entryID)
    }

    @Test func publicCopyRequiresOneToThreeHundredCharacters() {
        #expect(throws: EmpathyCopyError.emptyBody) {
            try EmpathyCopyStore.makeDraft(text: "   ", sourceEntryId: nil)
        }
        #expect(throws: EmpathyCopyError.tooLong) {
            try EmpathyCopyStore.makeDraft(text: String(repeating: "字", count: 301), sourceEntryId: nil)
        }
    }

    @Test func contactDetectionWarnsWithoutChangingText() {
        let text = "可以联系我 test@example.com 或 13800138000"

        let warnings = EmpathySeaDemoCatalog.contactWarnings(in: text)

        #expect(warnings.contains("邮箱地址"))
        #expect(warnings.contains("电话号码"))
        #expect(text == "可以联系我 test@example.com 或 13800138000")
    }

    @Test func demoReviewMovesFromReviewingToFixedResponse() throws {
        let copy = try EmpathyCopyStore.makeDraft(text: "今天有一点难过", sourceEntryId: nil)

        EmpathyCopyStore.submit(copy, at: Date(timeIntervalSince1970: 100))
        #expect(copy.reviewState == .reviewing)
        #expect(copy.sentAt == Date(timeIntervalSince1970: 100))

        EmpathyCopyStore.completeDemoReview(copy)
        #expect(copy.reviewState == .responded)
        #expect(copy.responseState == .received)
        #expect(copy.responseText?.isEmpty == false)
    }

    @Test func demoPostsHaveStableResponsesAndReportState() throws {
        let post = try #require(EmpathySeaDemoCatalog.posts.first)

        #expect(post.responses.isEmpty == false)
        #expect(EmpathySeaDemoCatalog.isReported(postID: post.id, reportedIDs: [post.id]))
        #expect(EmpathySeaDemoCatalog.isReported(postID: post.id, reportedIDs: []) == false)
    }

    @Test func reportedPostIDsRoundTripThroughLocalPreference() {
        let updated = EmpathySeaDemoCatalog.addReported(postID: "sea-b", to: "sea-a")

        #expect(EmpathySeaDemoCatalog.reportedIDs(from: updated) == ["sea-a", "sea-b"])
    }
}
