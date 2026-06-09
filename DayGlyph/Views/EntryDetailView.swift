import SwiftData
import SwiftUI

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var entry: DayEntry

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                GlyphCanvasView(signature: signature, lineWidth: 5)
                    .frame(maxWidth: 260)
                    .padding(.top, 20)

                VStack(spacing: 10) {
                    Text(entry.date, format: .dateTime.year().month().day())
                        .font(.headline)
                    HStack {
                        CapsuleLabel(text: entry.emotion.title, color: signature.primaryColor)
                        CapsuleLabel(text: entry.theme.title, color: signature.secondaryColor)
                        CapsuleLabel(text: "\(Int(entry.energy * 100))%", color: .white)
                    }
                }

                Text(entry.text)
                    .font(.body)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))

                Button(role: .destructive) {
                    modelContext.delete(entry)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Label("删除这一天", systemImage: "trash")
                }
            }
            .padding(22)
            .padding(.bottom, 96)
        }
        .background(DayGlyphStyle.background.ignoresSafeArea())
        .navigationTitle("一划详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var signature: GlyphSignature {
        GlyphSignature(
            analysis: EmotionAnalysis(emotion: entry.emotion, theme: entry.theme, energy: entry.energy, keywords: entry.keywords),
            seed: entry.glyphSeed
        )
    }
}
