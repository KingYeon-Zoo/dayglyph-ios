import SwiftData
import SwiftUI

nonisolated enum TodayRoute: Hashable {
    case record
    case generating(String)
}

struct TodayHomeView: View {
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]
    @Query(sort: \AIGenerationRecord.createdAt, order: .reverse) private var generationRecords: [AIGenerationRecord]

    var recordRequest: Int = 0

    @State private var path: [TodayRoute] = []
    @State private var draftText = ""

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let todayEntry {
                        if let record = generationRecord(for: todayEntry), let response = record.response {
                            PersistedAIDayView(entry: todayEntry, record: record, response: response)
                        } else {
                            // 仅供升级前的历史数据与演示数据兼容；新记录全部走 AI 结果。
                            CocktailResultView(entry: todayEntry, mode: .today)
                            WeatherQuoteSection(entry: todayEntry)
                            MicroActionSection(entry: todayEntry)
                        }
                        TimeLetterSection(entry: todayEntry)
                        EmpathySeaSection(entry: todayEntry)
                    } else {
                        emptyState
                        MicroActionSection(entry: nil)
                        TimeLetterSection(entry: nil)
                        EmpathySeaSection(entry: nil)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 112)
            }
            .background(DayGlyphBackground())
            .navigationTitle("今日")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TodayRoute.self) { route in
                switch route {
                case .record:
                    EmotionRecordView(text: $draftText) { text in
                        path.append(.generating(text))
                    }
                case .generating(let text):
                    DayGenerationView(text: text) { _ in
                        draftText = ""
                        path.removeAll()
                    }
                }
            }
        }
        .onChange(of: recordRequest) {
            guard todayEntry == nil else { return }
            path = [.record]
        }
    }

    private var todayEntry: DayEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: .now) }
    }

    private func generationRecord(for entry: DayEntry) -> AIGenerationRecord? {
        generationRecords.first { $0.entryID == entry.entryID && $0.response != nil }
            ?? generationRecords.first {
                // 修复旧版本生成链路写出不同 entryID 后遗留的孤立结果。
                $0.response != nil && Calendar.current.isDate($0.createdAt, inSameDayAs: entry.date)
            }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text("把今天调成一杯只属于你的情绪鸡尾酒。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "wineglass")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(DayGlyphStyle.today)
                .frame(width: 68, height: 68)
                .background(DayGlyphStyle.todaySoft, in: Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text("今天想调制什么？")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                Text("写一句也可以。DayGlyph 会把你的文字转成情绪配方。")
                    .font(.body)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .lineSpacing(4)
            }

            NavigationLink(value: TodayRoute.record) {
                Label("开始记录", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(.glassProminent)
            .tint(DayGlyphStyle.today)
            .padding(.top, 4)
        }
        .padding(24)
        .paperCard(cornerRadius: DayGlyphStyle.heroRadius)
    }
}

private struct PersistedAIDayView: View {
    var entry: DayEntry
    var record: AIGenerationRecord
    var response: DayGenerationResponse

    private let assetStore = GeneratedAssetStore()

    private var narrative: ResultNarrativeSpec? {
        GenerationExtrasValidator.sanitizedResultNarrative(response.resultNarrative)
    }

    private var actionOptions: [ActionOptionSpec]? {
        GenerationExtrasValidator.sanitizedActionOptions(response.actionOptions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            hero
            EmotionDetailSection(payload: response.emotionAnalysis)
            supportCard(
                title: response.emotionalWeather.title,
                text: response.emotionalWeather.explanation,
                symbol: weatherSymbol(response.emotionalWeather.symbol)
            )
            supportCard(
                title: "DayGlyph 今日寄语",
                text: response.dailyMessage.text,
                symbol: "quote.opening"
            )

            if let actionOptions {
                AIActionOptionsSection(options: actionOptions, entryID: entry.entryID)
            } else {
                aiActionCard(response.dailyAction)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(narrative?.headline ?? response.cocktail.name)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                Text(narrative?.explanation ?? response.cocktail.description)
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .lineSpacing(4)
            }

            generatedImage(
                slot: .cocktail,
                title: narrative?.cocktailName ?? response.cocktail.name,
                aspectRatio: 4.0 / 5.0
            )
            generatedImage(
                slot: .planet,
                title: narrative?.planetName ?? response.planet.name,
                aspectRatio: 1
            )
        }
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.heroRadius)
    }

    @ViewBuilder
    private func generatedImage(
        slot: GeneratedAssetStore.Slot,
        title: String,
        aspectRatio: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)

            if let data = assetStore.load(
                entryID: record.entryID,
                generationID: record.generationID,
                slot: slot
            ), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: DayGlyphStyle.largeRadius, style: .continuous))
            } else {
                Label("AI 图片文件暂时不可用", systemImage: "photo.badge.exclamationmark")
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(DayGlyphStyle.todaySoft, in: RoundedRectangle(cornerRadius: DayGlyphStyle.largeRadius))
            }
        }
    }

    private func supportCard(title: String, text: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private func aiActionCard(_ action: DailyActionSpec) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(action.title, systemImage: "figure.walk")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text(action.instruction)
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text("约 \(action.durationMinutes) 分钟 · \(action.reason)")
                .font(.footnote)
                .foregroundStyle(DayGlyphStyle.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private func weatherSymbol(_ token: String) -> String {
        switch token {
        case "clear": "sun.max"
        case "cloudy": "cloud"
        case "drizzle": "cloud.drizzle"
        case "rain": "cloud.rain"
        case "fog": "cloud.fog"
        case "breeze": "wind"
        default: "cloud.sun"
        }
    }
}

#Preview {
    TodayHomeView()
        .modelContainer(
            for: [DayEntry.self, ActionInstance.self, TimeLetter.self, EmpathyCopy.self],
            inMemory: true
        )
}
