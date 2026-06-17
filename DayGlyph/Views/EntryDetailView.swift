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
                CocktailResultView(entry: entry, mode: .history)
                originalText
                deleteButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 112)
        }
        .background(DayGlyphBackground())
        .navigationTitle("记录详情")
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
