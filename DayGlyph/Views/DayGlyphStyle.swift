import SwiftUI

enum DayGlyphStyle {
    static let ink = Color(red: 0.075, green: 0.12, blue: 0.11)
    static let mutedInk = Color(red: 0.34, green: 0.40, blue: 0.375)
    static let paper = Color(red: 0.975, green: 0.96, blue: 0.915)
    static let mist = Color(red: 0.86, green: 0.915, blue: 0.88)
    static let jade = Color(red: 0.12, green: 0.39, blue: 0.34)
    static let amber = Color(red: 0.82, green: 0.60, blue: 0.28)
    static let paperSurface = Color.white.opacity(0.56)
    static let quietSurface = Color.white.opacity(0.34)

    static let smallRadius: CGFloat = 14
    static let mediumRadius: CGFloat = 22
    static let largeRadius: CGFloat = 30

    static var background: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: paper, location: 0),
                .init(color: Color(red: 0.94, green: 0.96, blue: 0.91), location: 0.46),
                .init(color: mist, location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var ambientWash: RadialGradient {
        RadialGradient(
            colors: [Color.white.opacity(0.76), Color.white.opacity(0)],
            center: .topLeading,
            startRadius: 0,
            endRadius: 390
        )
    }
}

struct CapsuleLabel: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(DayGlyphStyle.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.16), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.54), lineWidth: 0.6)
            }
    }
}

struct DayGlyphBackground: View {
    var body: some View {
        ZStack {
            DayGlyphStyle.background
            DayGlyphStyle.ambientWash
        }
        .ignoresSafeArea()
    }
}

struct PaperCardModifier: ViewModifier {
    var cornerRadius: CGFloat = DayGlyphStyle.mediumRadius

    func body(content: Content) -> some View {
        content
            .background(
                DayGlyphStyle.paperSurface,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.68), lineWidth: 0.8)
            }
            .shadow(color: DayGlyphStyle.ink.opacity(0.055), radius: 24, y: 12)
    }
}

extension View {
    func paperCard(cornerRadius: CGFloat = DayGlyphStyle.mediumRadius) -> some View {
        modifier(PaperCardModifier(cornerRadius: cornerRadius))
    }
}
