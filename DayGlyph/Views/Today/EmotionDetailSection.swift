import SwiftUI

/// 丰富情绪展示（spec 5.1、第 11 节）。
///
/// 完整展示 1～8 个情绪词，不截断为前三项。点击词语查看强度、置信度和识别依据。
/// 默认解释保持简短，详细依据按需展开。
struct EmotionDetailSection: View {
    var payload: EmotionAnalysisPayload

    @State private var expandedTerm: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("今天的情绪")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)

            // 完整情绪词，可点击展开。
            FlowLayout(spacing: 8) {
                ForEach(payload.emotions, id: \.term) { item in
                    emotionChip(item)
                }
            }

            if let expandedTerm, let item = payload.emotions.first(where: { $0.term == expandedTerm }) {
                detailCard(item)
            }

            if !payload.summary.isEmpty {
                Text(payload.summary)
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .lineSpacing(4)
                    .padding(.top, 2)
            }
        }
        .padding(18)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private func emotionChip(_ item: EmotionItem) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedTerm = (expandedTerm == item.term) ? nil : item.term
            }
        } label: {
            HStack(spacing: 6) {
                Text(item.term)
                    .font(.subheadline.weight(.medium))
                Circle()
                    .fill(DayGlyphStyle.today.opacity(0.3 + 0.7 * item.intensity))
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(expandedTerm == item.term ? DayGlyphStyle.todaySoft : DayGlyphStyle.divider.opacity(0.5))
            )
            .foregroundStyle(DayGlyphStyle.textPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.term)，强度\(Int(item.intensity * 100))%，点击查看依据")
    }

    private func detailCard(_ item: EmotionItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("强度 \(Int(item.intensity * 100))%", systemImage: "waveform")
                Spacer()
                Label("把握 \(Int(item.confidence * 100))%", systemImage: "checkmark.seal")
            }
            .font(.caption)
            .foregroundStyle(DayGlyphStyle.textSecondary)

            if !item.evidence.isEmpty {
                Text("依据：\(item.evidence)")
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                    .lineSpacing(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DayGlyphStyle.todaySoft.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// 简单流式布局，用于情绪词换行排布。
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var currentRowWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(size)
            currentRowWidth += size.width + spacing
        }
        let height = rows.reduce(0) { acc, row in
            acc + (row.map(\.height).max() ?? 0) + spacing
        } - spacing
        return CGSize(width: maxWidth == .infinity ? currentRowWidth : maxWidth, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
