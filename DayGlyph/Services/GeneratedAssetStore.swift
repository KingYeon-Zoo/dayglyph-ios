import Foundation

/// 生成图片的本地文件存储（spec 第 10 节）。
///
/// 路径：Application Support/DayGlyphGenerated/{entryID}/{generationID}/{cocktail|planet}.jpeg
/// （注：探针确认 Seedream 返回 JPEG，非 spec 初稿写的 webp）。
///
/// 约定：
/// - 原子写入（.atomic）。
/// - 图片不存入 SwiftData，只存路径。
/// - 删除记录时删除整个 generation 目录。
/// - 图片丢失时返回 nil，由上层标记为可重新生成，不崩溃。
nonisolated struct GeneratedAssetStore {
    enum Slot: String, Sendable {
        case cocktail
        case planet

        var fileName: String { "\(rawValue).jpeg" }
    }

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// 生成资产根目录：Application Support/DayGlyphGenerated/
    var rootDirectory: URL {
        let base = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("DayGlyphGenerated", isDirectory: true)
    }

    func directory(entryID: UUID, generationID: UUID) -> URL {
        rootDirectory
            .appendingPathComponent(entryID.uuidString, isDirectory: true)
            .appendingPathComponent(generationID.uuidString, isDirectory: true)
    }

    func fileURL(entryID: UUID, generationID: UUID, slot: Slot) -> URL {
        directory(entryID: entryID, generationID: generationID)
            .appendingPathComponent(slot.fileName)
    }

    /// 原子写入图片，返回最终文件 URL。
    @discardableResult
    func save(_ data: Data, entryID: UUID, generationID: UUID, slot: Slot) throws -> URL {
        let dir = directory(entryID: entryID, generationID: generationID)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = fileURL(entryID: entryID, generationID: generationID, slot: slot)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// 读取图片字节；文件丢失返回 nil（不抛错，交上层标记可重新生成）。
    func load(entryID: UUID, generationID: UUID, slot: Slot) -> Data? {
        let url = fileURL(entryID: entryID, generationID: generationID, slot: slot)
        return try? Data(contentsOf: url)
    }

    func exists(entryID: UUID, generationID: UUID, slot: Slot) -> Bool {
        fileManager.fileExists(atPath: fileURL(entryID: entryID, generationID: generationID, slot: slot).path)
    }

    /// 删除单个 generation 的目录。
    func removeGeneration(entryID: UUID, generationID: UUID) {
        try? fileManager.removeItem(at: directory(entryID: entryID, generationID: generationID))
    }

    /// 删除某条 entry 的全部生成版本目录（spec 第 10 节：删除记录时删除全部生成版本和图片目录）。
    func removeEntry(entryID: UUID) {
        let dir = rootDirectory.appendingPathComponent(entryID.uuidString, isDirectory: true)
        try? fileManager.removeItem(at: dir)
    }
}
