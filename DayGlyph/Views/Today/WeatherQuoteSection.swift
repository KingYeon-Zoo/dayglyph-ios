import SwiftUI

struct WeatherQuoteSection: View {
    var entry: DayEntry

    @AppStorage("todayQuoteSwitchCount") private var switchCount = 0
    @AppStorage("todayQuoteSwitchDay") private var switchDay = ""
    @State private var presentedDetail: WeatherQuoteDetail?

    private var presentation: MoodWeatherPresentation {
        WeatherQuoteCatalog.presentation(for: entry.moodWeather)
    }

    private var quote: SupportQuote {
        WeatherQuoteCatalog.quote(
            for: entry.emotionRecipe.primary,
            date: entry.date,
            switchCount: switchCount
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            weatherCard
            quoteCard
        }
        .task { resetSwitchCountForTodayIfNeeded() }
        .sheet(item: $presentedDetail) { detail in
            NavigationStack {
                VStack(alignment: .leading, spacing: 18) {
                    Label(detail.title, systemImage: detail.symbol)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(DayGlyphStyle.textPrimary)

                    Text(detail.body)
                        .font(.body)
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                        .lineSpacing(5)

                    Spacer()
                }
                .padding(24)
                .background(DayGlyphBackground())
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { presentedDetail = nil }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var weatherCard: some View {
        Button {
            presentedDetail = WeatherQuoteDetail(
                title: "为什么是这种天气",
                symbol: presentation.symbolName,
                body: entry.moodWeather.explanation + " 天气只是一种轻量隐喻，不代表判断或预测。"
            )
        } label: {
            HStack(spacing: 18) {
                Image(systemName: presentation.symbolName)
                    .font(.system(size: 34, weight: .semibold))
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 62, height: 62)
                    .background(DayGlyphStyle.mineSoft, in: Circle())

                VStack(alignment: .leading, spacing: 8) {
                    Text("今天的天气")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                    Text(presentation.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DayGlyphStyle.textPrimary)
                    Text("点击查看这份天气的由来")
                        .font(.caption)
                        .foregroundStyle(DayGlyphStyle.mine)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            .padding(20)
            .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(presentation.accessibilityDescription)
    }

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("留给今天的一句话", systemImage: "quote.opening")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)

            Text(quote.text)
                .font(.title3.weight(.medium))
                .foregroundStyle(DayGlyphStyle.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            if let attribution = quote.attribution {
                Text("— \(attribution)")
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { switchQuoteButton; explainQuoteButton }
                VStack(spacing: 8) { switchQuoteButton; explainQuoteButton }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private var switchQuoteButton: some View {
        Button {
            guard WeatherQuoteCatalog.canSwitch(currentCount: switchCount) else { return }
            switchCount += 1
        } label: {
            Label("换一句", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glass)
        .disabled(WeatherQuoteCatalog.canSwitch(currentCount: switchCount) == false)
    }

    private var explainQuoteButton: some View {
        Button {
            presentedDetail = WeatherQuoteDetail(
                title: "为什么是这句话",
                symbol: "text.magnifyingglass",
                body: quote.matchExplanation
            )
        } label: {
            Text("为什么是这句话")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(DayGlyphStyle.textSecondary)
    }

    private func resetSwitchCountForTodayIfNeeded() {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: .now)
        guard switchDay != today else { return }
        switchDay = today
        switchCount = 0
    }
}

private struct WeatherQuoteDetail: Identifiable {
    let id = UUID()
    var title: String
    var symbol: String
    var body: String
}
