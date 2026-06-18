import SwiftData
import SwiftUI

struct ActionResponseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var action: ActionInstance

    @State private var selection: ActionResponseKind?
    @State private var note = ""
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(action.actionTitle)
                        .font(.headline)
                    if let completedAt = action.completedAt {
                        Text(completedAt, format: .dateTime.month().day().hour().minute())
                            .font(.subheadline)
                            .foregroundStyle(DayGlyphStyle.textSecondary)
                    }
                } header: {
                    Text("这次行动")
                }

                Section("后来感受如何") {
                    ForEach(ActionResponseKind.allCases) { kind in
                        Button {
                            selection = kind
                        } label: {
                            HStack {
                                Text(kind.title)
                                    .foregroundStyle(DayGlyphStyle.textPrimary)
                                Spacer()
                                Image(systemName: selection == kind ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selection == kind ? DayGlyphStyle.echo : DayGlyphStyle.textSecondary)
                            }
                        }
                        .accessibilityAddTraits(selection == kind ? .isSelected : [])
                    }
                }

                Section("可选备注") {
                    TextField("留下一句话，也可以空着", text: $note, axis: .vertical)
                        .lineLimit(3 ... 6)
                }

                Section {
                    Button("不记录感受") { save(kind: nil) }
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                }
            }
            .navigationTitle("记录行动回声")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save(kind: selection) }
                        .disabled(selection == nil)
                }
            }
            .alert("暂时无法保存", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(saveError ?? "请稍后再试。")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save(kind: ActionResponseKind?) {
        modelContext.insert(ActionResponse(
            actionInstanceId: action.id,
            kind: kind,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = "内容仍保留在页面中，请再次保存。"
        }
    }
}
