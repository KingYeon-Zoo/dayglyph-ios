import Testing
import Foundation
@testable import DayGlyph

/// 共情海匿名改写校验测试（contextual personalization spec 第 6、12 节）。
@MainActor
struct EmpathyRewriteValidatorTests {

    // MARK: - 请求前初筛

    @Test func prescreenRejectsEmpty() {
        #expect(EmpathyRewriteValidator.prescreen("   ") == .empty)
    }

    @Test func prescreenRejectsTooLong() {
        #expect(EmpathyRewriteValidator.prescreen(String(repeating: "字", count: 301)) == .tooLong)
    }

    @Test func prescreenFlagsHighRisk() {
        #expect(EmpathyRewriteValidator.prescreen("我不想活了") == .highRisk)
    }

    @Test func prescreenAcceptsNormal() {
        #expect(EmpathyRewriteValidator.prescreen("今天有点累，但还撑得住。") == .ok)
    }

    // MARK: - 身份信息识别（spec 12.1 条 7）

    @Test func detectsEmail() {
        #expect(EmpathyRewriteValidator.detectedIdentifiers(in: "联系我 a.b@example.com").contains("邮箱"))
    }

    @Test func detectsPhone() {
        #expect(EmpathyRewriteValidator.detectedIdentifiers(in: "我的号码 13912345678").contains("手机号"))
    }

    @Test func detectsSocialAccount() {
        #expect(EmpathyRewriteValidator.detectedIdentifiers(in: "微信号：zhangsan_2024").contains("社交账号"))
    }

    @Test func detectsSchool() {
        #expect(EmpathyRewriteValidator.detectedIdentifiers(in: "在北京大学读书").contains("学校"))
    }

    @Test func detectsCompany() {
        #expect(EmpathyRewriteValidator.detectedIdentifiers(in: "在字节跳动科技工作").contains("单位"))
    }

    @Test func detectsName() {
        #expect(EmpathyRewriteValidator.detectedIdentifiers(in: "我叫李明华").contains("姓名"))
    }

    @Test func cleanTextHasNoIdentifiers() {
        #expect(EmpathyRewriteValidator.detectedIdentifiers(in: "今天和一个人聊了聊，心里轻一些了。").isEmpty)
    }

    // MARK: - 返回后校验

    @Test func checkRejectsResultWithIdentifier() {
        let result = EmpathyRewriteValidator.check(
            rewrite: "我和同事在腾讯公司聊了聊。",
            source: "我和同事聊了聊。"
        )
        if case .containsIdentifiers = result { } else { Issue.record("应识别出单位信息") }
    }

    @Test func checkRejectsAddedContent() {
        let result = EmpathyRewriteValidator.check(
            rewrite: String(repeating: "新增的细节很多很多很多很多很多", count: 5),
            source: "今天有点累。"
        )
        #expect(result == .likelyAddedContent)
    }

    @Test func checkAcceptsCleanRewrite() {
        let result = EmpathyRewriteValidator.check(
            rewrite: "今天和一个人聊了聊，心里轻一些了。",
            source: "今天和小王聊了聊，心里轻一些了。"
        )
        #expect(result == .ok)
    }
}
