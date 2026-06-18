import Foundation
import Testing
@testable import DayGlyph

struct WeatherQuoteCatalogTests {
    @Test func sameDayAndAnchorSelectTheSameQuote() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 18)))

        let first = WeatherQuoteCatalog.quote(for: .calm, date: date, switchCount: 0, calendar: calendar)
        let second = WeatherQuoteCatalog.quote(for: .calm, date: date, switchCount: 0, calendar: calendar)

        #expect(first == second)
        #expect(first.text.isEmpty == false)
    }

    @Test func everyMoodWeatherHasTextualPresentation() {
        let weather = MoodWeather(
            type: "微风",
            intensityBand: "柔和",
            animationSeed: 12,
            explanation: "今天的状态更接近舒缓的微风。"
        )

        let presentation = WeatherQuoteCatalog.presentation(for: weather)

        #expect(presentation.title.contains("微风"))
        #expect(presentation.accessibilityDescription.isEmpty == false)
        #expect(presentation.symbolName.isEmpty == false)
    }

    @Test func missingCuratedQuoteUsesProductCopyWithoutFakeAttribution() {
        let quote = WeatherQuoteCatalog.quote(for: .numb, date: .distantPast, switchCount: 0)

        #expect(quote.isProductCopy)
        #expect(quote.attribution == nil)
        #expect(quote.text.isEmpty == false)
    }

    @Test func quoteCanOnlySwitchThreeTimesPerDay() {
        #expect(WeatherQuoteCatalog.canSwitch(currentCount: 0))
        #expect(WeatherQuoteCatalog.canSwitch(currentCount: 2))
        #expect(WeatherQuoteCatalog.canSwitch(currentCount: 3) == false)
    }
}
