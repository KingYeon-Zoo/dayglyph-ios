import SwiftData
import SwiftUI

/// 历史记录真实生成图片的只读提供者（修 bug：详情页此前从不读真图）。
///
/// 给定一条 `DayEntry`，查其最新 `AIGenerationRecord`，并从 `GeneratedAssetStore`
/// 读取已保存的鸡尾酒 / 星球真图。严格门控：仅当存在记录、对应 slot 为 `.saved`
/// 且文件存在时返回 `UIImage`，否则返回 nil 由调用方回退到程序化绘制。
///
/// 真实老数据（无 AIGenerationRecord）天然返回 nil，零回归。
@MainActor
struct GeneratedImageProvider {
    let context: ModelContext
    private let assetStore = GeneratedAssetStore()

    init(context: ModelContext) {
        self.context = context
    }

    /// 取某条记录的鸡尾酒 / 星球真图（任一缺失则为 nil）。
    func images(for entry: DayEntry) -> (cocktail: UIImage?, planet: UIImage?) {
        guard let record = latestRecord(for: entry.entryID) else {
            return (nil, nil)
        }
        let cocktail = image(record: record, slot: .cocktail, status: record.cocktailStatus)
        let planet = image(record: record, slot: .planet, status: record.planetStatus)
        return (cocktail, planet)
    }

    private func image(record: AIGenerationRecord, slot: GeneratedAssetStore.Slot, status: ImageSlotStatus) -> UIImage? {
        guard status == .saved else { return nil }
        guard let data = assetStore.load(entryID: record.entryID, generationID: record.generationID, slot: slot) else {
            return nil
        }
        return UIImage(data: data)
    }

    private func latestRecord(for entryID: UUID) -> AIGenerationRecord? {
        let descriptor = FetchDescriptor<AIGenerationRecord>(
            predicate: #Predicate { $0.entryID == entryID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try? context.fetch(descriptor).first
    }
}
