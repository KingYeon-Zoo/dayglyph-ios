import Foundation
import SwiftUI

enum DayEmotion: String, CaseIterable, Codable, Identifiable {
    case calm
    case joy
    case low
    case anxious
    case excited
    case tired
    case grateful
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: "平静"
        case .joy: "喜悦"
        case .low: "低落"
        case .anxious: "焦虑"
        case .excited: "激动"
        case .tired: "疲惫"
        case .grateful: "感恩"
        case .mixed: "混合"
        }
    }
}

enum DayTheme: String, CaseIterable, Codable, Identifiable {
    case work
    case relationship
    case growth
    case rest
    case family
    case health
    case creativity
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: "工作"
        case .relationship: "关系"
        case .growth: "成长"
        case .rest: "休息"
        case .family: "家庭"
        case .health: "健康"
        case .creativity: "创造"
        case .unknown: "未知"
        }
    }
}

struct EmotionAnalysis: Equatable {
    var emotion: DayEmotion
    var theme: DayTheme
    var energy: Double
    var keywords: [String]
}
