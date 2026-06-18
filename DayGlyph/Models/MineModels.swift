import Foundation

nonisolated struct EmotionAchievement: Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var symbol: String
    var progress: Int
    var target: Int
    var isUnlocked: Bool { progress >= target }
}
