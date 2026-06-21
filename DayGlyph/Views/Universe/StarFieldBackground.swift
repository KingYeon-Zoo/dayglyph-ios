import SwiftUI

/// 深空背景：三层——深色渐变底 + 星云雾斑 + 背景星尘。色调随当月平均情绪偏移。
struct StarFieldBackground: View {
    var visual: MonthlyPlanetVisual

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    starColor(hue: visual.baseHue, saturation: 0.42, brightness: 0.22),
                    DayGlyphStyle.universeBackground,
                    Color.black.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Canvas { context, size in
                let nebulae = nebulaSpots(in: size)
                for spot in nebulae {
                    let rect = CGRect(
                        x: spot.center.x - spot.radius,
                        y: spot.center.y - spot.radius,
                        width: spot.radius * 2,
                        height: spot.radius * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [spot.color, .clear]),
                            center: spot.center,
                            startRadius: 0,
                            endRadius: spot.radius
                        )
                    )
                }
            }
            .blur(radius: 28)
            .accessibilityHidden(true)

            Canvas { context, size in
                var random = SeededRandom(seed: visual.seed &+ 7919)
                for _ in 0 ..< 64 {
                    let x = random.next() * size.width
                    let y = random.next() * size.height
                    let diameter = 0.6 + random.next() * 1.6
                    let opacity = 0.12 + random.next() * 0.34
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
            .accessibilityHidden(true)
        }
    }

    private struct NebulaSpot {
        var center: CGPoint
        var radius: CGFloat
        var color: Color
    }

    private func nebulaSpots(in size: CGSize) -> [NebulaSpot] {
        var random = SeededRandom(seed: visual.seed &+ 1301)
        let hues = [visual.baseHue, visual.secondaryHue, visual.baseHue + 28]
        return hues.map { hue in
            let center = CGPoint(
                x: (0.18 + random.next() * 0.64) * size.width,
                y: (0.12 + random.next() * 0.62) * size.height
            )
            let radius = (0.26 + random.next() * 0.22) * min(size.width, size.height) * 1.6
            let alpha = 0.10 + visual.glow * 0.10
            return NebulaSpot(
                center: center,
                radius: radius,
                color: starColor(hue: hue, saturation: 0.62, brightness: 0.86).opacity(alpha)
            )
        }
    }

    private func starColor(hue: Double, saturation: Double, brightness: Double) -> Color {
        let normalized = hue.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        return Color(hue: positive / 360, saturation: saturation, brightness: brightness)
    }
}
