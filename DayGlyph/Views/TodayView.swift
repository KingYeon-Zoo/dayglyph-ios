import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]

    @State private var entryText = ""
    @State private var latestEntry: DayEntry?
    @State private var saveMessage = ""
    @State private var isAnalyzing = false
    @State private var errorMessage = ""
    @FocusState private var isEditorFocused: Bool

    private let analyzer = UnifiedEmotionAnalyzer()
    private let softLimit = 280

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                editor
                generateButton
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let latestEntry {
                    resultCard(for: latestEntry)
                }
            }
            .padding(22)
            .padding(.bottom, 96)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(DayGlyphStyle.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    isEditorFocused = false
                }
                .font(.headline)
            }
        }
        .onAppear(perform: loadToday)
        .onChange(of: entries.count) {
            loadToday()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("一划")
                    .font(.title2.weight(.bold))
                Spacer()
                Text(.now, format: .dateTime.month().day().weekday())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.mutedInk)
            }

            Text("今天留下些什么？")
                .font(.system(size: 38, weight: .bold, design: .serif))
                .foregroundStyle(DayGlyphStyle.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("一句话也可以，一小段也很好。")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.mutedInk)

            TextEditor(text: $entryText)
                .focused($isEditorFocused)
                .frame(minHeight: 132)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.7), lineWidth: 1)
                )

            HStack {
                Text("\(entryText.count)/\(softLimit)")
                Spacer()
                if entryText.count > softLimit {
                    Text("可以更轻一点")
                }
            }
            .font(.footnote)
            .foregroundStyle(entryText.count > softLimit ? .orange : DayGlyphStyle.mutedInk)
        }
    }

    private var generateButton: some View {
        Button(action: generateTodayGlyph) {
            Label(isAnalyzing ? "正在理解今天" : "生成今日一划", systemImage: "wand.and.sparkles")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .tint(DayGlyphStyle.ink)
        .disabled(isAnalyzing || entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func resultCard(for entry: DayEntry) -> some View {
        let signature = signature(for: entry)

        return VStack(spacing: 12) {
            GlyphCanvasView(signature: signature, lineWidth: 5)
                .frame(maxWidth: 178)
                .padding(.top, 6)

            VStack(spacing: 10) {
                Text("已保存为今天的一划")
                    .font(.headline)
                    .foregroundStyle(DayGlyphStyle.ink)

                HStack {
                    CapsuleLabel(text: entry.emotion.title, color: signature.primaryColor)
                    CapsuleLabel(text: entry.theme.title, color: signature.secondaryColor)
                    CapsuleLabel(text: "\(Int(entry.energy * 100))%", color: .white)
                }

                Text(entry.explanation)
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.mutedInk)
                    .multilineTextAlignment(.center)

                Text(entry.analysisSource.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.mutedInk)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 24))
    }

    private func loadToday() {
        if let today = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: .now) }) {
            latestEntry = today
            if entryText.isEmpty {
                entryText = today.text
            }
        }
    }

    private func generateTodayGlyph() {
        let trimmed = entryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isEditorFocused = false
        isAnalyzing = true
        errorMessage = ""

        Task {
            let analysis = await analyzer.analyze(trimmed)
            do {
                let entry = try DayEntryStore.saveEntry(
                    text: trimmed,
                    analysis: analysis,
                    context: modelContext
                )
                latestEntry = entry
                saveMessage = "已保存为今天的一划"
                isAnalyzing = false
            } catch {
                errorMessage = error.localizedDescription
                isAnalyzing = false
            }
        }
    }

    private func signature(for entry: DayEntry) -> GlyphSignature {
        GlyphSignature(
            analysis: EmotionAnalysis(
                emotion: entry.emotion,
                theme: entry.theme,
                energy: entry.energy,
                keywords: entry.keywords,
                confidence: entry.confidence,
                explanation: entry.explanation,
                source: entry.analysisSource
            ),
            seed: entry.glyphSeed
        )
    }
}

#Preview {
    TodayView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
