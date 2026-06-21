import SwiftUI

/// 单颗记录星：玻璃拟态柔光核心 + 外层辉光 + 常驻日期数字标签。
/// 颜色取当天主导情绪色相，大小取能量（arousal），「今天」与选中态加高亮环。
struct RecordStar: View {
    var day: UniverseDaySummary
    var isSelected: Bool
    var isToday: Bool
    var reduceMotion: Bool

    private var core: Color { starColor(saturation: 0.66, brightness: 0.96) }
    private var halo: Color { starColor(saturation: 0.58, brightness: 0.88) }

    /// 能量映射到星核直径：5...11pt，克制不夸张。选中时再放大。
    private var diameter: CGFloat {
        let clamped = min(max(day.arousal, 0), 1)
        let base = 5 + clamped * 6
        return isSelected ? base * 1.4 : base
    }

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: day.date))
    }

    var body: some View {
        VStack(spacing: 5) {
            starOrb
            Text(dayNumber)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(isSelected || isToday ? 0.96 : 0.74))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    if isToday {
                        Capsule().stroke(core.opacity(0.9), lineWidth: 0.8)
                    }
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var starOrb: some View {
        ZStack {
            Circle()
                .fill(halo)
                .frame(width: diameter * 2.6, height: diameter * 2.6)
                .blur(radius: diameter * 0.9)
                .opacity(0.55)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, core, core.opacity(0.5)],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.7
                    )
                )
                .frame(width: diameter, height: diameter)
                .overlay {
                    Circle().stroke(.white.opacity(0.6), lineWidth: 0.5)
                }

            if isSelected || isToday {
                Circle()
                    .stroke(.white.opacity(isSelected ? 0.85 : 0.5), lineWidth: 1)
                    .frame(width: diameter * 2.0, height: diameter * 2.0)
            }
        }
        .frame(width: diameter * 2.6, height: diameter * 2.6)
    }

    private var accessibilityText: String {
        let date = day.date.formatted(.dateTime.month().day())
        return "\(date)，\(day.cocktailName)\(isToday ? "，今天" : "")"
    }

    private func starColor(saturation: Double, brightness: Double) -> Color {
        let normalized = day.planet.baseHue.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        return Color(hue: positive / 360, saturation: saturation, brightness: brightness)
    }
}
