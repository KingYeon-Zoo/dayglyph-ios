import SwiftData
import SwiftUI

struct MicroActionSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActionInstance.createdAt, order: .reverse) private var instances: [ActionInstance]

    var entry: DayEntry?

    @State private var candidates: [MicroAction] = []

    private var calendar: Calendar { .current }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader

            if let todayInstance {
                instanceState(todayInstance)
            } else {
                candidateList
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
        .task(id: recommendationKey) {
            loadCandidates()
        }
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("今天迈一小步", systemImage: "figure.walk")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)

            Text("不需要完成很多，只选一个此刻做得到的小动作。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineSpacing(3)
        }
    }

    private var candidateList: some View {
        VStack(spacing: 12) {
            ForEach(candidates) { action in
                Button {
                    start(action)
                } label: {
                    actionCard(action)
                }
                .buttonStyle(.plain)
                .accessibilityHint("开始这项行动")
            }

            VStack(spacing: 8) {
                easierButton
                skipButton
            }
        }
    }

    private func actionCard(_ action: MicroAction) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol(for: action.category))
                .font(.title3.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.today)
                .frame(width: 42, height: 42)
                .background(DayGlyphStyle.todaySoft, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 7) {
                Text(action.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("约 \(action.estimatedMinutes) 分钟 · \(action.difficultyBand.title)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(DayGlyphStyle.today)

                Text(action.constraints.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "play.circle.fill")
                .font(.title3)
                .foregroundStyle(DayGlyphStyle.today)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(16)
        .background(DayGlyphStyle.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(DayGlyphStyle.divider, lineWidth: 1)
        }
    }

    private func instanceState(_ instance: ActionInstance) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            switch instance.state {
            case .started:
                if let action = MicroActionCatalog.all.first(where: { $0.id == instance.actionId }) {
                    actionCard(action)
                    Text("已经开始。按自己的节奏来，随时可以停下。")
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.textSecondary)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) { completeButton(instance); cancelButton(instance) }
                        VStack(spacing: 8) { completeButton(instance); cancelButton(instance) }
                    }
                }
            case .completed:
                Label("这一步已经完成", systemImage: "checkmark.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.today)
                Text("先把这次行动留在这里，不需要立刻判断它带来了什么。")
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            case .skipped:
                Label("今天先留一点空白", systemImage: "moon.zzz")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                Text("不做也可以。这里不会记录连续天数或未完成次数。")
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            case .cancelled:
                candidateList
            }
        }
    }

    private var easierButton: some View {
        Button(action: replaceFirstCandidate) {
            Label("换成更容易的", systemImage: "arrow.triangle.2.circlepath")
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glass)
        .disabled(candidates.isEmpty)
    }

    private var skipButton: some View {
        Button(action: skipToday) {
            Text("今天先不做")
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(DayGlyphStyle.textSecondary)
    }

    private func completeButton(_ instance: ActionInstance) -> some View {
        Button {
            instance.complete()
            try? modelContext.save()
        } label: {
            Label("完成了", systemImage: "checkmark")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glassProminent)
        .tint(DayGlyphStyle.today)
    }

    private func cancelButton(_ instance: ActionInstance) -> some View {
        Button {
            instance.cancel()
            try? modelContext.save()
        } label: {
            Text("先停下")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glass)
    }

    private var todayInstance: ActionInstance? {
        instances.first { calendar.isDate($0.createdAt, inSameDayAs: .now) && $0.state != .cancelled }
    }

    private var recommendationKey: String {
        "\(entry?.entryID.uuidString ?? "empty")-\(calendar.component(.day, from: .now))"
    }

    private func loadCandidates() {
        candidates = MicroActionCatalog.recommendations(
            for: entry?.emotionRecipe.primary,
            disabledCategories: [],
            seed: entry?.planetVisual.seed ?? calendar.ordinality(of: .day, in: .era, for: .now) ?? 0
        )
    }

    private func replaceFirstCandidate() {
        guard let current = candidates.first,
              let replacement = MicroActionCatalog.easierReplacement(
                for: current,
                anchor: entry?.emotionRecipe.primary,
                excluding: Set(candidates.map(\.id)),
                disabledCategories: [],
                seed: entry?.planetVisual.seed ?? 0
              ) else { return }
        candidates[0] = replacement
    }

    private func start(_ action: MicroAction) {
        let instance = ActionInstance(
            actionId: action.id,
            entryId: entry?.entryID,
            startedAt: .now,
            state: .started
        )
        modelContext.insert(instance)
        try? modelContext.save()
    }

    private func skipToday() {
        let instance = ActionInstance(
            actionId: "skip-today",
            entryId: entry?.entryID,
            startedAt: nil,
            state: .skipped
        )
        modelContext.insert(instance)
        try? modelContext.save()
    }

    private func symbol(for category: MicroActionCategory) -> String {
        switch category {
        case .breathing: "wind"
        case .movement: "figure.cooldown"
        case .sensory: "hand.raised"
        case .rest: "cup.and.saucer"
        case .writing: "pencil.line"
        case .social: "message"
        case .outdoors: "leaf"
        }
    }
}
