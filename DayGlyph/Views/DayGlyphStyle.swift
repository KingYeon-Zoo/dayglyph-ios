import SwiftUI

enum DayGlyphStyle {
    static let ink = Color(red: 0.08, green: 0.13, blue: 0.12)
    static let mutedInk = Color(red: 0.36, green: 0.43, blue: 0.40)
    static let paper = Color(red: 0.97, green: 0.94, blue: 0.88)
    static let mist = Color(red: 0.86, green: 0.91, blue: 0.87)

    static var background: LinearGradient {
        LinearGradient(colors: [paper, mist], startPoint: .topLeading, endPoint: .bottomTrailing)
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
            .background(color.opacity(0.18), in: Capsule())
    }
}
