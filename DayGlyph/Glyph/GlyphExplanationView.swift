import SwiftUI

struct GlyphExplanationView: View {
    var analysis: EmotionAnalysis
    var signature: GlyphSignature

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 16) {
                emotionComposition
                vadSummary
                grammarSummary
            }
            .padding(.top, 14)
        } label: {
            Label("为什么是这一划", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.ink)
        }
        .tint(DayGlyphStyle.mutedInk)
        .padding(16)
        .background(DayGlyphStyle.paperSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.66), lineWidth: 0.8)
        }
    }

    private var emotionComposition: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("情绪构成")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.mutedInk)

            ForEach(analysis.topEmotionWeights) { weight in
                HStack(spacing: 10) {
                    Text(weight.anchor.title)
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 44, alignment: .leading)
                    GeometryReader { proxy in
                        Capsule()
                            .fill(signature.palette.secondary.opacity(0.18))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(signature.palette.primary.opacity(0.74))
                                    .frame(width: proxy.size.width * weight.value)
                            }
                    }
                    .frame(height: 7)
                    Text(weight.value, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(DayGlyphStyle.mutedInk)
                        .frame(width: 34, alignment: .trailing)
                }
            }
        }
    }

    private var vadSummary: some View {
        HStack(spacing: 8) {
            metric(title: "愉悦度", value: analysis.valence, signed: true)
            metric(title: "唤醒度", value: analysis.arousal)
            metric(title: "掌控感", value: analysis.dominance, signed: true)
        }
    }

    private var grammarSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("图形语法")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.mutedInk)

            Text(grammarDescription)
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.ink)
                .lineSpacing(4)
        }
    }

    private func metric(title: String, value: Double, signed: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(DayGlyphStyle.mutedInk)
            Text(signed ? String(format: "%+.2f", value) : String(format: "%.2f", value))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(DayGlyphStyle.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var grammarDescription: String {
        let boundary = signature.boundary.angularity > 0.45 ? "边界以尖锐折线表达张力" : "边界以柔和闭合表达稳定感"
        let trajectory = signature.trajectory.oscillation > 0.4 ? "轨迹的摆动反映内在不确定" : "轨迹保持连贯，呈现相对清晰的心理走向"
        let core = signature.core.isolation > 0.45 ? "核心与外层拉开距离，表达孤立感" : "核心靠近整体重心，表达自我与环境的连接"
        let rhythm = signature.rhythm.burst > 0.45 ? "外部节律向外释放能量" : "外部节律收敛并维持呼吸感"
        return "\(boundary)；\(trajectory)；\(core)；\(rhythm)。"
    }
}
