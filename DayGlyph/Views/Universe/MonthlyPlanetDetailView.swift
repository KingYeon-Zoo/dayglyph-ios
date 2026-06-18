import SwiftUI

struct MonthlyPlanetDetailView: View {
    var month: MonthlyUniverseSummary
    var entries: [DayEntry]

    @State private var selectedDay: UniverseDaySummary?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                UniversePlanetView(visual: month.visual, size: 270)

                VStack(alignment: .leading, spacing: 10) {
                    Text(month.monthStart, format: .dateTime.year().month())
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(UniversePresentation.monthSummary(recordCount: month.recordCount))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.72))
                }

                insightCard
                UniverseAccessibleList(month: month) { selectedDay = $0 }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 112)
        }
        .background(DayGlyphStyle.universeBackground.ignoresSafeArea())
        .navigationTitle("月星球详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDay) { day in
            daySummary(for: day)
        }
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("这颗星球如何形成", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.white)

            detailRow(title: "内部层次", value: UniversePresentation.complexityDescription(month.visual.textureComplexity))
            detailRow(title: "有记录的日子", value: "\(month.recordCount) 天")
            detailRow(title: "常见关键词", value: month.keywords.isEmpty ? "还没有关键词" : month.keywords.joined(separator: " · "))

            Text("颜色和层次只描述这段时间留下的记录，不代表情绪好坏或等级。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(18)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).foregroundStyle(.white.opacity(0.64))
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.white)
        }
        .font(.subheadline)
    }

    private func daySummary(for day: UniverseDaySummary) -> some View {
        UniverseDaySummaryView(
            day: day,
            entry: entries.first { $0.entryID == day.entryID },
            previousAction: adjacentAction(from: day, direction: .previous),
            nextAction: adjacentAction(from: day, direction: .next)
        )
    }

    private func adjacentAction(
        from day: UniverseDaySummary,
        direction: UniverseDateDirection
    ) -> (() -> Void)? {
        guard let nextDate = UniverseInteractionPolicy.adjacentDate(
            to: day.date,
            direction: direction,
            in: month.days.map(\.date)
        ), let adjacent = month.days.first(where: { $0.date == nextDate }) else {
            return nil
        }
        return { selectedDay = adjacent }
    }
}
