import SwiftData
import SwiftUI

nonisolated enum TodayRoute: Hashable {
    case record
    case generating(String)
}

struct TodayHomeView: View {
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]

    @State private var path: [TodayRoute] = []
    @State private var draftText = ""

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let todayEntry {
                        CocktailResultView(entry: todayEntry, mode: .today)
                        TodaySupportPlaceholders()
                    } else {
                        emptyState
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
                    EmotionGeneratingView(text: text) { _ in
                        draftText = ""
                        path.removeAll()
                    }
                }
            }
        }
    }

    private var todayEntry: DayEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: .now) }
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

#Preview {
    TodayHomeView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
