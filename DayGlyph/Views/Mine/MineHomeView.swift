import SwiftData
import SwiftUI

struct MineHomeView: View {
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]
    @Query(sort: \ActionInstance.createdAt, order: .reverse) private var actions: [ActionInstance]
    @Query(sort: \ActionResponse.createdAt, order: .reverse) private var responses: [ActionResponse]

    @AppStorage("profileNickname") private var nickname = ""
    @AppStorage("announcedAchievements") private var announcedAchievementsBlob = ""
    @State private var editingNickname = false
    @State private var nicknameDraft = ""
    @State private var unlockToast: EmotionAchievement?

    private var achievements: [EmotionAchievement] {
        MineAggregator.achievements(entries: entries, actions: actions, responses: responses)
    }

    /// 已弹过解锁提示的成就 ID 集合。
    private var announcedIDs: Set<String> {
        Set(announcedAchievementsBlob.split(separator: "|").map(String.init))
    }

    /// 检测新解锁的 .live 成就，弹一次提示后记录，避免重复。
    private func detectUnlocks() {
        let newlyUnlocked = achievements.filter { $0.kind == .live && $0.isUnlocked && !announcedIDs.contains($0.id) }
        guard let first = newlyUnlocked.first else { return }
        let updated = announcedIDs.union(newlyUnlocked.map(\.id))
        announcedAchievementsBlob = updated.sorted().joined(separator: "|")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            unlockToast = first
        }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.3)) { unlockToast = nil }
        }
    }

    private var recordDays: Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                profileCard
                metrics
                achievementCard
                links
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
        .background(DayGlyphBackground())
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.inline)
        .task { detectUnlocks() }
        .overlay(alignment: .top) {
            if let toast = unlockToast {
                AchievementUnlockToast(achievement: toast)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("编辑昵称", isPresented: $editingNickname) {
            TextField("情绪旅人", text: $nicknameDraft)
            Button("取消", role: .cancel) {}
            Button("保存") {
                nickname = nicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("我的").font(.largeTitle.weight(.semibold))
            Text("回顾变化，管理只属于你的本地记录。")
                .foregroundStyle(DayGlyphStyle.textSecondary)
        }
    }

    private var profileCard: some View {
        Button {
            nicknameDraft = nickname
            editingNickname = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DayGlyphStyle.mine)
                VStack(alignment: .leading, spacing: 4) {
                    Text(nickname.isEmpty ? "情绪旅人" : nickname)
                        .font(.title2.weight(.semibold))
                    Text("本地个人资料 · 无需登录")
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                }
                Spacer()
                Image(systemName: "pencil")
            }
            .foregroundStyle(DayGlyphStyle.textPrimary)
            .padding(20)
            .paperCard()
        }
        .buttonStyle(.plain)
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            metric("记录天数", recordDays)
            metric("星球", entries.count)
            metric("回声", responses.count)
        }
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.title2.weight(.bold)).foregroundStyle(DayGlyphStyle.mine)
            Text(title).font(.caption).foregroundStyle(DayGlyphStyle.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .paperCard(cornerRadius: 18)
    }

    private var achievementCard: some View {
        NavigationLink {
            AchievementsView(achievements: achievements)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("情绪成就", systemImage: "medal.fill").font(.headline)
                    Text("已解锁 \(achievements.filter(\.isUnlocked).count)/\(achievements.count)")
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(DayGlyphStyle.mine)
            .padding(20)
            .paperCard()
        }
        .buttonStyle(.plain)
    }

    private var links: some View {
        VStack(spacing: 0) {
            NavigationLink { EmotionStatisticsView(entries: entries) } label: { linkRow("情绪统计", "chart.bar.xaxis") }
            Divider().padding(.leading, 46)
            NavigationLink { EmotionHistoryView() } label: { linkRow("情绪历史", "clock.arrow.circlepath") }
            Divider().padding(.leading, 46)
            NavigationLink { SettingsView() } label: { linkRow("设置与隐私", "gearshape") }
        }
        .padding(.horizontal, 16)
        .paperCard()
    }

    private func linkRow(_ title: String, _ symbol: String) -> some View {
        HStack {
            Image(systemName: symbol).frame(width: 24).foregroundStyle(DayGlyphStyle.mine)
            Text(title).foregroundStyle(DayGlyphStyle.textPrimary)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(DayGlyphStyle.textSecondary)
        }
        .frame(minHeight: 54)
    }
}
