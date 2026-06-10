import SwiftData
import SwiftUI

struct CalendarView: View {
    @Query(sort: \DayEntry.date, order: .forward) private var entries: [DayEntry]
    @State private var displayedDate = Date()
    @State private var selectedDate: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        let month = CalendarMonth(containing: displayedDate)
        let entriesByDay = Dictionary(grouping: entries, by: { Calendar.current.startOfDay(for: $0.date) })
            .compactMapValues { $0.sorted { $0.updatedAt > $1.updatedAt }.first }
        let selectedEntry = selectedDate.flatMap { entriesByDay[Calendar.current.startOfDay(for: $0)] }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                monthHeader(for: month)
                weekdayHeader

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(month.days) { day in
                        dayCell(day: day, entry: entriesByDay[day.date])
                    }
                }

                selectedSummary(entry: selectedEntry)
                    .animation(.spring(response: 0.5, dampingFraction: 0.86), value: selectedDate)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 112)
        }
        .background(DayGlyphBackground())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectInitialEntry(in: month, entriesByDay: entriesByDay)
        }
        .onChange(of: displayedDate) {
            let nextMonth = CalendarMonth(containing: displayedDate)
            selectInitialEntry(in: nextMonth, entriesByDay: entriesByDay)
        }
    }

    private func monthHeader(for month: CalendarMonth) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("情绪星图")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(DayGlyphStyle.jade)
                Text(month.displayedMonth, format: .dateTime.year().month())
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(DayGlyphStyle.ink)
            }

            Spacer()

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    monthButton(systemName: "chevron.left") {
                        displayedDate = month.addingMonths(-1)
                    }
                    monthButton(systemName: "chevron.right") {
                        displayedDate = month.addingMonths(1)
                    }
                }
            }
        }
    }

    private func monthButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.bold))
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.glass)
        .accessibilityLabel(systemName == "chevron.left" ? "上个月" : "下个月")
    }

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                Text(day)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(DayGlyphStyle.mutedInk.opacity(0.78))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(day: CalendarDay, entry: DayEntry?) -> some View {
        let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: day.date) } ?? false

        return Button {
            selectedDate = day.date
        } label: {
            VStack(spacing: 2) {
                Text("\(day.dayNumber)")
                    .font(.caption2.weight(isSelected ? .bold : .semibold))
                    .foregroundStyle(
                        day.isInDisplayedMonth
                            ? DayGlyphStyle.ink
                            : DayGlyphStyle.mutedInk.opacity(0.3)
                    )

                if let entry {
                    let signature = GlyphSignature(analysis: entry.analysis, seed: entry.glyphSeed)
                    GlyphCanvasView(
                        signature: signature,
                        lineWidth: 1.8,
                        mode: .thumbnail
                    )
                    .frame(width: 43, height: 43)
                    .shadow(color: signature.primaryColor.opacity(isSelected ? 0.26 : 0.1), radius: 8)
                } else {
                    Circle()
                        .fill(.white.opacity(day.isInDisplayedMonth ? 0.28 : 0.1))
                        .frame(width: 25, height: 25)
                        .padding(.vertical, 9)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .contentShape(Rectangle())
            .glassEffect(
                isSelected
                    ? .regular.tint(DayGlyphStyle.jade.opacity(0.08)).interactive()
                    : .identity,
                in: .rect(cornerRadius: 15)
            )
        }
        .buttonStyle(.plain)
        .disabled(!day.isInDisplayedMonth)
        .accessibilityLabel(accessibilityLabel(for: day, entry: entry))
    }

    @ViewBuilder
    private func selectedSummary(entry: DayEntry?) -> some View {
        if let selectedDate {
            if let entry {
                let signature = GlyphSignature(analysis: entry.analysis, seed: entry.glyphSeed)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedDate, format: .dateTime.month().day().weekday())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DayGlyphStyle.mutedInk)
                            Text(entry.primaryEmotion.title)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(DayGlyphStyle.ink)
                        }

                        Spacer()

                        CapsuleLabel(text: entry.theme.title, color: signature.secondaryColor)
                    }

                    Text(entry.text)
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.ink)
                        .lineLimit(2)
                        .lineSpacing(3)

                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        HStack {
                            Text("展开这一天")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                    .tint(DayGlyphStyle.jade)
                }
                .padding(18)
                .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
                .transition(.blurReplace.combined(with: .opacity))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedDate, format: .dateTime.month().day().weekday())
                        .font(.headline)
                        .foregroundStyle(DayGlyphStyle.ink)
                    Text("这一天还没有留下情绪印记。")
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.mutedInk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
            }
        } else {
            Text("选择一天，查看它的情绪结构。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.mutedInk)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
        }
    }

    private func selectInitialEntry(in month: CalendarMonth, entriesByDay: [Date: DayEntry]) {
        if month.days.contains(where: { Calendar.current.isDateInToday($0.date) }) {
            selectedDate = Calendar.current.startOfDay(for: .now)
            return
        }
        selectedDate = month.days
            .filter(\.isInDisplayedMonth)
            .compactMap { entriesByDay[$0.date]?.date }
            .last
            ?? month.displayedMonth
    }

    private func accessibilityLabel(for day: CalendarDay, entry: DayEntry?) -> String {
        let date = day.date.formatted(.dateTime.month().day())
        guard let entry else { return "\(date)，没有记录" }
        return "\(date)，\(entry.primaryEmotion.title)，\(entry.theme.title)"
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
