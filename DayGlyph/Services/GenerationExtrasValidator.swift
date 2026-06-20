import Foundation

/// 即时情境个性化扩展字段的非抛错校验（contextual personalization spec 第 5、10 节）。
///
/// 与核心 `GenerationSchemaValidator` 的关键差异：**永不抛错、永不阻塞核心结果**。
/// 每个扩展模块独立清洗，返回合法值或 `nil`；`nil` 时由 UI 回退本地默认内容。
/// 这样保证“核心情绪 + 双图成功，但分享卡 / 行动 / 过程文案任一非法”时核心结果照常展示（spec 第 10 节）。
enum GenerationExtrasValidator {

    // MARK: - 受控枚举（spec 5.4：不接受自由布局，只接受客户端受控集合）

    static let validActionLevels: [String] = ["light", "standard", "active"]
    static let validVisualFocus: Set<String> = ["cocktail", "planet"]
    static let validLayoutVariants: Set<String> = ["portrait_centered", "square_centered", "minimal"]
    static let validPrivacyLevels: Set<String> = ["emotion_only"]

    /// 行动指令中的禁止内容（spec 5.3：不要求购买、饮酒、服药、驾驶或进入危险环境）。
    static let forbiddenActionTerms: [String] = [
        "购买", "下单", "付款", "饮酒", "喝酒", "酒精", "服药", "吃药", "药物",
        "驾驶", "开车", "危险", "攀爬", "高处"
    ]

    // MARK: - 过程文案（spec 5.1）

    /// 清洗过程文案：三段都需非空且不超长、不含诊断措辞，否则整体回退。
    static func sanitizedExperienceCopy(_ copy: ExperienceCopySpec?) -> ExperienceCopySpec? {
        guard let copy else { return nil }
        let segments = [copy.imageGenerationTitle, copy.cocktailProgress, copy.planetProgress]
        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count <= 24 else { return nil }
            if containsForbiddenDiagnostic(trimmed) { return nil }
        }
        return copy
    }

    // MARK: - 结果叙事（spec 5.2）

    /// 清洗结果叙事：名称非空且不相同、标题与解释不超长、无诊断措辞。
    static func sanitizedResultNarrative(_ narrative: ResultNarrativeSpec?) -> ResultNarrativeSpec? {
        guard let narrative else { return nil }
        let cocktailName = narrative.cocktailName.trimmingCharacters(in: .whitespacesAndNewlines)
        let planetName = narrative.planetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let headline = narrative.headline.trimmingCharacters(in: .whitespacesAndNewlines)
        let explanation = narrative.explanation.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cocktailName.isEmpty, !planetName.isEmpty else { return nil }
        // 鸡尾酒名与星球名应同语义方向但不得完全相同（spec 5.2）。
        guard cocktailName != planetName else { return nil }
        guard cocktailName.count <= 12, planetName.count <= 12 else { return nil }
        guard !headline.isEmpty, headline.count <= 40 else { return nil }
        guard explanation.count <= 80 else { return nil }
        for text in [cocktailName, planetName, headline, explanation] where containsForbiddenDiagnostic(text) {
            return nil
        }
        return ResultNarrativeSpec(
            cocktailName: cocktailName,
            planetName: planetName,
            headline: headline,
            explanation: explanation
        )
    }

    // MARK: - 三档微行动（spec 5.3）

    /// 清洗三档行动：必须恰好三档、档位齐全且唯一、字段合法、无禁止内容、回声问题非空、
    /// 且在时长上存在真实差异。任一不满足返回 nil → 整组丢弃回退本地 `MicroActionCatalog`（spec 第 10 节）。
    static func sanitizedActionOptions(_ options: [ActionOptionSpec]?) -> [ActionOptionSpec]? {
        guard let options, options.count == 3 else { return nil }

        var seenLevels = Set<String>()
        for option in options {
            let level = option.level.lowercased()
            guard validActionLevels.contains(level) else { return nil }
            guard seenLevels.insert(level).inserted else { return nil }   // 档位唯一

            guard !option.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            guard !option.instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            guard (1...120).contains(option.durationMinutes) else { return nil }
            guard (1...5).contains(option.difficulty) else { return nil }
            guard !option.echoQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

            let haystack = "\(option.title)\(option.instruction)\(option.reason)"
            if forbiddenActionTerms.contains(where: haystack.contains) { return nil }
            if containsForbiddenDiagnostic(haystack) { return nil }
        }

        // 三档必须有真实差异，不能只换标题（spec 5.3）：以时长区分即可，要求三档时长不全相同。
        let durations = Set(options.map(\.durationMinutes))
        guard durations.count >= 2 else { return nil }

        // 按 light → standard → active 规范排序，便于 UI 稳定展示。
        return options.sorted {
            (validActionLevels.firstIndex(of: $0.level.lowercased()) ?? 0)
                < (validActionLevels.firstIndex(of: $1.level.lowercased()) ?? 0)
        }
    }

    // MARK: - 分享卡（spec 5.4）

    /// 清洗分享卡：受控枚举、标题/短句非空且不超长、无诊断措辞。非法返回 nil → UI 用默认版式 + 已验证名称。
    static func sanitizedShareCard(_ card: ShareCardSpec?) -> ShareCardSpec? {
        guard let card else { return nil }
        let title = card.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let caption = card.caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let visualFocus = card.visualFocus.lowercased()
        let layoutVariant = card.layoutVariant.lowercased()
        let privacyLevel = card.privacyLevel.lowercased()

        guard validVisualFocus.contains(visualFocus) else { return nil }
        guard validLayoutVariants.contains(layoutVariant) else { return nil }
        guard validPrivacyLevels.contains(privacyLevel) else { return nil }
        guard !title.isEmpty, title.count <= 16 else { return nil }
        guard !caption.isEmpty, caption.count <= 40 else { return nil }
        for text in [title, caption] where containsForbiddenDiagnostic(text) { return nil }

        return ShareCardSpec(
            title: title,
            caption: caption,
            visualFocus: visualFocus,
            layoutVariant: layoutVariant,
            privacyLevel: privacyLevel
        )
    }

    // MARK: - 工具

    private static func containsForbiddenDiagnostic(_ text: String) -> Bool {
        GenerationSchemaValidator.forbiddenDiagnosticTerms.contains(where: text.contains)
    }
}
