import Testing
import Foundation
@testable import DayGlyph

/// 图片本地存储测试（spec 第 10 节）。
@MainActor
struct GeneratedAssetStoreTests {

    private func makeStore() -> (GeneratedAssetStore, UUID, UUID) {
        // 用临时目录隔离每次测试。
        let store = GeneratedAssetStore()
        return (store, UUID(), UUID())
    }

    @Test func savesAndLoadsImage() throws {
        let (store, entryID, generationID) = makeStore()
        defer { store.removeEntry(entryID: entryID) }

        let data = Data([0xFF, 0xD8, 0xFF, 0x00])
        try store.save(data, entryID: entryID, generationID: generationID, slot: .cocktail)

        #expect(store.exists(entryID: entryID, generationID: generationID, slot: .cocktail))
        #expect(store.load(entryID: entryID, generationID: generationID, slot: .cocktail) == data)
    }

    @Test func missingFileReturnsNilNotCrash() {
        let (store, entryID, generationID) = makeStore()
        #expect(store.load(entryID: entryID, generationID: generationID, slot: .planet) == nil)
        #expect(!store.exists(entryID: entryID, generationID: generationID, slot: .planet))
    }

    @Test func removeEntryDeletesAllGenerations() throws {
        let (store, entryID, _) = makeStore()
        let gen1 = UUID(); let gen2 = UUID()
        try store.save(Data([1]), entryID: entryID, generationID: gen1, slot: .cocktail)
        try store.save(Data([2]), entryID: entryID, generationID: gen2, slot: .planet)

        store.removeEntry(entryID: entryID)
        #expect(!store.exists(entryID: entryID, generationID: gen1, slot: .cocktail))
        #expect(!store.exists(entryID: entryID, generationID: gen2, slot: .planet))
    }

    @Test func filePathUsesJpegExtension() {
        let (store, entryID, generationID) = makeStore()
        let url = store.fileURL(entryID: entryID, generationID: generationID, slot: .cocktail)
        #expect(url.lastPathComponent == "cocktail.jpeg")
    }
}

/// 词库测试（spec 第 12 节）。
@MainActor
struct EmotionLexiconTests {

    @Test func hasEnoughTerms() {
        // 60～100 个词。
        #expect(EmotionLexicon.entries.count >= 60)
        #expect(EmotionLexicon.entries.count <= 100)
    }

    @Test func coversAllFamilies() {
        let families = Set(EmotionLexicon.entries.map(\.family))
        #expect(families.count == EmotionFamily.allCases.count)
    }

    @Test func termsAreUnique() {
        let terms = EmotionLexicon.entries.map(\.term)
        #expect(Set(terms).count == terms.count)
    }

    @Test func everyFamilyMapsToAnchor() {
        for family in EmotionFamily.allCases {
            _ = family.anchor // 不应崩溃，且类型完备。
        }
        #expect(EmotionFamily.depletion.anchor == .tired)
        #expect(EmotionFamily.anger.anchor == .angry)
    }

    @Test func vadValuesInRange() {
        for entry in EmotionLexicon.entries {
            #expect((-1...1).contains(entry.valence))
            #expect((0...1).contains(entry.arousal))
            #expect((-1...1).contains(entry.dominance))
        }
    }
}
