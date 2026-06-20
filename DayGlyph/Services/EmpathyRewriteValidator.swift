import Foundation

/// 共情海匿名改写的本地校验（contextual personalization spec 第 6 节、§8 EmpathyRewriteValidator）。
///
/// 负责两类检查：
/// 1. 改写请求前的本地初筛（长度与明确风险）。
/// 2. AI 改写返回后的隐私与安全校验：必须移除姓名、手机号、邮箱、社交账号、学校、公司、
///    精确地址与可识别单位；若无法在不改变原意的前提下安全匿名化，返回不可用状态而非看似安全的错误草稿（spec 第 6 节）。
enum EmpathyRewriteValidator {

    static let maxSourceLength = 300
    static let maxRewriteLength = 300

    /// 改写前本地初筛结果。
    enum Prescreen: Equatable {
        case ok
        case empty
        case tooLong
        case highRisk
    }

    /// 改写返回后校验结果。
    enum Check: Equatable {
        case ok
        /// 仍含可识别信息，列出命中的类别。
        case containsIdentifiers([String])
        case empty
        case tooLong
        /// 长度异常增长，疑似新增事实（spec 第 6 节：不得新增用户没有表达的事实）。
        case likelyAddedContent
    }

    // MARK: - 请求前初筛

    static func prescreen(_ text: String) -> Prescreen {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        guard trimmed.count <= maxSourceLength else { return .tooLong }
        if SafetyPrescreen.isHighRisk(trimmed) { return .highRisk }
        return .ok
    }

    // MARK: - 返回后校验

    static func check(rewrite: String, source: String) -> Check {
        let trimmed = rewrite.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        guard trimmed.count <= maxRewriteLength else { return .tooLong }

        let identifiers = detectedIdentifiers(in: trimmed)
        guard identifiers.isEmpty else { return .containsIdentifiers(identifiers) }

        // 防止 AI 新增大量未表达事实：改写后明显比原文更长视为异常（spec 第 6 节）。
        let sourceCount = source.trimmingCharacters(in: .whitespacesAndNewlines).count
        if sourceCount > 0, trimmed.count > sourceCount + 40 {
            return .likelyAddedContent
        }
        return .ok
    }

    /// 识别可识别信息类别（spec 第 6 节、12.1 条 7：姓名、手机号、邮箱、社交账号、学校、公司、地址）。
    static func detectedIdentifiers(in text: String) -> [String] {
        var hits: [String] = []

        if matches(text, #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#) {
            hits.append("邮箱")
        }
        if matches(text, #"(?<!\d)1[3-9]\d{9}(?!\d)"#) {
            hits.append("手机号")
        }
        // 社交账号：微信 / QQ / 微博 / 小红书 / 抖音 + 号/id；或 @handle。
        if matches(text, #"(微信|微信号|wechat|QQ|qq|微博|小红书|抖音|ID|id)\s*[:：]?\s*[A-Za-z0-9_-]{4,}"#)
            || matches(text, #"(?<![A-Za-z0-9])@[A-Za-z0-9_]{3,}"#) {
            hits.append("社交账号")
        }
        if matches(text, #"[一-龥]{2,}(大学|学院|中学|小学|学校)"#) {
            hits.append("学校")
        }
        if matches(text, #"[一-龥]{2,}(公司|集团|有限|科技|事务所|工作室|医院|银行)"#) {
            hits.append("单位")
        }
        // 精确地址：含省/市/区/路/号/栋/室等门牌粒度。
        if matches(text, #"[一-龥]{2,}(路|街|号楼|小区|大厦)[一-龥0-9]{0,}(\d+号|\d+室|\d+栋)"#)
            || matches(text, #"\d+号(楼|院)?\d*(室|单元)"#) {
            hits.append("精确地址")
        }
        // 中文姓名：常见“老X / 小X / 姓+名”模式，配合关系词降低误判。
        if matches(text, #"(我叫|名字叫|姓名是|我是)\s*[一-龥]{2,4}"#) {
            hits.append("姓名")
        }

        return hits
    }

    private static func matches(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}
