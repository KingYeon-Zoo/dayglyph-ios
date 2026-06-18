import SwiftData
import SwiftUI

struct UniverseView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \DayEntry.date, order: .forward) private var entries: [DayEntry]

    var onStartRecording: () -> Void

    @State private var selectedMonthStart: Date?
    @State private var selectedDay: UniverseDaySummary?

    var body: some View {
        ZStack {
            universeBackground

            if months.isEmpty {
                emptyState
            } else if let month = selectedMonth {
                monthOverview(month)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear(perform: selectInitialMonth)
        .onChange(of: months.map(\.id)) { validateSelection() }
        .sheet(item: $selectedDay) { day in
            daySummary(for: day)
        }
    }

    private var months: [MonthlyUniverseSummary] {
        UniverseAggregator.months(from: entries)
    }

    private var selectedMonth: MonthlyUniverseSummary? {
        months.first { $0.monthStart == selectedMonthStart } ?? months.last
    }

    private var universeBackground: some View {
        ZStack {
            DayGlyphStyle.universeBackground
            RadialGradient(
                colors: [DayGlyphStyle.universe.opacity(0.24), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 420
            )
            Canvas { context, size in
                let count = months.isEmpty ? 18 : 58
                for index in 0 ..< count {
                    let x = CGFloat((index * 47) % 101) / 100 * size.width
                    let y = CGFloat((index * 71) % 103) / 102 * size.height
                    let diameter = CGFloat(index % 3 + 1)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                        with: .color(.white.opacity(0.18 + Double(index % 4) * 0.06))
                    )
                }
            }
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            UniversePlanetView(
                visual: MonthlyPlanetVisual(
                    seed: 0,
                    baseHue: 252,
                    secondaryHue: 310,
                    textureComplexity: 0.2,
                    glow: 0.25,
                    sizeScale: 0.86,
                    rings: 1,
                    satellites: 0,
                    rotationSpeed: 0,
                    recordDots: []
                ),
                size: 210
            )
            .opacity(0.62)
            .frame(height: 230)

            VStack(spacing: 9) {
                Text("你的宇宙还在等待第一颗星球")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("留下第一杯心情鸡尾酒，这里就会点亮一个属于你的日子。")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
            }

            Button(action: onStartRecording) {
                Label("记录今天", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.glassProminent)
            .tint(DayGlyphStyle.universe)
        }
        .padding(24)
        .frame(maxWidth: 520)
        .padding(.horizontal, 20)
    }

    private func monthOverview(_ month: MonthlyUniverseSummary) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                monthHeader(month)

                UniversePlanetView(visual: month.visual)
                    .contentShape(Rectangle())
                    .gesture(monthSwipeGesture)

                VStack(alignment: .leading, spacing: 12) {
                    Text(UniversePresentation.monthSummary(recordCount: month.recordCount))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.78))

                    HStack(spacing: 12) {
                        NavigationLink {
                            MonthlyPlanetDetailView(month: month, entries: entries)
                        } label: {
                            Label("月星球详情", systemImage: "sparkles")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(DayGlyphStyle.universe)

                        NavigationLink {
                            UniverseTrendsPlaceholderView(month: month)
                        } label: {
                            Label("查看趋势", systemImage: "chart.xyaxis.line")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.glass)
                    }
                }
                .padding(18)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                UniverseAccessibleList(month: month) { selectedDay = $0 }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 112)
        }
    }

    private func monthHeader(_ month: MonthlyUniverseSummary) -> some View {
        HStack(spacing: 12) {
            monthButton(systemName: "chevron.left", offset: -1)

            VStack(spacing: 3) {
                Text("情绪宇宙")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.62))
                Text(month.monthStart, format: .dateTime.year().month())
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)

            monthButton(systemName: "chevron.right", offset: 1)
        }
        .overlay(alignment: .bottom) {
            if !Calendar.current.isDate(month.monthStart, equalTo: .now, toGranularity: .month) {
                Button("回到本月") { selectCurrentMonth() }
                    .font(.caption.weight(.semibold))
                    .offset(y: 24)
            }
        }
        .padding(.bottom, 10)
    }

    private func monthButton(systemName: String, offset: Int) -> some View {
        Button {
            moveMonth(by: offset)
        } label: {
            Image(systemName: systemName)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .disabled(targetMonth(offset: offset) == nil)
        .accessibilityLabel(offset < 0 ? "上一个有记录的月份" : "下一个有记录的月份")
    }

    private var monthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                let offset = UniverseInteractionPolicy.monthOffset(
                    translation: value.translation.width,
                    velocity: value.velocity.width
                )
                if offset != 0 { moveMonth(by: offset) }
            }
    }

    private func moveMonth(by offset: Int) {
        guard let target = targetMonth(offset: offset) else { return }
        if reduceMotion {
            selectedMonthStart = target.monthStart
        } else {
            withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                selectedMonthStart = target.monthStart
            }
        }
        selectedDay = nil
    }

    private func targetMonth(offset: Int) -> MonthlyUniverseSummary? {
        guard let selectedMonth,
              let index = months.firstIndex(where: { $0.id == selectedMonth.id }) else { return nil }
        let targetIndex = index + offset
        guard months.indices.contains(targetIndex) else { return nil }
        return months[targetIndex]
    }

    private func selectInitialMonth() {
        guard selectedMonthStart == nil else { return }
        selectCurrentMonth()
    }

    private func selectCurrentMonth() {
        let current = months.first {
            Calendar.current.isDate($0.monthStart, equalTo: .now, toGranularity: .month)
        } ?? months.last
        selectedMonthStart = current?.monthStart
    }

    private func validateSelection() {
        guard months.isEmpty == false else {
            selectedMonthStart = nil
            selectedDay = nil
            return
        }
        if months.contains(where: { $0.monthStart == selectedMonthStart }) == false {
            selectCurrentMonth()
        }
        if let selectedDay,
           months.flatMap(\.days).contains(where: { $0.entryID == selectedDay.entryID }) == false {
            self.selectedDay = nil
        }
    }

    private func daySummary(for day: UniverseDaySummary) -> some View {
        let month = months.first { $0.days.contains(where: { $0.id == day.id }) }
        return UniverseDaySummaryView(
            day: day,
            entry: entries.first { $0.entryID == day.entryID },
            previousAction: adjacentAction(from: day, direction: .previous, month: month),
            nextAction: adjacentAction(from: day, direction: .next, month: month)
        )
    }

    private func adjacentAction(
        from day: UniverseDaySummary,
        direction: UniverseDateDirection,
        month: MonthlyUniverseSummary?
    ) -> (() -> Void)? {
        guard let month,
              let nextDate = UniverseInteractionPolicy.adjacentDate(
                to: day.date,
                direction: direction,
                in: month.days.map(\.date)
              ),
              let adjacent = month.days.first(where: { $0.date == nextDate }) else {
            return nil
        }
        return { selectedDay = adjacent }
    }
}

private struct UniverseTrendsPlaceholderView: View {
    var month: MonthlyUniverseSummary

    var body: some View {
        Text("趋势统计将在 Stage 3C 接入")
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DayGlyphStyle.universeBackground.ignoresSafeArea())
            .navigationTitle(month.monthStart.formatted(.dateTime.year().month()))
    }
}

#Preview {
    NavigationStack {
        UniverseView(onStartRecording: {})
    }
    .modelContainer(for: DayEntry.self, inMemory: true)
}
