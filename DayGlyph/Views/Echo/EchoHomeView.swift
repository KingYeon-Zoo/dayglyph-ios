import SwiftData
import SwiftUI

struct EchoHomeView: View {
    @Query(sort: \ActionInstance.createdAt, order: .reverse) private var actions: [ActionInstance]
    @Query(sort: \ActionResponse.createdAt, order: .reverse) private var responses: [ActionResponse]

    @State private var selectedAction: ActionInstance?

    private var due: [ActionInstance] {
        EchoAggregator.dueActions(from: actions, responses: responses)
    }

    private var pending: [ActionInstance] {
        EchoAggregator.pendingActions(from: actions, responses: responses)
    }

    private var insights: [EchoInsight] {
        EchoAggregator.insights(from: actions, responses: responses)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                if due.isEmpty && pending.isEmpty && responses.isEmpty {
                    emptyState
                } else {
                    summaryCard
                    if !due.isEmpty { actionSection("可以回应", actions: due, isDue: true) }
                    if !pending.isEmpty { actionSection("稍后看看", actions: pending, isDue: false) }
                    if !responses.isEmpty { recentResponses }
                    if !insights.isEmpty { insightLink }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
        .background(DayGlyphBackground())
        .navigationTitle("回声")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedAction) { action in
            ActionResponseSheet(action: action)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("回声")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text("做过什么，以及后来感受如何。")
                .foregroundStyle(DayGlyphStyle.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(DayGlyphStyle.echo)
            Text("完成一个小行动后，这里会留下回声")
                .font(.title2.weight(.semibold))
            Text("不用立刻判断是否变好。到了合适的时候，再回来记录真实感受。")
                .foregroundStyle(DayGlyphStyle.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .paperCard(cornerRadius: DayGlyphStyle.heroRadius)
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            Image(systemName: due.isEmpty ? "clock" : "bell.badge")
                .font(.title2)
                .foregroundStyle(DayGlyphStyle.echo)
                .frame(width: 48, height: 48)
                .background(DayGlyphStyle.echoSoft, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(due.isEmpty ? "没有等待回应的行动" : "有 \(due.count) 项可以回应")
                    .font(.headline)
                Text("任何结果都是正常记录")
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .paperCard()
    }

    private func actionSection(_ title: String, actions: [ActionInstance], isDue: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            ForEach(actions) { action in
                Button {
                    if isDue { selectedAction = action }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isDue ? "exclamationmark.bubble.fill" : "clock.fill")
                            .foregroundStyle(DayGlyphStyle.echo)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.actionTitle).font(.body.weight(.semibold))
                            Text(isDue ? "已到回应时间" : "将在 \((action.followUpAt ?? .now).formatted(date: .omitted, time: .shortened)) 提醒")
                                .font(.caption)
                                .foregroundStyle(DayGlyphStyle.textSecondary)
                        }
                        Spacer()
                        if isDue { Image(systemName: "chevron.right") }
                    }
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                    .padding(16)
                    .background(DayGlyphStyle.surface.opacity(0.78), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(!isDue)
            }
        }
    }

    private var recentResponses: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近回声").font(.headline)
            ForEach(responses.prefix(5)) { response in
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(DayGlyphStyle.echo)
                    Text(response.kind?.title ?? "没有记录感受")
                    Spacer()
                    Text(response.createdAt, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                }
                .padding(16)
                .paperCard(cornerRadius: 16)
            }
        }
    }

    private var insightLink: some View {
        NavigationLink {
            EchoInsightsView(insights: insights)
        } label: {
            HStack {
                Label("我的发现", systemImage: "sparkles")
                Spacer()
                Text("\(insights.count)")
                Image(systemName: "chevron.right")
            }
            .font(.headline)
            .foregroundStyle(DayGlyphStyle.echo)
            .padding(20)
            .paperCard()
        }
        .buttonStyle(.plain)
    }
}
