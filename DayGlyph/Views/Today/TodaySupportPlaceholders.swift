import SwiftUI

struct TodaySupportPlaceholders: View {
    private let modules: [TodaySupportModule] = [
        TodaySupportModule(title: "今天的天气", symbol: "cloud.sun", body: "把今天的状态放进更长的时间线里看。"),
        TodaySupportModule(title: "今天迈一小步", symbol: "figure.walk", body: "从当下情绪里找到一个很轻的小行动。"),
        TodaySupportModule(title: "时间来信", symbol: "envelope", body: "给未来的自己留下一句温柔提醒。"),
        TodaySupportModule(title: "共情海", symbol: "water.waves", body: "在不暴露隐私的前提下看见相似感受。")
    ]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(modules) { module in
                VStack(alignment: .leading, spacing: 12) {
                    Label(module.title, systemImage: module.symbol)
                        .font(.headline)
                        .foregroundStyle(DayGlyphStyle.textPrimary)

                    Text(module.body)
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                        .lineSpacing(4)

                    Button("下一阶段接入") {}
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.glass)
                        .disabled(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
            }
        }
    }
}

private struct TodaySupportModule: Identifiable {
    var title: String
    var symbol: String
    var body: String

    var id: String { title }
}
