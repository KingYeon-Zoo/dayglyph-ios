import Foundation
import SwiftData

/// AI 生成版本记录仓储（spec 模块边界 GenerationRepository）。
///
/// 负责 `AIGenerationRecord` 的写入、查询与删除；删除时连带清理本地图片目录。
/// 重新生成保留旧版本（spec 决策 10），按 createdAt 倒序即版本历史。
@MainActor
struct GenerationRepository {
    let context: ModelContext
    let assetStore: GeneratedAssetStore

    init(context: ModelContext, assetStore: GeneratedAssetStore = GeneratedAssetStore()) {
        self.context = context
        self.assetStore = assetStore
    }

    @discardableResult
    func create(entryID: UUID, configuration: AIConfiguration) throws -> AIGenerationRecord {
        let record = AIGenerationRecord(
            entryID: entryID,
            status: .draft,
            textModelID: configuration.textModelID,
            imageModelID: configuration.imageModelID
        )
        context.insert(record)
        try context.save()
        return record
    }

    func save() throws {
        try context.save()
    }

    /// 某条 entry 的全部生成版本，按时间倒序（最新在前）。
    func records(for entryID: UUID) throws -> [AIGenerationRecord] {
        let descriptor = FetchDescriptor<AIGenerationRecord>(
            predicate: #Predicate { $0.entryID == entryID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// 某条 entry 的最新生成版本。
    func latestRecord(for entryID: UUID) throws -> AIGenerationRecord? {
        try records(for: entryID).first
    }

    /// 所有未完成、可恢复的记录（spec 第 8 节：App 重启后补生成未保存的图片）。
    func resumableRecords() throws -> [AIGenerationRecord] {
        let descriptor = FetchDescriptor<AIGenerationRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = try context.fetch(descriptor)
        return all.filter { record in
            switch record.status {
            case .contentReady, .generatingImages, .partiallyReady, .retryableFailure:
                return true
            default:
                return false
            }
        }
    }

    /// 删除单个生成版本（记录 + 图片目录）。
    func delete(_ record: AIGenerationRecord) throws {
        assetStore.removeGeneration(entryID: record.entryID, generationID: record.generationID)
        context.delete(record)
        try context.save()
    }

    /// 删除某条 entry 的全部生成版本与图片目录（spec 第 10 节）。
    func deleteAll(for entryID: UUID) throws {
        let all = try records(for: entryID)
        for record in all {
            context.delete(record)
        }
        assetStore.removeEntry(entryID: entryID)
        try context.save()
    }
}
