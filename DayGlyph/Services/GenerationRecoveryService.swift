import Foundation
import SwiftData

/// App 重启生成恢复服务（spec 第 8 节）。
///
/// 直连模式无法保证 App 被系统终止后网络请求继续。因此先保存 JSON 与图片参数，
/// 重启后读取本地任务，只补生成尚未保存的图片。
@MainActor
enum GenerationRecoveryService {

    /// 扫描可恢复记录，为每条创建编排器并恢复未保存的图片。
    /// 返回正在恢复的编排器列表，供调用方持有（避免 Task 被释放）。
    @discardableResult
    static func resumePendingGenerations(
        context: ModelContext,
        configuration: AIConfiguration = .demo
    ) -> [DayGenerationOrchestrator] {
        let repository = GenerationRepository(context: context)
        guard let records = try? repository.resumableRecords(), !records.isEmpty else {
            return []
        }

        var orchestrators: [DayGenerationOrchestrator] = []
        for record in records {
            // 已有完整文本结果才值得补图；否则保持为可重试，由用户主动触发。
            guard record.response != nil else { continue }
            let orchestrator = DayGenerationOrchestrator(
                entryID: record.entryID,
                context: context,
                configuration: configuration
            )
            orchestrator.resume(from: record)
            orchestrators.append(orchestrator)
        }
        return orchestrators
    }
}
