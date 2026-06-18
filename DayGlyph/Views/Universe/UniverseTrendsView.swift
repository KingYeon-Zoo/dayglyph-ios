import Charts
import SwiftUI
import UIKit

struct UniverseTrendsView: View {
    var entries: [DayEntry]
    var initialDate: Date

    @State private var range: UniverseTrendRange = .month
    @State private var shareItem: UniverseShareItem?
    @State private var exportError: String?

    private var summary: UniverseTrendSummary {
        UniverseTrendAggregator.summary(
            from: entries,
            anchorDate: initialDate,
            range: range
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                rangePicker
                sampleCard
                compositionCard
                arousalCard
                contextCard
                exportButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 112)
        }
        .background(DayGlyphStyle.universeBackground.ignoresSafeArea())
        .navigationTitle("宇宙趋势")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareItem) { item in
            UniverseActivityView(items: [item.url])
        }
        .alert("暂时无法导出", isPresented: exportErrorBinding) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(exportError ?? "请稍后再试。")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("描述这段时间，不给情绪打分")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("所有图表仅根据你主动留下的记录生成。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var rangePicker: some View {
        Picker("时间范围", selection: $range) {
            ForEach(UniverseTrendRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var sampleCard: some View {
        let metadata = UniverseExportMetadata(summary: summary)
        return VStack(alignment: .leading, spacing: 8) {
            Text(metadata.sampleDescription)
                .font(.headline)
                .foregroundStyle(.white)
            Text(summary.guidance)
                .font(.subheadline)
                .foregroundStyle(summary.hasEnoughDataForPatterns ? .white.opacity(0.68) : Color.orange.opacity(0.90))
            Text(metadata.sourceNotice)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.56))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .universeGlassCard()
    }

    private var compositionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("情绪构成")
                .font(.headline)
                .foregroundStyle(.white)

            if summary.emotionComposition.isEmpty {
                Text("这个范围内还没有记录。")
                    .foregroundStyle(.white.opacity(0.68))
            } else {
                Chart(summary.emotionComposition) { item in
                    BarMark(
                        x: .value("构成", item.proportion),
                        y: .value("情绪", item.anchor.title)
                    )
                    .foregroundStyle(color(for: item.anchor))
                    .annotation(position: .trailing) {
                        Text(item.proportion, format: .percent.precision(.fractionLength(0)))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }
                .chartXScale(domain: 0 ... max(summary.emotionComposition.first?.proportion ?? 1, 0.2))
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(.white.opacity(0.72))
                    }
                }
                .frame(height: max(150, CGFloat(summary.emotionComposition.count) * 38))
                .accessibilityLabel("情绪构成条形图")

                compositionTable
            }
        }
        .universeGlassCard()
    }

    private var compositionTable: some View {
        VStack(spacing: 8) {
            ForEach(summary.emotionComposition) { item in
                HStack {
                    Circle()
                        .fill(color(for: item.anchor))
                        .frame(width: 8, height: 8)
                    Text(item.anchor.title)
                    Spacer()
                    Text(item.proportion, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.76))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("情绪构成数值表")
    }

    @ViewBuilder
    private var arousalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("记录中的唤醒度波动")
                .font(.headline)
                .foregroundStyle(.white)

            if summary.hasEnoughDataForPatterns {
                Chart(summary.days) { day in
                    LineMark(
                        x: .value("日期", day.date),
                        y: .value("唤醒度", day.arousal)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(DayGlyphStyle.universe)

                    PointMark(
                        x: .value("日期", day.date),
                        y: .value("唤醒度", day.arousal)
                    )
                    .foregroundStyle(.white)
                }
                .chartYScale(domain: 0 ... 1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.10))
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(number, format: .number.precision(.fractionLength(1)))
                                    .foregroundStyle(.white.opacity(0.62))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisGridLine().foregroundStyle(.white.opacity(0.08))
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }
                .frame(height: 220)
                .accessibilityLabel("唤醒度随记录日期变化的折线图")

                Text("范围：\(summary.arousalRange.lowerBound.formatted(.number.precision(.fractionLength(2))))–\(summary.arousalRange.upperBound.formatted(.number.precision(.fractionLength(2))))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.66))
            } else {
                Label(summary.guidance, systemImage: "chart.line.downtrend.xyaxis")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.70))
            }
        }
        .universeGlassCard()
    }

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("天气与关键词")
                .font(.headline)
                .foregroundStyle(.white)

            if summary.weatherTypes.isEmpty {
                Text("暂无天气记录")
                    .foregroundStyle(.white.opacity(0.66))
            } else {
                ForEach(summary.weatherTypes.sorted(by: weatherSort), id: \.key) { weather, count in
                    HStack {
                        Text(weather)
                        Spacer()
                        Text("\(count) 天").monospacedDigit()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.76))
                }
            }

            if summary.keywords.isEmpty == false {
                Text(summary.keywords.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.top, 4)
            }
        }
        .universeGlassCard()
    }

    private var exportButton: some View {
        Button(action: exportSnapshot) {
            Label("导出静态回顾图", systemImage: "square.and.arrow.up")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.glassProminent)
        .tint(DayGlyphStyle.universe)
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(
            get: { exportError != nil },
            set: { if $0 == false { exportError = nil } }
        )
    }

    @MainActor
    private func exportSnapshot() {
        let renderer = ImageRenderer(
            content: UniverseExportCard(summary: summary)
                .frame(width: 540)
        )
        renderer.scale = 2
        guard let data = renderer.uiImage?.pngData() else {
            exportError = "图片生成失败，当前筛选仍会保留。"
            return
        }

        do {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("DayGlyph-宇宙回顾-\(range.rawValue).png")
            try data.write(to: url, options: .atomic)
            shareItem = UniverseShareItem(url: url)
        } catch {
            exportError = "图片保存失败，请检查设备可用空间后再试。"
        }
    }

    private func color(for anchor: EmotionVisualAnchor) -> Color {
        let index = EmotionVisualAnchor.allCases.firstIndex(of: anchor) ?? 0
        let hues = [344.0, 171, 252, 329, 33, 232, 222, 260, 352, 226, 199, 210]
        return Color(hue: hues[index] / 360, saturation: 0.62, brightness: 0.94)
    }

    private func weatherSort(
        _ lhs: Dictionary<String, Int>.Element,
        _ rhs: Dictionary<String, Int>.Element
    ) -> Bool {
        lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
    }
}

private extension View {
    func universeGlassCard() -> some View {
        padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
    }
}
