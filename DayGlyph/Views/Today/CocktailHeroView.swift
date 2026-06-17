import SwiftUI

struct CocktailHeroView: View {
    var recipe: EmotionRecipe
    var visual: CocktailVisual

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DayGlyphStyle.heroRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DayGlyphStyle.todaySoft,
                            DayGlyphStyle.mineSoft,
                            DayGlyphStyle.echoSoft
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 14) {
                glass
                    .frame(width: 150, height: 190)

                Text(recipe.name)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 286)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name)，\(recipe.primary.title)配方")
    }

    private var glass: some View {
        ZStack(alignment: .bottom) {
            glassShape
                .fill(.white.opacity(0.42))
                .overlay {
                    glassShape
                        .stroke(.white.opacity(0.82), lineWidth: 2)
                }
                .shadow(color: DayGlyphStyle.today.opacity(0.18), radius: 22, y: 12)

            VStack(spacing: 0) {
                ForEach(Array(visual.liquidLayers.prefix(3).enumerated()), id: \.offset) { item in
                    Rectangle()
                        .fill(Color(hex: item.element).opacity(0.82))
                        .frame(height: layerHeight(for: item.offset))
                }
            }
            .clipShape(glassShape)
            .padding(.horizontal, 16)
            .padding(.bottom, visual.glassType == "coupe" ? 38 : 18)

            garnish
                .offset(x: 42, y: visual.glassType == "coupe" ? -132 : -150)
        }
    }

    private var glassShape: some Shape {
        RoundedRectangle(cornerRadius: visual.glassType == "highball" ? 26 : 34, style: .continuous)
    }

    private var garnish: some View {
        Image(systemName: garnishSymbol)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(DayGlyphStyle.textPrimary.opacity(0.66))
            .frame(width: 44, height: 44)
            .background(.white.opacity(0.58), in: Circle())
    }

    private var garnishSymbol: String {
        switch visual.garnish {
        case "rose": "camera.macro"
        case "mint": "leaf"
        case "citrus": "circle.lefthalf.filled"
        default: "sparkle"
        }
    }

    private func layerHeight(for index: Int) -> CGFloat {
        [52, 46, 40][min(index, 2)]
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
