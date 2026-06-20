import Testing
import Foundation
@testable import DayGlyph

/// 即时情境个性化扩展字段的非阻塞校验测试（contextual personalization spec 第 5、10、12 节）。
@MainActor
struct GenerationExtrasValidatorTests {

    // MARK: - 过程文案

    @Test func acceptsValidExperienceCopy() {
        let copy = ExperienceCopySpec(
            imageGenerationTitle: "正在让余温沉入杯底",
            cocktailProgress: "把克制调成层次",
            planetProgress: "凝结一颗喘息的星球"
        )
        #expect(GenerationExtrasValidator.sanitizedExperienceCopy(copy) != nil)
    }

    @Test func rejectsOverlongExperienceCopy() {
        let copy = ExperienceCopySpec(
            imageGenerationTitle: String(repeating: "余", count: 30),
            cocktailProgress: "ok",
            planetProgress: "ok"
        )
        #expect(GenerationExtrasValidator.sanitizedExperienceCopy(copy) == nil)
    }

    @Test func nilExperienceCopyStaysNil() {
        #expect(GenerationExtrasValidator.sanitizedExperienceCopy(nil) == nil)
    }

    // MARK: - 结果叙事

    @Test func acceptsValidNarrative() {
        let narrative = ResultNarrativeSpec(
            cocktailName: "迟潮余温",
            planetName: "缓慢回声",
            headline: "今天在坚持与疲惫之间寻找空间",
            explanation: "你仍在努力维持前进，也需要为疲惫留一点位置。"
        )
        #expect(GenerationExtrasValidator.sanitizedResultNarrative(narrative) != nil)
    }

    @Test func rejectsIdenticalCocktailAndPlanetName() {
        let narrative = ResultNarrativeSpec(
            cocktailName: "余温",
            planetName: "余温",
            headline: "今天",
            explanation: "说明"
        )
        #expect(GenerationExtrasValidator.sanitizedResultNarrative(narrative) == nil)
    }

    @Test func rejectsDiagnosticInNarrative() {
        let narrative = ResultNarrativeSpec(
            cocktailName: "迟潮",
            planetName: "回声",
            headline: "你这是抑郁症",
            explanation: "说明"
        )
        #expect(GenerationExtrasValidator.sanitizedResultNarrative(narrative) == nil)
    }

    // MARK: - 三档行动

    private func makeOptions(
        levels: [String] = ["light", "standard", "active"],
        durations: [Int] = [1, 5, 10]
    ) -> [ActionOptionSpec] {
        zip(levels, durations).map { level, duration in
            ActionOptionSpec(
                level: level,
                title: "标题\(level)",
                instruction: "做一个简单的动作。",
                durationMinutes: duration,
                difficulty: 2,
                environment: ["室内"],
                reason: "原因",
                echoQuestion: "做完后感觉如何？"
            )
        }
    }

    @Test func acceptsThreeDistinctLevels() {
        let result = GenerationExtrasValidator.sanitizedActionOptions(makeOptions())
        #expect(result?.count == 3)
        #expect(result?.map(\.level) == ["light", "standard", "active"])
    }

    @Test func rejectsWrongCount() {
        let two = Array(makeOptions().prefix(2))
        #expect(GenerationExtrasValidator.sanitizedActionOptions(two) == nil)
    }

    @Test func rejectsDuplicateLevels() {
        let dup = makeOptions(levels: ["light", "light", "active"])
        #expect(GenerationExtrasValidator.sanitizedActionOptions(dup) == nil)
    }

    @Test func rejectsIdenticalDurations() {
        // 三档时长完全相同 → 无真实差异。
        let same = makeOptions(durations: [5, 5, 5])
        #expect(GenerationExtrasValidator.sanitizedActionOptions(same) == nil)
    }

    @Test func rejectsForbiddenActionContent() {
        var options = makeOptions()
        options[1].instruction = "去便利店购买一瓶酒。"
        #expect(GenerationExtrasValidator.sanitizedActionOptions(options) == nil)
    }

    @Test func rejectsEmptyEchoQuestion() {
        var options = makeOptions()
        options[0].echoQuestion = "   "
        #expect(GenerationExtrasValidator.sanitizedActionOptions(options) == nil)
    }

    @Test func sortsByLevelOrder() {
        let scrambled = makeOptions(levels: ["active", "light", "standard"], durations: [10, 1, 5])
        let result = GenerationExtrasValidator.sanitizedActionOptions(scrambled)
        #expect(result?.map(\.level) == ["light", "standard", "active"])
    }

    // MARK: - 分享卡

    private func makeShareCard(
        focus: String = "cocktail",
        layout: String = "portrait_centered",
        privacy: String = "emotion_only"
    ) -> ShareCardSpec {
        ShareCardSpec(
            title: "迟潮余温",
            caption: "今天不必立刻抵达平静。",
            visualFocus: focus,
            layoutVariant: layout,
            privacyLevel: privacy
        )
    }

    @Test func acceptsValidShareCard() {
        #expect(GenerationExtrasValidator.sanitizedShareCard(makeShareCard()) != nil)
    }

    @Test func rejectsUnknownVisualFocus() {
        #expect(GenerationExtrasValidator.sanitizedShareCard(makeShareCard(focus: "diary_text")) == nil)
    }

    @Test func rejectsUnknownLayoutVariant() {
        #expect(GenerationExtrasValidator.sanitizedShareCard(makeShareCard(layout: "free_form_html")) == nil)
    }

    @Test func rejectsUnknownPrivacyLevel() {
        #expect(GenerationExtrasValidator.sanitizedShareCard(makeShareCard(privacy: "full_diary")) == nil)
    }

    // MARK: - 核心不受扩展失败影响（spec 第 10 节）

    @Test func coreValidationIgnoresInvalidExtras() throws {
        // 即使扩展字段非法，核心 schema 校验仍应通过。
        let response = GenerationFixtures.validResponse {
            $0.actionOptions = []                 // 非法（数量不足）
            $0.shareCard = ShareCardSpec(title: "", caption: "", visualFocus: "x", layoutVariant: "y", privacyLevel: "z")
            $0.resultNarrative = nil
        }
        try GenerationSchemaValidator.validate(response)   // 不抛错即通过
        #expect(GenerationExtrasValidator.sanitizedActionOptions(response.actionOptions) == nil)
        #expect(GenerationExtrasValidator.sanitizedShareCard(response.shareCard) == nil)
    }
}
