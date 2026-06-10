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
