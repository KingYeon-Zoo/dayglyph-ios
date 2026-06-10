import Foundation
import FoundationModels

enum AppleIntelligenceStatus: Equatable {
    case available
    case appleIntelligenceNotEnabled
    case modelNotReady
    case deviceNotEligible
    case unknown

    var canUseFoundationModels: Bool {
        self == .available
    }

    var title: String {
        switch self {
        case .available:
            "Apple Intelligence 已就绪"
        case .appleIntelligenceNotEnabled:
            "Apple Intelligence 尚未开启"
        case .modelNotReady:
            "Apple Intelligence 正在准备"
        case .deviceNotEligible:
            "此设备不符合运行条件"
        case .unknown:
            "暂时无法使用 Apple Intelligence"
        }
    }

    var detail: String {
        switch self {
        case .available:
            "DayGlyph 会优先使用设备端模型理解记录。"
        case .appleIntelligenceNotEnabled:
            "请在系统设置中开启 Apple Intelligence；当前继续使用本地分析。"
        case .modelNotReady:
            "系统模型仍在准备或下载；当前继续使用本地分析。"
        case .deviceNotEligible:
            "设备、地区或系统资格不满足要求；当前继续使用本地分析。"
        case .unknown:
            "系统没有返回可识别的状态；当前继续使用本地分析。"
        }
    }

    var suggestion: String {
        switch self {
        case .available:
            "无需额外设置。"
        case .appleIntelligenceNotEnabled:
            "请前往系统设置开启 Apple Intelligence。"
        case .modelNotReady:
            "请保持设备联网并连接电源，等待系统模型准备完成。"
        case .deviceNotEligible:
            "请在符合条件且已启用 Apple Intelligence 的 Mac 模拟器或实体设备上验证。"
        case .unknown:
            "请检查系统版本和 Apple Intelligence 设置后重试。"
        }
    }

    var symbolName: String {
        switch self {
        case .available:
            "apple.intelligence"
        case .modelNotReady:
            "arrow.trianglehead.2.clockwise.rotate.90"
        case .appleIntelligenceNotEnabled, .deviceNotEligible, .unknown:
            "exclamationmark.triangle"
        }
    }

    static var environmentTitle: String {
#if targetEnvironment(simulator)
        "iOS 模拟器 · 使用宿主 Mac 的系统模型"
#else
        "实体设备 · 使用本机系统模型"
#endif
    }

    static var current: Self {
        switch SystemLanguageModel.default.availability {
        case .available:
            .available
        case .unavailable(.appleIntelligenceNotEnabled):
            .appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            .modelNotReady
        case .unavailable(.deviceNotEligible):
            .deviceNotEligible
        case .unavailable:
            .unknown
        }
    }
}
