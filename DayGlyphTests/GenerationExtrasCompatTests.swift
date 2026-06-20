import Testing
import Foundation
@testable import DayGlyph

/// 个性化扩展字段的向后兼容与降级样本测试（contextual personalization spec 第 10、12 节）。
@MainActor
struct GenerationExtrasCompatTests {

    /// 旧生成 JSON（不含任何扩展字段）在新增可选字段后仍可解码（spec 12.1 条 10）。
    @Test func legacyJSONWithoutExtrasStillDecodes() throws {
        let legacyJSON = """
        {
          "schema_version": "1.0",
          "request_id": "legacy",
          "safety": { "risk_level": "none", "crisis_detected": false, "rationale": "无风险" },
          "emotion_analysis": {
            "emotions": [ { "term": "疲惫", "family": "depletion", "intensity": 0.5, "confidence": 0.7, "evidence": "累" } ],
            "other_emotions": [],
            "dimensions": { "valence": 0.0, "arousal": 0.4, "dominance": 0.0, "energy": 0.4, "tension": 0.5, "certainty": 0.5, "social_connection": 0.5 },
            "relationships": [],
            "summary": "今天有些疲惫。",
            "uncertainties": []
          },
          "shared_visual_direction": {
            "palette": ["#3B6FB0"], "contrast": 0.5, "temperature": 0.5,
            "light_softness": 0.6, "spatial_density": 0.4, "motion_impression": "缓慢", "symbols": ["微尘"]
          },
          "cocktail": {
            "name": "余温", "description": "一杯", "glass": "杯", "glass_material": "crystal",
            "liquid_layers": [ { "color": "amber", "boundary_style": "soft_diffusion" } ],
            "garnish": [], "particles": "气泡", "lighting": "暖光", "camera": "特写", "background": "深蓝", "composition": "居中"
          },
          "planet": {
            "name": "余温星", "description": "一颗", "silhouette": "圆润",
            "surface": { "material": "mineral", "detail": "脉络" },
            "core": "暖核", "atmosphere": "薄雾", "rings": [], "satellites": [],
            "particles": "星尘", "lighting": "柔光", "camera": "中景", "background": "深空", "composition": "居中"
          },
          "daily_action": { "title": "呼吸", "instruction": "深呼吸三次", "duration_minutes": 2, "difficulty": "easy", "environment": "anywhere", "reason": "需要停顿" },
          "daily_message": { "text": "今天已经很努力了。", "attribution": "DayGlyph 今日寄语" },
          "emotional_weather": { "title": "多云", "explanation": "光需要时间", "symbol": "partly_cloudy" }
        }
        """
        let data = legacyJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(DayGenerationResponse.self, from: data)

        // 旧 JSON 解码成功，扩展字段为 nil，核心校验通过。
        #expect(response.experienceCopy == nil)
        #expect(response.resultNarrative == nil)
        #expect(response.actionOptions == nil)
        #expect(response.shareCard == nil)
        try GenerationSchemaValidator.validate(response)

        // 清洗器对缺失扩展返回 nil，由 UI 回退本地默认。
        #expect(GenerationExtrasValidator.sanitizedActionOptions(response.actionOptions) == nil)
        #expect(GenerationExtrasValidator.sanitizedShareCard(response.shareCard) == nil)
    }

    /// 降级样本自带的扩展字段全部合法（spec 第 8、14 节：现场降级可完整演示新功能）。
    @Test func demoFallbackExtrasAreValid() {
        let sample = DemoFallbackCatalog.richSample
        #expect(GenerationExtrasValidator.sanitizedExperienceCopy(sample.experienceCopy) != nil)
        #expect(GenerationExtrasValidator.sanitizedResultNarrative(sample.resultNarrative) != nil)
        #expect(GenerationExtrasValidator.sanitizedActionOptions(sample.actionOptions)?.count == 3)
        #expect(GenerationExtrasValidator.sanitizedShareCard(sample.shareCard) != nil)
    }
}
