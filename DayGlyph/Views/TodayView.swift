import SwiftData
import SwiftUI
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]

    @State private var entryText = ""
    @State private var latestEntry: DayEntry?
    @State private var isEditing = true
    @State private var isAnalyzing = false
    @State private var errorMessage = ""
    @State private var revealProgress = 1.0
    @FocusState private var isEditorFocused: Bool

    private let analyzer = UnifiedEmotionAnalyzer()
    private let appleIntelligenceStatus = AppleIntelligenceStatus.current
    private let softLimit = 280

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                Group {
                    if let latestEntry, !isEditing {
                        result(for: latestEntry)
                            .transition(.blurReplace.combined(with: .opacity))
                    } else {
                        editor
                            .transition(.blurReplace.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.62, dampingFraction: 0.86), value: isEditing)

                if !errorMessage.isEmpty {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 112)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(DayGlyphBackground())
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Label("DAYGLYPH", systemImage: "scribble.variable")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(DayGlyphStyle.jade)

                Spacer()

                Text(.now, format: .dateTime.month().day().weekday())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.mutedInk)
            }

            Text(isEditing ? "今天留下些什么？" : "今日情绪鸡尾酒")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(DayGlyphStyle.ink)
                .contentTransition(.numericText())

            Text(isEditing ? "写下真实感受，模型会把情绪结构转译成今日配方。" : "颜色表达情绪气候，结构记录它如何发生。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.mutedInk)
                .lineSpacing(3)
        }
    }

    private var editor: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("今日记录")
                        .font(.headline)
                    Spacer()
                    modelStatusPill
                }

                ZStack(alignment: .topLeading) {
                    if entryText.isEmpty {
                        Text("一句话也可以。比如：会议结束后松了一口气，但仍有一点不安。")
                            .font(.body)
                            .foregroundStyle(DayGlyphStyle.mutedInk.opacity(0.7))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $entryText)
                        .focused($isEditorFocused)
                        .frame(minHeight: 164)
                        .scrollContentBackground(.hidden)
                        .font(.body)
                        .lineSpacing(5)
                }

                HStack {
                    Text("文字仅在设备上分析")
                        .font(.caption)
                        .foregroundStyle(DayGlyphStyle.mutedInk)
                    Spacer()
                    Text("\(entryText.count)/\(softLimit)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(entryText.count > softLimit ? .orange : DayGlyphStyle.mutedInk)
                }
            }
            .padding(18)
            .paperCard(cornerRadius: DayGlyphStyle.largeRadius)

            generateButton
        }
    }

    private var modelStatusPill: some View {
        HStack(spacing: 6) {
            Image(systemName: appleIntelligenceStatus.symbolName)
            Text(appleIntelligenceStatus.canUseFoundationModels ? "结构化理解" : "暂不可用")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(appleIntelligenceStatus.canUseFoundationModels ? DayGlyphStyle.jade : .orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassEffect(
            .regular.tint((appleIntelligenceStatus.canUseFoundationModels ? DayGlyphStyle.jade : Color.orange).opacity(0.09)),
            in: .capsule
        )
    }

    private var generateButton: some View {
        Button(action: generateTodayMood) {
            HStack(spacing: 10) {
                if isAnalyzing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "wand.and.sparkles")
                }
                Text(isAnalyzing ? "正在理解情绪结构" : "调制今日情绪")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.glassProminent)
        .tint(DayGlyphStyle.ink)
        .controlSize(.large)
        .disabled(isAnalyzing || entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityHint("使用设备端模型分析文字并生成情绪配方")
    }

    private func result(for entry: DayEntry) -> some View {
        let signature = GlyphSignature(analysis: entry.analysis, seed: entry.glyphSeed)

        return VStack(spacing: 20) {
            GlyphCanvasView(
                signature: signature,
                lineWidth: 5,
                mode: .hero,
                revealProgress: revealProgress
            )
            .frame(maxWidth: 262)
            .padding(.top, 2)

            VStack(spacing: 12) {
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

                Text("\(entry.theme.title) · \(entry.analysisSource.title)")
                    .font(.caption)
                    .foregroundStyle(DayGlyphStyle.mutedInk)
            }

            GlyphExplanationView(analysis: entry.analysis, signature: signature)

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        isEditing = true
                        errorMessage = ""
                        isEditorFocused = true
                    } label: {
                        Label("编辑文字", systemImage: "square.and.pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)

                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        Label("查看详情", systemImage: "arrow.up.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(DayGlyphStyle.jade)
                }
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(18)
        .paperCard(cornerRadius: 34)
    }

    private func loadToday() {
        guard let today = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: .now) }) else {
            isEditing = true
            return
        }
        latestEntry = today
        entryText = today.text
        isEditing = false
        revealProgress = 1
    }

    private func generateTodayMood() {
        let trimmed = entryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isEditorFocused = false
        isAnalyzing = true
        errorMessage = ""

        Task {
            do {
                let analysis = try await analyzer.analyze(trimmed)
                let entry = try DayEntryStore.saveEntry(
                    text: trimmed,
                    analysis: analysis,
                    context: modelContext
                )
                latestEntry = entry
                revealProgress = reduceMotion ? 1 : 0
                withAnimation(.spring(response: 0.65, dampingFraction: 0.88)) {
                    isEditing = false
                }
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 1.25)) {
                        revealProgress = 1
                    }
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                errorMessage = error.localizedDescription
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            isAnalyzing = false
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
