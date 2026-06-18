import SwiftData
import SwiftUI

struct EmpathySeaSection: View {
    var entry: DayEntry?

    @State private var showsSea = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("共情海", systemImage: "water.waves")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)

            Text("看看一段匿名感受，或编辑一份独立副本放入海中。原始日记不会公开。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineSpacing(4)

            Button {
                showsSea = true
            } label: {
                Label("进入共情海", systemImage: "sailboat")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
        .sheet(isPresented: $showsSea) {
            EmpathySeaView(entry: entry)
        }
    }
}

private struct EmpathySeaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmpathyCopy.sentAt, order: .reverse) private var copies: [EmpathyCopy]

    var entry: DayEntry?

    @State private var postIndex = 0
    @AppStorage("empathySeaReportedIDs") private var reportedIDsBlob = ""
    @State private var chosenResponse: String?
    @State private var postPendingReport: EmpathySeaPost?

    private var post: EmpathySeaPost {
        EmpathySeaDemoCatalog.posts[postIndex % EmpathySeaDemoCatalog.posts.count]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    demoNotice

                    if let latestCopy = copies.first {
                        ownCopyStatus(latestCopy)
                    }

                    salvagedPost

                    NavigationLink {
                        EmpathyCopyEditor(entry: entry)
                    } label: {
                        Label("匿名放入一句话", systemImage: "square.and.pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(DayGlyphStyle.universe)
                }
                .padding(20)
                .padding(.bottom, 36)
            }
            .background(DayGlyphBackground())
            .navigationTitle("共情海")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .alert("确认举报这段内容？", isPresented: reportAlertBinding, presenting: postPendingReport) { selected in
            Button("举报", role: .destructive) {
                reportedIDsBlob = EmpathySeaDemoCatalog.addReported(
                    postID: selected.id,
                    to: reportedIDsBlob
                )
                postPendingReport = nil
            }
            Button("取消", role: .cancel) { postPendingReport = nil }
        } message: { _ in
            Text("本地演示会记录为已举报，不会发送网络请求。")
        }
        .task(id: reviewingCopy?.id) {
            guard let copy = reviewingCopy else { return }
            try? await Task.sleep(for: .seconds(1.2))
            EmpathyCopyStore.completeDemoReview(copy)
            try? modelContext.save()
        }
    }

    private var demoNotice: some View {
        Label("本地演示内容 · 不连接公开社区", systemImage: "iphone.and.arrow.forward")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(DayGlyphStyle.universe)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(DayGlyphStyle.mineSoft, in: Capsule())
    }

    private func ownCopyStatus(_ copy: EmpathyCopy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            switch copy.reviewState {
            case .reviewing:
                Label("匿名副本审核中", systemImage: "clock.badge.checkmark")
                    .font(.headline)
                    .foregroundStyle(DayGlyphStyle.universe)
                Text("演示审核会在本机完成，原始日记仍只保存在你的记录里。")
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            case .responded:
                Label("有人回应了你的那句话", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.headline)
                    .foregroundStyle(DayGlyphStyle.universe)
                if let response = copy.responseText {
                    Text(response)
                        .font(.body)
                        .foregroundStyle(DayGlyphStyle.textPrimary)
                        .lineSpacing(4)
                }
            default:
                Label("匿名副本已保存在本机", systemImage: "checkmark.seal")
                    .font(.headline)
                    .foregroundStyle(DayGlyphStyle.universe)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(DayGlyphStyle.mineSoft.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
    }

    private var salvagedPost: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今天打捞到")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DayGlyphStyle.universe)
                    Text(post.mood)
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                }
                Spacer()
                Button {
                    postIndex = (postIndex + 1) % EmpathySeaDemoCatalog.posts.count
                    chosenResponse = nil
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("打捞下一条")
            }

            Text(post.text)
                .font(.title3.weight(.medium))
                .foregroundStyle(DayGlyphStyle.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(post.responses, id: \.self) { response in
                    Button {
                        chosenResponse = response
                    } label: {
                        HStack {
                            Text(response)
                            Spacer()
                            if chosenResponse == response {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.glass)
                }
            }

            if let chosenResponse {
                Text("回应已留在本地演示中：\(chosenResponse)")
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            }

            Button {
                postPendingReport = post
            } label: {
                Label(
                    reportedIDs.contains(post.id) ? "已举报" : "举报这段内容",
                    systemImage: reportedIDs.contains(post.id) ? "checkmark.shield" : "exclamationmark.bubble"
                )
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(DayGlyphStyle.textSecondary)
            .disabled(reportedIDs.contains(post.id))
        }
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private var reviewingCopy: EmpathyCopy? {
        copies.first { $0.reviewState == .reviewing }
    }

    private var reportedIDs: Set<String> {
        EmpathySeaDemoCatalog.reportedIDs(from: reportedIDsBlob)
    }

    private var reportAlertBinding: Binding<Bool> {
        Binding(
            get: { postPendingReport != nil },
            set: { if $0 == false { postPendingReport = nil } }
        )
    }
}

private struct EmpathyCopyEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var entry: DayEntry?

    @State private var text: String
    @State private var acknowledgesPublicCopy = false
    @State private var showsSubmitConfirmation = false

    init(entry: DayEntry?) {
        self.entry = entry
        _text = State(initialValue: String((entry?.text ?? "").prefix(300)))
    }

    private var warnings: [String] {
        EmpathySeaDemoCatalog.contactWarnings(in: text)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("编辑匿名副本")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)

                Text("这里是一份独立副本。你可以清空重写，任何修改都不会影响原始日记。")
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .lineSpacing(4)

                TextEditor(text: $text)
                    .frame(minHeight: 240)
                    .padding(12)
                    .background(DayGlyphStyle.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(DayGlyphStyle.divider, lineWidth: 1)
                    }
                    .onChange(of: text) { _, value in
                        if value.count > 300 { text = String(value.prefix(300)) }
                    }

                Text("\(text.count)/300")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if warnings.isEmpty == false {
                    Label(
                        "检测到可能的\(warnings.joined(separator: "、"))。发送前请确认是否移除。内容不会被自动修改。",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.danger)
                    .padding(14)
                    .background(DayGlyphStyle.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }

                Toggle(isOn: $acknowledgesPublicCopy) {
                    Text("我知道这份副本会以匿名形式进入本地演示海域")
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.textPrimary)
                }

                Button {
                    showsSubmitConfirmation = true
                } label: {
                    Label("匿名放入海中", systemImage: "water.waves")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.glassProminent)
                .tint(DayGlyphStyle.universe)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || acknowledgesPublicCopy == false)
            }
            .padding(20)
        }
        .background(DayGlyphBackground())
        .navigationTitle("匿名副本")
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认放入共情海？", isPresented: $showsSubmitConfirmation) {
            Button("放入海中") { submit() }
            Button("再检查一下", role: .cancel) {}
        } message: {
            Text("发送的是当前编辑副本，不是原始日记。演示内容只保存在本机。")
        }
    }

    private func submit() {
        guard let copy = try? EmpathyCopyStore.makeDraft(text: text, sourceEntryId: entry?.entryID) else { return }
        EmpathyCopyStore.submit(copy)
        modelContext.insert(copy)
        try? modelContext.save()
        dismiss()
    }
}
