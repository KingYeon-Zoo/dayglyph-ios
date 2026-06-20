import SwiftUI

struct AchievementsView: View {
    var achievements: [EmotionAchievement]

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var unlockedCount: Int { achievements.filter(\.isUnlocked).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                summary
                ForEach(AchievementCategory.allCases) { category in
                    let items = achievements.filter { $0.category == category }
                    if !items.isEmpty {
                        section(category, items)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 96)
        }
        .background(DayGlyphBackground())
        .navigationTitle("情绪成就")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("已点亮 \(unlockedCount) / \(achievements.count)")
                .font(.title2.weight(.bold))
                .foregroundStyle(DayGlyphStyle.mine)
            Text("记录得越久，越多成就会被点亮。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .paperCard()
    }

    private func section(_ category: AchievementCategory, _ items: [EmotionAchievement]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.title)
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(items) { item in
                    AchievementCard(achievement: item)
                }
            }
        }
    }
}

/// 单个成就卡片：解锁时按稀有度上色 + 光晕，未解锁灰态 + 进度。
private struct AchievementCard: View {
    var achievement: EmotionAchievement

    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: DayGlyphStyle.mine
        case .rare: Color(red: 0.26, green: 0.62, blue: 0.92)
        case .epic: Color(red: 0.62, green: 0.38, blue: 0.90)
        case .legendary: Color(red: 0.95, green: 0.70, blue: 0.22)
        }
    }

    private var unlocked: Bool { achievement.isUnlocked }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: achievement.symbol)
                    .font(.title2)
                    .foregroundStyle(unlocked ? rarityColor : DayGlyphStyle.textSecondary.opacity(0.6))
                    .frame(width: 46, height: 46)
                    .background(
                        Circle().fill(unlocked ? rarityColor.opacity(0.16) : DayGlyphStyle.divider.opacity(0.4))
                    )
                Spacer()
                rarityBadge
            }

            Text(achievement.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(unlocked ? DayGlyphStyle.textPrimary : DayGlyphStyle.textSecondary)
                .lineLimit(1)

            Text(achievement.description)
                .font(.caption)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 32, alignment: .top)

            if unlocked {
                Label("已点亮", systemImage: "checkmark.seal.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(rarityColor)
            } else if achievement.kind == .live {
                ProgressView(value: achievement.progressFraction)
                    .tint(rarityColor)
                Text("\(min(achievement.progress, achievement.target))/\(achievement.target)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            } else {
                Label("未点亮", systemImage: "lock.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textSecondary.opacity(0.7))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DayGlyphStyle.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(unlocked ? rarityColor.opacity(0.5 + achievement.rarity.glowStrength * 0.4) : DayGlyphStyle.divider, lineWidth: unlocked ? 1.5 : 1)
        )
        .shadow(
            color: unlocked ? rarityColor.opacity(achievement.rarity.glowStrength * 0.4) : .clear,
            radius: unlocked ? 12 * achievement.rarity.glowStrength + 2 : 0,
            y: 2
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title)，\(achievement.rarity.title)，\(unlocked ? "已点亮" : "未点亮")")
    }

    private var rarityBadge: some View {
        Text(achievement.rarity.title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(unlocked ? rarityColor : DayGlyphStyle.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(unlocked ? rarityColor.opacity(0.14) : DayGlyphStyle.divider.opacity(0.4))
            )
    }
}
