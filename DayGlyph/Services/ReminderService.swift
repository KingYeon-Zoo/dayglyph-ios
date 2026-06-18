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
        await schedule(NotificationScheduler.dailyPlan(hour: hour, minute: minute))
    }

    func cancelDailyReminder() {
        cancel(identifiers: [NotificationScheduler.dailyIdentifier])
    }

    func scheduleActionEcho(id: UUID, title: String, date: Date) async {
        await schedule(NotificationScheduler.actionEchoPlan(id: id, title: title, date: date))
    }

    func scheduleTimeLetter(id: UUID, date: Date) async {
        await schedule(NotificationScheduler.timeLetterPlan(id: id, date: date))
    }

    func cancel(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func schedule(_ plan: NotificationPlan) async {
        cancel(identifiers: [plan.identifier])
        let content = UNMutableNotificationContent()
        content.title = plan.title
        content.body = plan.body
        content.sound = .default

        let trigger: UNNotificationTrigger
        if let date = plan.date {
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
                repeats: plan.repeats
            )
        } else {
            var components = DateComponents()
            components.hour = plan.hour
            components.minute = plan.minute
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: plan.repeats)
        }
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: plan.identifier, content: content, trigger: trigger)
        )
    }
}
