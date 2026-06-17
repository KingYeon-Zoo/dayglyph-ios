import Testing
@testable import DayGlyph

struct CocktailResultCopyTests {
    @Test func lowConfidenceUsesCarefulTitle() {
        #expect(CocktailResultCopy.title(for: .low) == "今天可能由这些感受组成")
    }

    @Test func confidentResultsUseCocktailTitle() {
        #expect(CocktailResultCopy.title(for: .medium) == "今日情绪鸡尾酒")
        #expect(CocktailResultCopy.title(for: .high) == "今日情绪鸡尾酒")
    }

    @Test func favoriteButtonReflectsEntryState() {
        #expect(CocktailResultCopy.favoriteButtonTitle(isFavorite: false) == "收藏配方")
        #expect(CocktailResultCopy.favoriteButtonTitle(isFavorite: true) == "已收藏")
    }
}
