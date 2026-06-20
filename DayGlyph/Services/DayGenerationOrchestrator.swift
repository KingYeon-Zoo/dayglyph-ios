import Foundation
import SwiftData

/// 日生成编排器（spec 第 8、12 节）。
///
/// 客户端状态机编排：文本理解 → 校验 → 内容就绪 → 并行双图 → 部分就绪 → 完成。
/// 负责并发、取消、重试、恢复；单图失败不阻塞另一张；高风险短路到安全支持。
///
/// 未来若改后端代理，只替换 textClient / imageClient，状态机与持久化不变。
@MainActor
@Observable
final class DayGenerationOrchestrator {
    // 领域状态（供 ViewModel 观察）。
    private(set) var status: GenerationStatus = .draft
    private(set) var response: DayGenerationResponse?
    private(set) var cocktailStatus: ImageSlotStatus = .notStarted
    private(set) var planetStatus: ImageSlotStatus = .notStarted
    private(set) var cocktailImage: Data?
    private(set) var planetImage: Data?
    private(set) var errorMessage: String?

    let entryID: UUID
    private(set) var generationID: UUID

    private let configuration: AIConfiguration
    private let textClient: any SeedTextGenerating
    private let imageClient: any SeedImageGenerating
    private let assetStore: GeneratedAssetStore
    private let repository: GenerationRepository
    private var record: AIGenerationRecord?

    private var runTask: Task<Void, Never>?

    init(
        entryID: UUID,
        context: ModelContext,
        configuration: AIConfiguration = .demo,
        textClient: (any SeedTextGenerating)? = nil,
        imageClient: (any SeedImageGenerating)? = nil,
        assetStore: GeneratedAssetStore = GeneratedAssetStore()
    ) {
        self.entryID = entryID
        self.generationID = UUID()
        self.configuration = configuration
        self.textClient = textClient ?? SeedTextClient(configuration: configuration)
        self.imageClient = imageClient ?? SeedImageClient(configuration: configuration)
        self.assetStore = assetStore
        self.repository = GenerationRepository(context: context, assetStore: assetStore)
    }

    // MARK: - 启动

    /// 开始一次全新生成（spec 第 8 节完整链路）。
    func start(record text: String) {
        runTask?.cancel()
        runTask = Task { await run(text: text) }
    }

    func cancel() {
        runTask?.cancel()
        status = .cancelled
        persistStatus()
    }

    // MARK: - 主流程

    private func run(text: String) async {
        do {
            // 第一层安全短路（spec 第 9 节）。
            if SafetyPrescreen.isHighRisk(text) {
                try enterSafety()
                return
            }

            // 创建草稿记录。
            let newRecord = try repository.create(entryID: entryID, configuration: configuration)
            self.record = newRecord
            self.generationID = newRecord.generationID

            // 文本理解。
            transition(.analyzing)
            let generated = try await textClient.generate(record: text)
            try Task.checkCancellation()

            // 第二层安全判断（spec 第 9 节）。
            transition(.validating)
            if generated.safety.isHighRisk {
                self.response = generated
                try enterSafety()
                return
            }

            // 内容就绪：文本先展示。
            self.response = generated
            newRecord.setResponse(generated)
            transition(.contentReady)

            // 并行双图（spec 第 8 节：两张独立揭示，局部失败不阻塞）。
            transition(.generatingImages)
            await generateImages(from: generated)

            // 汇总状态。
            finalizeStatus()
        } catch is CancellationError {
            status = .cancelled
            persistStatus()
        } catch let error as DoubaoClientError where error == .cancelled {
            status = .cancelled
            persistStatus()
        } catch {
            errorMessage = error.localizedDescription
            transition(.retryableFailure)
        }
    }

    // MARK: - 双图并发

    private func generateImages(from generated: DayGenerationResponse) async {
        let cocktailPrompt = PromptTemplateEngine.cocktailPrompt(
            cocktail: generated.cocktail,
            shared: generated.sharedVisualDirection
        )
        let planetPrompt = PromptTemplateEngine.planetPrompt(
            planet: generated.planet,
            shared: generated.sharedVisualDirection
        )
        record?.cocktailPromptHash = cocktailPrompt.hash
        record?.planetPromptHash = planetPrompt.hash
        persist()

        // 两张图独立并发，互不阻塞（spec 第 8 节）。
        async let cocktail: Void = generateSlot(.cocktail, prompt: cocktailPrompt.text, size: configuration.cocktailSize)
        async let planet: Void = generateSlot(.planet, prompt: planetPrompt.text, size: configuration.planetSize)
        _ = await (cocktail, planet)
    }

