import Foundation

nonisolated struct NotificationPlan: Equatable {
    var identifier: String
    var title: String
    var body: String
    var date: Date?
    var hour: Int?
    var minute: Int?
    var repeats: Bool
}
