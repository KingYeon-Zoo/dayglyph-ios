import SwiftData
import SwiftUI

struct CalendarView: View {
    @Query(sort: \DayEntry.date, order: .forward) private var entries: [DayEntry]
    @State private var displayedDate = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    var body: some View {
        let month = CalendarMonth(containing: displayedDate)
        let entriesByDay = Dictionary(grouping: entries, by: { Calendar.current.startOfDay(for: $0.date) })
            .compactMapValues { $0.sorted { $0.updatedAt > $1.updatedAt }.first }

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                monthHeader(for: month)
                weekdayHeader

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(month.days) { day in
                        dayCell(day: day, entry: entriesByDay[day.date])
                    }
                }

                if entries.isEmpty {
                    Text("还没有记录")
                        .font(.callout)
                        .foregroundStyle(DayGlyphStyle.mutedInk)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                }
            }
            .padding(22)
            .padding(.bottom, 96)
        }
        .background(DayGlyphStyle.background.ignoresSafeArea())
        .navigationTitle("情绪月历")
    }

    private func monthHeader(for month: CalendarMonth) -> some View {
        HStack {
            Text(month.displayedMonth, format: .dateTime.year().month())
                .font(.system(size: 32, weight: .bold, design: .serif))

            Spacer()

            Button {
                displayedDate = month.addingMonths(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)

            Button {
                displayedDate = month.addingMonths(1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
        }
    }

    private var weekdayHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("日 一 二 三 四 五 六")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.mutedInk)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DayGlyphStyle.mutedInk)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(day: CalendarDay, entry: DayEntry?) -> some View {
        if let entry {
            NavigationLink {
                EntryDetailView(entry: entry)
            } label: {
                glyphDayContent(day: day, entry: entry)
            }
            .buttonStyle(.plain)
        } else {
            emptyDayContent(day: day)
        }
    }

    private func glyphDayContent(day: CalendarDay, entry: DayEntry) -> some View {
        let signature = GlyphSignature(
            analysis: EmotionAnalysis(emotion: entry.emotion, theme: entry.theme, energy: entry.energy, keywords: entry.keywords),
            seed: entry.glyphSeed
        )

        return VStack(spacing: 4) {
            Text("\(day.dayNumber)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(day.isInDisplayedMonth ? DayGlyphStyle.ink : DayGlyphStyle.mutedInk.opacity(0.45))
            GlyphCanvasView(signature: signature, lineWidth: 2)
                .padding(3)
        }
        .frame(height: 72)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 12))
    }

    private func emptyDayContent(day: CalendarDay) -> some View {
        VStack(spacing: 5) {
            Text("\(day.dayNumber)")
                .font(.caption2.weight(.semibold))
            Circle()
                .fill(.white.opacity(day.isInDisplayedMonth ? 0.34 : 0.12))
                .frame(width: 24, height: 24)
        }
        .foregroundStyle(day.isInDisplayedMonth ? DayGlyphStyle.mutedInk.opacity(0.64) : DayGlyphStyle.mutedInk.opacity(0.25))
        .frame(height: 72)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
