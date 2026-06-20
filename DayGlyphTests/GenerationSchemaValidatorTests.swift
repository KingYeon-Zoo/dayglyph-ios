import Testing
import Foundation
@testable import DayGlyph

/// Schema 校验测试（spec 第 6、14 节）。
@MainActor
struct GenerationSchemaValidatorTests {

    @Test func acceptsValidResponse() throws {
        try GenerationSchemaValidator.validate(GenerationFixtures.validResponse())
    }

    @Test func rejectsEmotionCountAboveEight() {
        let response = GenerationFixtures.validResponse {
            $0.emotionAnalysis.emotions = (0..<9).map { _ in
                EmotionItem(term: "欣慰", family: "joy", intensity: 0.5, confidence: 0.5, evidence: "x")
            }
        }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }

    @Test func rejectsZeroEmotions() {
        let response = GenerationFixtures.validResponse { $0.emotionAnalysis.emotions = [] }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }

    @Test func rejectsDuplicateEmotionTerms() {
        let response = GenerationFixtures.validResponse {
            $0.emotionAnalysis.emotions = [
                EmotionItem(term: "欣慰", family: "joy", intensity: 0.5, confidence: 0.5, evidence: "a"),
                EmotionItem(term: "欣慰", family: "joy", intensity: 0.4, confidence: 0.5, evidence: "b")
            ]
        }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }

    @Test func rejectsTermOutsideLexicon() {
        let response = GenerationFixtures.validResponse {
            $0.emotionAnalysis.emotions = [
                EmotionItem(term: "薛定谔的情绪", family: "joy", intensity: 0.5, confidence: 0.5, evidence: "x")
            ]
        }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }

    @Test func rejectsIntensityOutOfRange() {
        let response = GenerationFixtures.validResponse {
            $0.emotionAnalysis.emotions = [
                EmotionItem(term: "欣慰", family: "joy", intensity: 1.5, confidence: 0.5, evidence: "x")
            ]
        }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }

    @Test func rejectsForbiddenDiagnosticLanguage() {
        let response = GenerationFixtures.validResponse {
            $0.emotionAnalysis.summary = "你这是抑郁症的典型表现。"
        }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }

    @Test func rejectsMessageWithoutBrandAttribution() {
        let response = GenerationFixtures.validResponse {
            $0.dailyMessage.attribution = "鲁迅"
        }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }

    @Test func rejectsTooManyLiquidLayers() {
        let response = GenerationFixtures.validResponse {
            $0.cocktail.liquidLayers = (0..<6).map { _ in
                LiquidLayer(color: "amber", boundaryStyle: "soft_diffusion")
            }
        }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }

    @Test func rejectsInvalidPaletteColor() {
        let response = GenerationFixtures.validResponse {
            $0.sharedVisualDirection.palette = ["not-a-color"]
        }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }

    @Test func rejectsDimensionOutOfRange() {
        let response = GenerationFixtures.validResponse {
            $0.emotionAnalysis.dimensions.valence = -2
        }
        #expect(throws: GenerationValidationError.self) {
            try GenerationSchemaValidator.validate(response)
        }
    }
}
