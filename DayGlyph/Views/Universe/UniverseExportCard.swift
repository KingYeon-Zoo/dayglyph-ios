import Charts
import SwiftUI
import UIKit

struct UniverseExportCard: View {
    var summary: UniverseTrendSummary

    private var metadata: UniverseExportMetadata {
        UniverseExportMetadata(summary: summary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(metadata.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(metadata.sampleDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.70))
            }

            if summary.emotionComposition.isEmpty {
                Text("这个范围内还没有记录。")
                    .foregroundStyle(.white.opacity(0.70))
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart(summary.emotionComposition) { item in
                    BarMark(
                        x: .value("构成", item.proportion),
                        y: .value("情绪", item.anchor.title)
                    )
                    .foregroundStyle(DayGlyphStyle.universe)
                    .annotation(position: .trailing) {
                        Text(item.proportion, format: .percent.precision(.fractionLength(0)))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(.white.opacity(0.76))
                    }
                }
                .frame(height: max(190, CGFloat(summary.emotionComposition.count) * 42))
            }

            HStack(spacing: 18) {
                fact(title: "记录日", value: "\(summary.recordDayCount)")
                fact(title: "天气类型", value: "\(summary.weatherTypes.count)")
                fact(title: "关键词", value: "\(summary.keywords.count)")
            }

            Text(summary.guidance)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))

            HStack {
                Text("DayGlyph")
                    .font(.headline)
                Spacer()
                Text(metadata.sourceNotice)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
        .foregroundStyle(.white)
        .padding(34)
        .background(
            LinearGradient(
                colors: [DayGlyphStyle.universeBackground, Color(red: 0.16, green: 0.12, blue: 0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func fact(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UniverseShareItem: Identifiable {
    var id: URL { url }
    var url: URL
}

struct UniverseActivityView: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
