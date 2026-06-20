import SwiftUI

struct UniversePlanetView: View {
    var visual: MonthlyPlanetVisual
    var size: CGFloat = 238
    /// 单日记录的真实生成星球图（存在时优先显示，否则程序化绘制）。月度聚合星球不传此参数。
    var generatedImage: UIImage?

    var body: some View {
        if let generatedImage {
            Image(uiImage: generatedImage)
                .resizable()
                .scaledToFit()
                .frame(width: size * 1.1, height: size * 1.1)
                .clipShape(Circle())
                .shadow(color: color(hue: visual.baseHue).opacity(visual.glow * 0.55), radius: size * 0.18)
                .frame(maxWidth: .infinity)
                .frame(height: size * 1.3)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("情绪星球")
        } else {
            proceduralPlanet
        }
    }

    private var proceduralPlanet: some View {
        ZStack {
            ForEach(0 ..< visual.rings, id: \.self) { index in
                Ellipse()
                    .stroke(.white.opacity(0.14 + Double(index) * 0.04), lineWidth: 1)
                    .frame(width: size * (1.20 + CGFloat(index) * 0.16), height: size * 0.42)
                    .rotationEffect(.degrees(-18 + Double(index) * 26))
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color(hue: visual.secondaryHue).opacity(0.92),
                            color(hue: visual.baseHue).opacity(0.96),
                            color(hue: visual.baseHue).opacity(0.38),
                            .black.opacity(0.82)
                        ],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: size * 0.72
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.20))
                        .frame(width: size * 0.34)
                        .blur(radius: size * 0.09)
                        .offset(x: -size * 0.12, y: size * 0.09)
                }
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
                .frame(width: size * visual.sizeScale, height: size * visual.sizeScale)
                .shadow(
                    color: color(hue: visual.baseHue).opacity(visual.glow * 0.55),
                    radius: size * 0.18
                )

            ForEach(Array(visual.recordDots.enumerated()), id: \.offset) { index, _ in
                let angle = Double(index) / Double(max(visual.recordDots.count, 1)) * 360 - 90
                Circle()
                    .fill(.white.opacity(0.92))
                    .frame(width: 7, height: 7)
                    .shadow(color: .white.opacity(0.65), radius: 5)
                    .offset(y: -size * 0.48)
                    .rotationEffect(.degrees(angle))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: size * 1.3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "月星球，\(visual.recordDots.count) 个记录日，\(UniversePresentation.complexityDescription(visual.textureComplexity))"
        )
    }

    private func color(hue: Double) -> Color {
        Color(hue: hue / 360, saturation: 0.66, brightness: 0.92)
    }
}
