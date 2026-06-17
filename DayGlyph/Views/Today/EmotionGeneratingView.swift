import SwiftData
import SwiftUI

struct EmotionGeneratingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    var text: String
    var onComplete: (DayEntry) -> Void

    @State private var phaseIndex = 0
    @State private var errorMessage = ""
    @State private var hasStarted = false

    private let phases = ["理解文字", "调制颜色", "凝结星球"]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DayGlyphStyle.todaySoft)
                    .frame(width: 184, height: 184)

                Circle()
                    .stroke(DayGlyphStyle.today.opacity(0.24), lineWidth: 12)
                    .frame(width: reduceMotion ? 124 : 142, height: reduceMotion ? 124 : 142)
                    .scaleEffect(reduceMotion ? 1 : 1.05)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: hasStarted)

                Image(systemName: "wineglass")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(DayGlyphStyle.today)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(phases[phaseIndex])
                    .font(.title.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                    .contentTransition(.opacity)

                Text("正在把今天的文字调成一份温和的情绪配方。")
                    .font(.body)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            HStack(spacing: 10) {
                ForEach(phases.indices, id: \.self) { index in
                    Circle()
                        .fill(index <= phaseIndex ? DayGlyphStyle.today : DayGlyphStyle.divider)
                        .frame(width: 9, height: 9)
                }
            }
            .accessibilityLabel(phases[phaseIndex])

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.danger)
                    .multilineTextAlignment(.center)

                Button("返回修改") {
                    dismiss()
                }
                .buttonStyle(.glass)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .background(DayGlyphBackground())
        .navigationTitle("正在调制")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard hasStarted == false else { return }
            hasStarted = true
            await run()
        }
    }

    private func run() async {
        do {
            for index in phases.indices {
                phaseIndex = index
                if reduceMotion == false {
                    try await Task.sleep(for: .milliseconds(520))
                }
            }

            let analysis = try await analyze(text)
            let entry = try DayEntryStore.saveEntry(
                text: text,
                analysis: analysis,
                context: modelContext
            )
            onComplete(entry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func analyze(_ text: String) async throws -> EmotionAnalysis {
        do {
            return try await UnifiedEmotionAnalyzer().analyze(text)
        } catch let error as FoundationEmotionAnalyzerError {
            switch error {
            case .unavailable:
                return EmotionAnalyzer().analyze(text)
            case .invalidOutput:
                throw error
            }
        }
    }
}

#Preview {
    EmotionGeneratingView(text: "今天把重要的事情说出口了。") { _ in }
        .modelContainer(for: DayEntry.self, inMemory: true)
}
