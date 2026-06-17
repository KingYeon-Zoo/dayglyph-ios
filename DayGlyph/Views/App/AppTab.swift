import SwiftUI

nonisolated enum AppTab: String, CaseIterable, Identifiable {
    case today
    case universe
    case echo
    case mine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "今日"
        case .universe: "宇宙"
        case .echo: "回声"
        case .mine: "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "house.fill"
        case .universe: "sparkles"
        case .echo: "dot.radiowaves.left.and.right"
        case .mine: "person.crop.circle"
        }
    }

    @MainActor var tint: Color {
        switch self {
        case .today: DayGlyphStyle.today
        case .universe: DayGlyphStyle.universe
        case .echo: DayGlyphStyle.echo
        case .mine: DayGlyphStyle.mine
        }
    }
}
