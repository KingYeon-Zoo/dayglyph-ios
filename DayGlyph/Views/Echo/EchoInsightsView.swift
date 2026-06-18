import SwiftUI

struct EchoInsightsView: View {
    var insights: [EchoInsight]

    var body: some View {
        List(insights) { insight in
            VStack(alignment: .leading, spacing: 12) {
                Label(insight.category.title, systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(DayGlyphStyle.echo)
                Text(insight.summary)
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                Text("样本 \(insight.sampleCount) 次 · \(insight.startedAt.formatted(date: .abbreviated, time: .omitted)) 至 \(insight.endedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                ForEach(ActionResponseKind.allCases) { kind in
                    if let count = insight.distribution[kind], count > 0 {
                        LabeledContent(kind.title, value: "\(count) 次")
                            .font(.subheadline)
                    }
                }
                Text("这些描述只反映你留下的记录，不代表行动与感受之间存在因果关系。")
                    .font(.caption)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            }
            .padding(.vertical, 8)
        }
        .scrollContentBackground(.hidden)
        .background(DayGlyphBackground())
        .navigationTitle("我的发现")
    }
}
