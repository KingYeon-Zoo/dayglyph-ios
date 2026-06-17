import SwiftUI

enum DayGlyphStyle {
    static let canvas = Color(red: 1.0, green: 0.973, blue: 0.980)
    static let surface = Color.white
    static let surfaceSoft = Color(red: 1.0, green: 0.898, blue: 0.929)
    static let textPrimary = Color(red: 0.129, green: 0.106, blue: 0.141)
    static let textSecondary = Color(red: 0.506, green: 0.467, blue: 0.518)
    static let divider = Color(red: 0.933, green: 0.875, blue: 0.898)
    static let today = Color(red: 1.0, green: 0.365, blue: 0.514)
    static let todaySoft = Color(red: 1.0, green: 0.898, blue: 0.929)
    static let universe = Color(red: 0.463, green: 0.341, blue: 0.784)
    static let universeBackground = Color(red: 0.094, green: 0.098, blue: 0.184)
    static let echo = Color(red: 1.0, green: 0.604, blue: 0.263)
    static let echoSoft = Color(red: 1.0, green: 0.941, blue: 0.878)
    static let mine = Color(red: 0.357, green: 0.498, blue: 0.886)
    static let mineSoft = Color(red: 0.914, green: 0.933, blue: 1.0)
    static let danger = Color(red: 0.906, green: 0.361, blue: 0.424)

    static let ink = textPrimary
    static let mutedInk = textSecondary
    static let paper = canvas
    static let mist = surfaceSoft
    static let jade = today
    static let amber = echo
    static let paperSurface = surface.opacity(0.88)
    static let quietSurface = surface.opacity(0.64)

    static let smallRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 18
    static let mediumRadius: CGFloat = 24
    static let largeRadius: CGFloat = 28
    static let heroRadius: CGFloat = 32

    static var background: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: canvas, location: 0),
                .init(color: Color(red: 1.0, green: 0.949, blue: 0.965), location: 0.52),
                .init(color: Color(red: 0.965, green: 0.972, blue: 1.0), location: 1)
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
