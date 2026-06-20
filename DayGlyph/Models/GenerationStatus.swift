import Foundation

/// 总任务状态机（spec 第 8 节）。
///
/// draft → analyzing → validating → contentReady → generatingImages
/// → partiallyReady → completed
/// 任意阶段可进入 retryableFailure / blockedBySafety / cancelled。
enum GenerationStatus: String, Codable, Sendable, Equatable {
    case draft
    case analyzing
    case validating
    case contentReady
    case generatingImages
    case partiallyReady
    case completed
    case retryableFailure
    case blockedBySafety
    case cancelled
}

/// 单张图状态（spec 第 8 节）：notStarted → rendering → downloading → saved。
/// 失败进入 failed（可单独重试）。
enum ImageSlotStatus: String, Codable, Sendable, Equatable {
    case notStarted
    case rendering
    case downloading
    case saved
    case failed
}
