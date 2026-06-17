import SwiftUI

struct EmotionRecordView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var text: String
    var onSubmit: (String) -> Void

    @State private var showsDiscardConfirmation = false
    @FocusState private var isFocused: Bool

    private let limit = 500

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("今天发生了什么？可以只写一句")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(DayGlyphStyle.textPrimary)
                    Text("不用整理得很完整，留下真实的一点就够了。")
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("例如：今天把难处理的事说出口了，有点紧张，也松了一口气。")
                                .font(.body)
                                .foregroundStyle(DayGlyphStyle.textSecondary.opacity(0.72))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $text)
                            .focused($isFocused)
                            .frame(minHeight: 240)
                            .scrollContentBackground(.hidden)
                            .font(.body)
                            .lineSpacing(6)
                    }

                    HStack {
                        Label("仅在设备上生成情绪配方", systemImage: "lock")
                            .font(.caption)
                            .foregroundStyle(DayGlyphStyle.textSecondary)
                        Spacer()
                        Text("\(text.count)/\(limit)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(text.count >= limit ? DayGlyphStyle.danger : DayGlyphStyle.textSecondary)
                    }
                }
                .padding(18)
                .paperCard(cornerRadius: DayGlyphStyle.largeRadius)

                Button(action: submit) {
                    Label("调制今日情绪", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                }
                .buttonStyle(.glassProminent)
                .tint(DayGlyphStyle.today)
                .disabled(trimmedText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
        .background(DayGlyphBackground())
        .navigationTitle("今日记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消", action: cancel)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    isFocused = false
                }
                .font(.headline)
            }
        }
        .confirmationDialog(
            "保留这段草稿？",
            isPresented: $showsDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("继续编辑", role: .cancel) {}
            Button("放弃草稿", role: .destructive) {
                text = ""
                dismiss()
            }
        } message: {
            Text("本阶段草稿只会暂存在当前页面。")
        }
        .onAppear {
            isFocused = true
        }
        .onChange(of: text) { _, newValue in
            if newValue.count > limit {
                text = String(newValue.prefix(limit))
            }
        }
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submit() {
        guard trimmedText.isEmpty == false else { return }
        isFocused = false
        onSubmit(trimmedText)
    }

    private func cancel() {
        if trimmedText.isEmpty {
            dismiss()
        } else {
            showsDiscardConfirmation = true
        }
    }
}

#Preview {
    NavigationStack {
        EmotionRecordView(text: .constant("")) { _ in }
    }
}
