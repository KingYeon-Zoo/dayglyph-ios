import SwiftUI

struct AchievementsView: View {
    var achievements: [EmotionAchievement]

    var body: some View {
        List {
            Section("已解锁") {
                ForEach(achievements.filter(\.isUnlocked)) { achievement in
                    row(achievement)
                }
            }
            Section("进行中") {
                ForEach(achievements.filter { !$0.isUnlocked }) { achievement in
                    row(achievement)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(DayGlyphBackground())
        .navigationTitle("情绪成就")
    }

    private func row(_ achievement: EmotionAchievement) -> some View {
        HStack(spacing: 14) {
            Image(systemName: achievement.symbol)
                .font(.title2)
                .foregroundStyle(achievement.isUnlocked ? DayGlyphStyle.mine : DayGlyphStyle.textSecondary)
                .frame(width: 48, height: 48)
                .background(DayGlyphStyle.mineSoft, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title).font(.headline)
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                Text("累计 \(min(achievement.progress, achievement.target))/\(achievement.target)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.mine)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
