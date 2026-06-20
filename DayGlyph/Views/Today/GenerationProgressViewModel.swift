import Foundation
import SwiftData
import SwiftUI

/// 领域状态到 SwiftUI 状态的转换（spec 模块边界 GenerationProgressViewModel）。
///
/// 桥接 `DayGenerationOrchestrator`（AI 生成 + AIGenerationRecord）与 `DayEntryStore`
/// （每日索引 + 统计/视觉兼容）。文本理解成功后即写入 DayEntry，使现有统计与历史可用；
/// 双图作为增强主视觉独立揭示。
@MainActor
@Observable
final class GenerationProgressViewModel {
    let orchestrator: DayGenerationOrchestrator
    private let context: ModelContext
    private let recordText: String
    private var didPersistEntry = false

    private(set) var entry: DayEntry?

    init(text: String, context: ModelContext, configuration: AIConfiguration = .demo) {
        self.recordText = text
        self.context = context
        // entryID 预生成，贯穿 orchestrator 与 DayEntry。
        let entryID = UUID()
        self.orchestrator = DayGenerationOrchestrator(
            entryID: entryID,
            context: context,
            configuration: configuration
        )
    }

    func start() {
        orchestrator.start(record: recordText)
    }

    func cancel() {
        orchestrator.cancel()
    }

    func retryCocktail() { orchestrator.retrySlot(.cocktail) }
    func retryPlanet() { orchestrator.retrySlot(.planet) }

    // MARK: - 派生 UI 状态

    /// 当前阶段文案（spec 第 8 节：真实阶段，不展示虚假百分比）。
    var phaseTitle: String {
        switch orchestrator.status {
        case .draft, .analyzing: "正在理解今天的感受"
        case .validating: "正在确认理解"
        case .contentReady, .generatingImages:
            switch (orchestrator.cocktailStatus, orchestrator.planetStatus) {
            case (.saved, _), (_, .saved): "正在凝结星球表面"
            case (.downloading, _), (_, .downloading): "正在保存画面"
            default: "正在设计你的鸡尾酒与星球"
            }
        case .partiallyReady: "正在等待另一张画面"
        case .completed: "今天的结果已就绪"
        case .retryableFailure: "生成遇到问题"
        case .blockedBySafety: "先照顾好此刻的你"
        case .cancelled: "已取消"
        }
    }

    var isAnalyzing: Bool {
        switch orchestrator.status {
        case .draft, .analyzing, .validating: true
        default: false
        }
    }

    var contentReady: Bool {
        orchestrator.response != nil && orchestrator.status != .blockedBySafety
    }

    var isBlockedBySafety: Bool {
        orchestrator.status == .blockedBySafety
    }

    var isFailed: Bool {
        orchestrator.status == .retryableFailure
    }

    var errorMessage: String? {
        orchestrator.errorMessage
    }

    /// 文本就绪后把分析写入 DayEntry（只写一次），供统计与历史使用。
    func persistEntryIfReady() {
        guard !didPersistEntry, let response = orchestrator.response, !isBlockedBySafety else { return }
        let analysis = GenerationAnalysisMapper.makeAnalysis(from: response)
        do {
            let saved = try DayEntryStore.saveEntry(text: recordText, analysis: analysis, context: context)
            self.entry = saved
            didPersistEntry = true
        } catch {
            // 保存失败不阻塞展示，仅记录。
            orchestratorSaveFailed(error)
        }
    }

    private func orchestratorSaveFailed(_ error: Error) {
        #if DEBUG
        print("DayEntry 保存失败：\(error.localizedDescription)")
        #endif
    }
}
