import Foundation

nonisolated enum OnboardingPage: Int, CaseIterable, Identifiable {
    case value
    case privacy
    case preferences

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .value: "把今天的感受，留成一颗星球"
        case .privacy: "你的感受，由你掌握"
        case .preferences: "按你的节奏开始"
        }
    }

    var points: [String] {
        switch self {
        case .value: ["一句话完成记录", "看见情绪的构成", "回顾长期变化"]
        case .privacy: ["记录默认保存在本机", "公开前由你再次确认", "数据可随时清除"]
        case .preferences: ["提醒可以稍后开启", "行动偏好随时可改", "所有功能都不要求登录"]
        }
    }

    var primaryActionTitle: String {
        self == .preferences ? "完成" : "继续"
    }
}
