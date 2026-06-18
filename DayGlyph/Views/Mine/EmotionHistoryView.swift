import SwiftData
import SwiftUI

struct EmotionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]

    @State private var query = ""
    @State private var pendingDeletion: DayEntry?

    private var filtered: [DayEntry] {
        MineAggregator.filteredEntries(entries, query: query)
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView(
                    query.isEmpty ? "还没有情绪记录" : "没有匹配的记录",
                    systemImage: "magnifyingglass",
                    description: Text(query.isEmpty ? "记录后会按时间出现在这里。" : "试试更短的关键词。")
                )
                if !query.isEmpty {
                    Button("清除搜索") { query = "" }
                }
            } else {
                ForEach(filtered) { entry in
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(entry.emotionRecipe.name).font(.headline)
                                Spacer()
                                Text(entry.date, format: .dateTime.year().month().day())
                                    .font(.caption)
                                    .foregroundStyle(DayGlyphStyle.textSecondary)
                            }
                            Text(entry.moodWeather.explanation)
                                .font(.subheadline)
                                .foregroundStyle(DayGlyphStyle.textSecondary)
                                .lineLimit(2)
                            Text(entry.keywords.prefix(3).joined(separator: " · "))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(DayGlyphStyle.mine)
                        }
                        .padding(.vertical, 6)
                    }
                    .swipeActions {
                        Button("删除", role: .destructive) { pendingDeletion = entry }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "搜索文字、配方或关键词")
        .scrollContentBackground(.hidden)
        .background(DayGlyphBackground())
        .navigationTitle("情绪历史")
        .confirmationDialog("删除这条记录？", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        ), titleVisibility: .visible) {
            Button("删除记录", role: .destructive) { deletePendingEntry() }
            Button("取消", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("对应的宇宙日期落点也会消失。此操作无法恢复。")
        }
    }

    private func deletePendingEntry() {
        guard let entry = pendingDeletion else { return }
        modelContext.delete(entry)
        try? modelContext.save()
        pendingDeletion = nil
    }
}