    private func generateSlot(_ slot: GeneratedAssetStore.Slot, prompt: String, size: String) async {
        setSlotStatus(slot, .rendering)
        do {
            let image = try await imageClient.generate(prompt: prompt, size: size)
            try Task.checkCancellation()
            setSlotStatus(slot, .downloading)
            let url = try assetStore.save(image.data, entryID: entryID, generationID: generationID, slot: slot)
            _ = url
            applySlotResult(slot, data: image.data, pixelSize: image.size)
            setSlotStatus(slot, .saved)
        } catch {
            setSlotStatus(slot, .failed)
        }
    }

    /// 单图重试（spec 第 8 节、决策 10：换一张沿用同一 JSON，仅重新生图）。
    func retrySlot(_ slot: GeneratedAssetStore.Slot) {
        guard let generated = response else { return }
        runTask = Task {
            let prompt: RenderedPrompt
            let size: String
            switch slot {
            case .cocktail:
                prompt = PromptTemplateEngine.cocktailPrompt(cocktail: generated.cocktail, shared: generated.sharedVisualDirection)
                size = configuration.cocktailSize
            case .planet:
                prompt = PromptTemplateEngine.planetPrompt(planet: generated.planet, shared: generated.sharedVisualDirection)
                size = configuration.planetSize
            }
            await generateSlot(slot, prompt: prompt.text, size: size)
            finalizeStatus()
        }
    }

    // MARK: - 恢复（spec 第 8 节：App 重启读取本地任务，只补未保存的图片）

    /// 从已有记录恢复未完成生成。
    func resume(from record: AIGenerationRecord) {
        self.record = record
        self.generationID = record.generationID
        self.response = record.response
        self.cocktailStatus = record.cocktailStatus
        self.planetStatus = record.planetStatus
        self.cocktailImage = assetStore.load(entryID: entryID, generationID: generationID, slot: .cocktail)
        self.planetImage = assetStore.load(entryID: entryID, generationID: generationID, slot: .planet)

        guard let generated = record.response else {
            status = .retryableFailure
            return
        }

        runTask?.cancel()
        runTask = Task {
            status = .generatingImages
            await withTaskGroup(of: Void.self) { group in
                if cocktailStatus != .saved {
                    group.addTask { @MainActor in
                        let prompt = PromptTemplateEngine.cocktailPrompt(cocktail: generated.cocktail, shared: generated.sharedVisualDirection)
                        await self.generateSlot(.cocktail, prompt: prompt.text, size: self.configuration.cocktailSize)
                    }
                }
                if planetStatus != .saved {
                    group.addTask { @MainActor in
                        let prompt = PromptTemplateEngine.planetPrompt(planet: generated.planet, shared: generated.sharedVisualDirection)
                        await self.generateSlot(.planet, prompt: prompt.text, size: self.configuration.planetSize)
                    }
                }
            }
            finalizeStatus()
        }
    }

    // MARK: - 状态辅助

    private func enterSafety() throws {
        cocktailStatus = .notStarted
        planetStatus = .notStarted
        transition(.blockedBySafety)
    }

    private func transition(_ newStatus: GenerationStatus) {
        status = newStatus
        persistStatus()
    }

    private func setSlotStatus(_ slot: GeneratedAssetStore.Slot, _ status: ImageSlotStatus) {
        switch slot {
        case .cocktail:
            cocktailStatus = status
            record?.cocktailStatus = status
        case .planet:
            planetStatus = status
            record?.planetStatus = status
        }
        // 一张完成即进入部分就绪。
        if status == .saved, self.status == .generatingImages {
            if !(cocktailStatus == .saved && planetStatus == .saved) {
                self.status = .partiallyReady
            }
        }
        persist()
    }

    private func applySlotResult(_ slot: GeneratedAssetStore.Slot, data: Data, pixelSize: String?) {
        switch slot {
        case .cocktail:
            cocktailImage = data
            record?.cocktailPixelSize = pixelSize ?? ""
        case .planet:
            planetImage = data
            record?.planetPixelSize = pixelSize ?? ""
        }
    }

    private func finalizeStatus() {
        if cocktailStatus == .saved && planetStatus == .saved {
            status = .completed
        } else if cocktailStatus == .saved || planetStatus == .saved {
            status = .partiallyReady
        } else {
            status = .retryableFailure
        }
        persistStatus()
    }

    private func persistStatus() {
        record?.status = status
        persist()
    }

    private func persist() {
        try? repository.save()
    }
}
