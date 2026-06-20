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
        // 同一天重新生成时复用 DayEntry ID；新记录则让该 ID 贯穿 AI 记录与首页记录。
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        let entryID = (try? context.fetch(descriptor).first?.entryID) ?? UUID()
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

    // MARK: - 个性化扩展（已清洗，nil 即回退本地默认）

    /// 已清洗的过程文案（spec 5.1）。
    var experienceCopy: ExperienceCopySpec? {
        GenerationExtrasValidator.sanitizedExperienceCopy(orchestrator.response?.experienceCopy)
    }

    /// 已清洗的结果叙事（spec 5.2）。
    var resultNarrative: ResultNarrativeSpec? {
        GenerationExtrasValidator.sanitizedResultNarrative(orchestrator.response?.resultNarrative)
    }

    /// 已清洗的三档行动（spec 5.3）。nil 时由结果页回退本地 `MicroActionCatalog`。
    var actionOptions: [ActionOptionSpec]? {
        GenerationExtrasValidator.sanitizedActionOptions(orchestrator.response?.actionOptions)
    }

    /// 已清洗的分享卡规格（spec 5.4）。
    var shareCard: ShareCardSpec? {
        GenerationExtrasValidator.sanitizedShareCard(orchestrator.response?.shareCard)
    }

    /// 始终可用的分享卡规格：AI 规格非法时回退默认版式 + 已验证当日名称与寄语（spec 第 10 节）。
    var resolvedShareCard: ShareCardSpec {
        if let card = shareCard { return card }
        let caption = orchestrator.response?.dailyMessage.text ?? "今天已经走到了这里。"
        return ShareCardSpec(
            title: cocktailDisplayName,
            caption: String(caption.prefix(40)),
            visualFocus: "cocktail",
            layoutVariant: "portrait_centered",
            privacyLevel: "emotion_only"
        )
    }

    /// 鸡尾酒展示名：优先结果叙事，回退核心 cocktail.name，最后固定文案。
    var cocktailDisplayName: String {
        if let name = resultNarrative?.cocktailName, !name.isEmpty { return name }
        let coreName = orchestrator.response?.cocktail.name ?? ""
        return coreName.isEmpty ? "今日鸡尾酒" : coreName
    }

    /// 星球展示名：优先结果叙事，回退核心 planet.name，最后固定文案。
    var planetDisplayName: String {
        if let name = resultNarrative?.planetName, !name.isEmpty { return name }
        let coreName = orchestrator.response?.planet.name ?? ""
        return coreName.isEmpty ? "今日星球" : coreName
    }

    // MARK: - 派生 UI 状态

    /// 当前阶段文案（spec 第 8 节：真实阶段，不展示虚假百分比）。
    /// 结构化文本返回后、双图仍在生成的阶段优先用 AI 过程文案（spec 5.1）；
    /// AI 返回前与失败提示继续用固定中性文案。
    var phaseTitle: String {
        switch orchestrator.status {
        case .draft, .analyzing: "正在理解今天的感受"
        case .validating: "正在确认理解"
        case .contentReady, .generatingImages:
            if let copy = experienceCopy {
                switch (orchestrator.cocktailStatus, orchestrator.planetStatus) {
                case (.saved, _): copy.planetProgress
                case (_, .saved): copy.cocktailProgress
                default: copy.imageGenerationTitle
                }
            } else {
                switch (orchestrator.cocktailStatus, orchestrator.planetStatus) {
                case (.saved, _), (_, .saved): "正在凝结星球表面"
                case (.downloading, _), (_, .downloading): "正在保存画面"
                default: "正在设计你的鸡尾酒与星球"
                }
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
            let saved = try DayEntryStore.saveEntry(
                entryID: orchestrator.entryID,
                text: recordText,
                analysis: analysis,
                context: context
            )
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
