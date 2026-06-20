import Foundation
import SwiftData

/// AI 生成版本记录（spec 第 10 节）。
///
/// 独立于 `DayEntry`，保存一次完整生成的全部状态：
/// generation ID、entry ID、状态、各版本号、模型 ID、规范化 JSON、提示词哈希、
/// 双图状态、本地相对信息与错误信息。图片本身不入 SwiftData，只存 slot 状态；
/// 文件路径由 `GeneratedAssetStore` 用 entryID/generationID 推导。
///
/// 重新生成保留旧版本（spec 决策 10）：同一 entry 可有多条记录，用 createdAt 区分版本。
@Model
final class AIGenerationRecord {
    var generationID: UUID = UUID()
    var entryID: UUID = UUID()
    var statusRawValue: String = GenerationStatus.draft.rawValue

    // 版本化（spec 第 7 节：Schema、词库、片段库、模板分别版本化）。
    var schemaVersion: String = "1.0"
    var promptTemplateVersion: String = PromptTemplateEngine.templateVersion
    var lexiconVersion: String = "1.0"

    var textModelID: String = ""
    var imageModelID: String = ""

    /// 规范化后的统一生成 JSON（DayGenerationResponse 编码）。
    var normalizedJSONData: Data = Data()

    // 双图提示词哈希（spec 第 7 节：同版本可复现）。
    var cocktailPromptHash: String = ""
    var planetPromptHash: String = ""

    // 双图状态。
    var cocktailStatusRawValue: String = ImageSlotStatus.notStarted.rawValue
    var planetStatusRawValue: String = ImageSlotStatus.notStarted.rawValue

    /// 返回的实际像素尺寸（如 "1728x2160"）。
    var cocktailPixelSize: String = ""
    var planetPixelSize: String = ""

    var errorMessage: String = ""
    var isDemoFallback: Bool = false

    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(
        generationID: UUID = UUID(),
        entryID: UUID,
        status: GenerationStatus = .draft,
        textModelID: String,
        imageModelID: String,
        createdAt: Date = .now
    ) {
        self.generationID = generationID
        self.entryID = entryID
        self.statusRawValue = status.rawValue
        self.textModelID = textModelID
        self.imageModelID = imageModelID
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    // MARK: - 计算属性

    var status: GenerationStatus {
        get { GenerationStatus(rawValue: statusRawValue) ?? .draft }
        set { statusRawValue = newValue.rawValue; updatedAt = .now }
    }

    var cocktailStatus: ImageSlotStatus {
        get { ImageSlotStatus(rawValue: cocktailStatusRawValue) ?? .notStarted }
        set { cocktailStatusRawValue = newValue.rawValue; updatedAt = .now }
    }

    var planetStatus: ImageSlotStatus {
        get { ImageSlotStatus(rawValue: planetStatusRawValue) ?? .notStarted }
        set { planetStatusRawValue = newValue.rawValue; updatedAt = .now }
    }

    /// 解码规范化 JSON。文件损坏返回 nil。
    var response: DayGenerationResponse? {
        guard !normalizedJSONData.isEmpty else { return nil }
        return try? JSONDecoder().decode(DayGenerationResponse.self, from: normalizedJSONData)
    }

    func setResponse(_ response: DayGenerationResponse) {
        normalizedJSONData = (try? JSONEncoder().encode(response)) ?? Data()
        schemaVersion = response.schemaVersion
        updatedAt = .now
    }

    /// 两张图都已保存。
    var bothImagesSaved: Bool {
        cocktailStatus == .saved && planetStatus == .saved
    }

    /// 至少一张已保存（partiallyReady 判定辅助）。
    var anyImageSaved: Bool {
        cocktailStatus == .saved || planetStatus == .saved
    }
}
