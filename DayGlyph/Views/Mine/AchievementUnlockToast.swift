import SwiftUI

/// 成就解锁提示条：在「我的」首次检测到 .live 成就解锁时短暂浮现，带稀有度配色。
struct AchievementUnlockToast: View {
    var achievement: EmotionAchievement

    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: DayGlyphStyle.mine
        case .rare: Color(red: 0.26, green: 0.62, blue: 0.92)
        case .epic: Color(red: 0.62, green: 0.38, blue: 0.90)
        case .legendary: Color(red: 0.95, green: 0.70, blue: 0.22)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.symbol)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Circle().fill(rarityColor))
                .shadow(color: rarityColor.opacity(0.6), radius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("点亮成就 · \(achievement.rarity.title)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(rarityColor)
                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
            }
            Spacer()
            Image(systemName: "sparkles")
                .foregroundStyle(rarityColor)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DayGlyphStyle.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(rarityColor.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("点亮成就：\(achievement.title)，\(achievement.rarity.title)")
    }
}
