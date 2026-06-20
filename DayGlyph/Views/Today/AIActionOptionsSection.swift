import SwiftData
import SwiftUI

/// 三档微行动选择区（contextual personalization spec 5.3）。
///
/// 展示 light / standard / active 三档当日专属行动；用户选择后把
/// 标题、指令、原因、档位、时长与回声问题作为快照写入 `ActionInstance`，
/// 之后不再调用 AI，从而保证回声问题与实际选择一致、离线可用（spec 5.3、§9）。
struct AIActionOptionsSection: View {
    @Environment(\.modelContext) private var modelContext

    var options: [ActionOptionSpec]
    var entryID: UUID?

    @Query(sort: \ActionInstance.createdAt, order: .reverse) private var instances: [ActionInstance]

    private var calendar: Calendar { .current }

    private var todayInstance: ActionInstance? {
        instances.first { calendar.isDate($0.createdAt, inSameDayAs: .now) && $0.state != .cancelled }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let todayInstance {
                chosenState(todayInstance)
            } else {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    Button {
                        select(option)
                    } label: {
                        optionCard(option)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("选择这档行动")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("今天迈一小步", systemImage: "figure.walk")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text("三档轻重不同的小动作，只选一个此刻做得到的。任何一档都可以跳过。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineSpacing(3)
        }
    }

    private func optionCard(_ option: ActionOptionSpec) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(levelTitle(option.level))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DayGlyphStyle.today)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DayGlyphStyle.todaySoft, in: Capsule())
                Text(option.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
            }

            Text(option.instruction)
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Label("\(option.durationMinutes) 分钟", systemImage: "clock")
                if !option.environment.isEmpty {
                    Label(option.environment.prefix(2).joined(separator: " · "), systemImage: "mappin.and.ellipse")
                }
            }
            .font(.caption)
            .foregroundStyle(DayGlyphStyle.today)

            if !option.reason.isEmpty {
                Text(option.reason)
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DayGlyphStyle.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).stroke(DayGlyphStyle.divider, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func chosenState(_ instance: ActionInstance) -> some View {
        switch instance.state {
        case .skipped:
            Label("今天先留一点空白", systemImage: "moon.zzz")
                .font(.title3.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text("不做也可以。这里不会记录连续天数或未完成次数。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
        default:
            VStack(alignment: .leading, spacing: 8) {
                Label(instance.actionTitle, systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(DayGlyphStyle.today)
                if !instance.actionInstruction.isEmpty {
                    Text(instance.actionInstruction)
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.textPrimary)
                        .lineSpacing(3)
                }
                Text("已经选好这一步。到了合适的时候，回声里会问你那个专属问题。")
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func levelTitle(_ level: String) -> String {
        ActionOptionLevel(rawValue: level.lowercased())?.title ?? "行动"
    }

    private func select(_ option: ActionOptionSpec) {
        let instance = ActionInstance(
            actionId: "ai-\(option.level.lowercased())",
            entryId: entryID,
            actionTitle: option.title,
            category: nil,
            startedAt: .now,
            state: .started,
            actionInstruction: option.instruction,
            actionReason: option.reason,
            actionLevel: ActionOptionLevel(rawValue: option.level.lowercased()),
            echoQuestion: option.echoQuestion,
            durationMinutes: option.durationMinutes
        )
        modelContext.insert(instance)
        try? modelContext.save()
    }
}
