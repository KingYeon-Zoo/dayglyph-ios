import Testing
@testable import DayGlyph

struct MicroActionCatalogTests {
    @Test func recommendationsAreStableAndReturnThreeCandidates() {
        let first = MicroActionCatalog.recommendations(
            for: .anxious,
            disabledCategories: [],
            seed: 42
        )
        let second = MicroActionCatalog.recommendations(
            for: .anxious,
            disabledCategories: [],
            seed: 42
        )

        #expect(first == second)
        #expect(first.count == 3)
        #expect(Set(first.map(\.id)).count == 3)
    }

    @Test func explicitDisabledCategoriesNeverReturn() {
        let disabled: Set<MicroActionCategory> = [.social, .outdoors]

        let candidates = MicroActionCatalog.recommendations(
            for: .lonely,
            disabledCategories: disabled,
            seed: 7
        )

        #expect(candidates.isEmpty == false)
        #expect(candidates.allSatisfy { disabled.contains($0.category) == false })
    }

    @Test func easierReplacementOnlyChangesRequestedCard() throws {
        let original = MicroActionCatalog.recommendations(
            for: .tired,
            disabledCategories: [],
            seed: 18
        )
        let current = try #require(original.first)
        let replacement = try #require(
            MicroActionCatalog.easierReplacement(
                for: current,
                anchor: .tired,
                excluding: Set(original.map(\.id)),
                disabledCategories: [],
                seed: 18
            )
        )
        var updated = original
        updated[0] = replacement

        #expect(updated[0].id != original[0].id)
        #expect(updated[1] == original[1])
        #expect(updated[2] == original[2])
        #expect(replacement.difficultyBand <= current.difficultyBand)
    }
}
