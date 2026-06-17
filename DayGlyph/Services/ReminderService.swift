import Combine
import Foundation
import UserNotifications

@MainActor
final class ReminderService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dayglyph.daily"])

        let content = UNMutableNotificationContent()
        content.title = "今天的情绪"
        content.body = "留一句今天给自己。"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dayglyph.daily", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dayglyph.daily"])
    }
}
