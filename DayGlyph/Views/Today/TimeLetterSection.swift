import SwiftData
import SwiftUI

struct TimeLetterSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeLetter.notBefore) private var letters: [TimeLetter]
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]

    @AppStorage("letterRemindersEnabled") private var letterRemindersEnabled = false
    @StateObject private var reminderService = ReminderService()

    var entry: DayEntry?

    @State private var showsComposer = false
    @State private var draft = ""
    @State private var delayDays = 30
    @State private var savedMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("时间来信", systemImage: "envelope")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)

            if let letter = TimeLetterStore.dueLetter(from: letters) {
                dueLetterCard(letter)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
        .sheet(isPresented: $showsComposer) {
            composer
        }
        .task { seedPastLetterIfNeeded() }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let savedMessage {
                Label(savedMessage, systemImage: "checkmark.seal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.mine)
            } else {
                Text("把一句话留给未来。它最早会在 7 天后，安静地回到这里。")
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .lineSpacing(4)
            }

            Button {
                showsComposer = true
            } label: {
                Label("写给未来", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glass)
        }
    }

    private func dueLetterCard(_ letter: TimeLetter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(letter.sourceType.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.mine)

            Text(letter.createdAt, format: .dateTime.year().month().day())
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)

            Text(letter.body)
                .font(.body)
                .foregroundStyle(DayGlyphStyle.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            if let recipeSummary = letter.recipeSummary {
                Label(recipeSummary, systemImage: "wineglass")
                    .font(.caption)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            }

            VStack(spacing: 8) {
                Button {
                    draft = ""
                    showsComposer = true
                } label: {
                    Text("写写现在")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glassProminent)
                .tint(DayGlyphStyle.mine)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { keepButton(letter); hideButton(letter) }
                    VStack(spacing: 8) { keepButton(letter); hideButton(letter) }
                }
            }
        }
    }

    private func keepButton(_ letter: TimeLetter) -> some View {
        Button {
            letter.keep()
            try? modelContext.save()
        } label: {
            Text("先收下")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glass)
    }

    private func hideButton(_ letter: TimeLetter) -> some View {
        Button {
            letter.hideForToday()
            try? modelContext.save()
        } label: {
            Text("今天先不看")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(DayGlyphStyle.textSecondary)
    }

    private var composer: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("想留给未来什么？")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(DayGlyphStyle.textPrimary)
                        Text("不会显示准确触达日期，也不会作为提醒催促你。")
                            .font(.subheadline)
                            .foregroundStyle(DayGlyphStyle.textSecondary)
                    }

                    TextEditor(text: $draft)
                        .frame(minHeight: 220)
                        .padding(12)
                        .background(DayGlyphStyle.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(DayGlyphStyle.divider, lineWidth: 1)
                        }
                        .onChange(of: draft) { _, value in
                            if value.count > 500 { draft = String(value.prefix(500)) }
                        }

                    Text("\(draft.count)/500")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("大约多久以后")
                            .font(.headline)
                        Picker("大约多久以后", selection: $delayDays) {
                            Text("7 天后").tag(7)
                            Text("30 天后").tag(30)
                            Text("90 天后").tag(90)
                        }
                        .pickerStyle(.segmented)
                    }

                    Button(action: saveFutureLetter) {
                        Label("把信收好", systemImage: "envelope.badge")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(DayGlyphStyle.mine)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(20)
            }
            .background(DayGlyphBackground())
            .navigationTitle("写给未来")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showsComposer = false }
                }
            }
        }
    }

    private func saveFutureLetter() {
        let summary = entry.map { "当时的配方：\($0.emotionRecipe.name)" }
        guard let letter = try? TimeLetterStore.makeFuture(
            body: draft,
            delayDays: delayDays,
            sourceEntryId: entry?.entryID,
            recipeSummary: summary
        ) else { return }
        modelContext.insert(letter)
        try? modelContext.save()
        if letterRemindersEnabled {
            Task {
                await reminderService.scheduleTimeLetter(id: letter.id, date: letter.notBefore)
            }
        }
        draft = ""
        showsComposer = false
        savedMessage = "已经收好，会在未来某天出现"
    }

    private func seedPastLetterIfNeeded() {
        let calendar = Calendar.current
        guard letters.contains(where: { $0.sourceType == .past && calendar.isDate($0.createdAt, inSameDayAs: .now) }) == false,
              let cutoff = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: .now)),
              let historical = entries.first(where: { candidate in
                  candidate.date <= cutoff
                      && letters.contains(where: { $0.sourceEntryId == candidate.entryID }) == false
              }) else { return }

        modelContext.insert(TimeLetterStore.makePast(from: historical))
        try? modelContext.save()
    }
}
