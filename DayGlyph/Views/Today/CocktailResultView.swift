import SwiftData
import SwiftUI

nonisolated enum CocktailResultMode {
    case today
    case history
}

nonisolated enum CocktailResultCopy {
    static func title(for confidenceBand: ConfidenceBand) -> String {
        switch confidenceBand {
        case .low: "今天可能由这些感受组成"
        case .medium, .high: "今日情绪鸡尾酒"
        }
    }

    static func favoriteButtonTitle(isFavorite: Bool) -> String {
        isFavorite ? "已收藏" : "收藏配方"
    }
}

struct CocktailResultView: View {
    @Environment(\.modelContext) private var modelContext

    var entry: DayEntry
    var mode: CocktailResultMode

    @State private var showsImageToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            hero
            recipeDetails
            if case .history = mode {
                weatherCard
            }
            actions
        }
        .overlay(alignment: .bottom) {
            if showsImageToast {
                Text("保存图片会在下一阶段接入")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(DayGlyphStyle.textPrimary.opacity(0.88), in: Capsule())
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(CocktailResultCopy.title(for: entry.emotionRecipe.confidenceBand))
                    .font(.title.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)

                Text(entry.date, format: .dateTime.month().day().weekday())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            }

            CocktailHeroView(recipe: entry.emotionRecipe, visual: entry.cocktailVisual)

            if entry.emotionRecipe.keywords.isEmpty == false {
                HStack(spacing: 8) {
                    ForEach(entry.emotionRecipe.keywords.prefix(3), id: \.self) { keyword in
                        Text(keyword)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DayGlyphStyle.today)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(DayGlyphStyle.todaySoft, in: Capsule())
                    }
                }
            }

            Text(entry.emotionRecipe.supportCopy)
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineSpacing(4)
        }
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.heroRadius)
    }

    private var recipeDetails: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("配方")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)

            ForEach(entry.emotionRecipe.parts) { part in
                HStack {
                    Text(part.anchor.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(DayGlyphStyle.textPrimary)
                    Spacer()
                    Text("\(part.parts) 份")
                        .font(.body.monospacedDigit().weight(.semibold))
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("今天的天气", systemImage: "cloud.sun")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)

            Text("\(entry.moodWeather.intensityBand)的\(entry.moodWeather.type)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.textPrimary)

            Text(entry.moodWeather.explanation)
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                favoriteButton
                saveImageButton
            }

            VStack(spacing: 10) {
                favoriteButton
                saveImageButton
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, mode == .history ? 0 : 4)
    }

    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            Label(
                CocktailResultCopy.favoriteButtonTitle(isFavorite: entry.isFavorite),
                systemImage: entry.isFavorite ? "heart.fill" : "heart"
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
        .buttonStyle(.glassProminent)
        .tint(DayGlyphStyle.today)
    }

    private var saveImageButton: some View {
        Button(action: showImageToast) {
            Label("保存图片", systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
        }
        .buttonStyle(.glass)
    }

    private func toggleFavorite() {
        entry.isFavorite.toggle()
        try? modelContext.save()
    }

    private func showImageToast() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            showsImageToast = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.2)) {
                showsImageToast = false
            }
        }
    }
}
