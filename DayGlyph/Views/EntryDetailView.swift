import SwiftData
import SwiftUI

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var entry: DayEntry

    @State private var showsDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                hero
                GlyphExplanationView(analysis: entry.analysis, signature: signature)
                originalText
                deleteButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 112)
        }
        .background(DayGlyphBackground())
        .navigationTitle("一划详情")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "删除这一天？",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除记录", role: .destructive, action: deleteEntry)
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复。")
        }
    }

    private var signature: GlyphSignature {
        GlyphSignature(analysis: entry.analysis, seed: entry.glyphSeed)
    }

    private var hero: some View {
        VStack(spacing: 18) {
            GlyphCanvasView(
                signature: signature,
                lineWidth: 5.5,
                mode: .detail
            )
            .frame(maxWidth: 286)

            VStack(spacing: 10) {
                Text(entry.date, format: .dateTime.year().month().day().weekday())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.mutedInk)

                Text(entry.primaryEmotion.title)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(DayGlyphStyle.ink)

                HStack(spacing: 7) {
                    ForEach(entry.analysis.topEmotionWeights) { weight in
                        CapsuleLabel(
                            text: "\(weight.anchor.title) \(Int(weight.value * 100))%",
                            color: signature.palette.primary
                        )
                    }
                }

                Text(entry.explanation)
                    .font(.body.weight(.medium))
                    .foregroundStyle(DayGlyphStyle.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("\(entry.theme.title) · \(entry.analysisSource.title) · 置信度 \(Int(entry.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(DayGlyphStyle.mutedInk)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .paperCard(cornerRadius: 34)
    }

    private var originalText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("那天写下的文字", systemImage: "text.quote")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.ink)

            Text(entry.text)
                .font(.body)
                .foregroundStyle(DayGlyphStyle.ink)
                .lineSpacing(7)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !entry.keywords.isEmpty {
                Text(entry.keywords.joined(separator: "  ·  "))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.mutedInk)
            }
        }
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showsDeleteConfirmation = true
        } label: {
            Label("删除这一天", systemImage: "trash")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .tint(.red.opacity(0.82))
    }

    private func deleteEntry() {
        modelContext.delete(entry)
        try? modelContext.save()
        dismiss()
    }
}
