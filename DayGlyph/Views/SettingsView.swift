import SwiftData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 21
    @AppStorage("reminderMinute") private var reminderMinute = 30

    @StateObject private var reminderService = ReminderService()
    @State private var reminderDate = Date()

    private let appleIntelligenceStatus = AppleIntelligenceStatus.current

    var body: some View {
        Form {
            Section("Apple Intelligence") {
                Label(
                    appleIntelligenceStatus.title,
                    systemImage: appleIntelligenceStatus.symbolName
                )
                .font(.headline)

                Text(appleIntelligenceStatus.detail)
                    .foregroundStyle(DayGlyphStyle.mutedInk)

                LabeledContent("运行环境", value: AppleIntelligenceStatus.environmentTitle)

                Text(appleIntelligenceStatus.suggestion)
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.mutedInk)

                Link(
                    "查看 Apple 官方可用性说明",
                    destination: URL(string: "https://support.apple.com/zh-cn/121115")!
                )
            }

            Section("每日提醒") {
                Toggle("每日提醒", isOn: $reminderEnabled)
                    .onChange(of: reminderEnabled) {
                        handleReminderToggle()
                    }

                DatePicker("提醒时间", selection: $reminderDate, displayedComponents: .hourAndMinute)
                    .disabled(!reminderEnabled)
                    .onChange(of: reminderDate) {
                        updateReminderTime()
                    }

                Text(permissionText)
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.mutedInk)
            }

            Section("演示数据") {
                Button {
                    DemoDataSeeder.seed(into: modelContext)
                } label: {
                    Label("填充演示月", systemImage: "calendar.badge.plus")
                }

                Button(role: .destructive) {
                    DemoDataSeeder.clearAllEntries(in: modelContext)
                } label: {
                    Label("清空全部记录", systemImage: "trash")
                }
            }

            Section("隐私") {
                Text("记录与分析保存在本机。")
                    .foregroundStyle(DayGlyphStyle.mutedInk)
            }
        }
        .scrollContentBackground(.hidden)
        .listSectionSpacing(18)
        .background(DayGlyphBackground())
        .tint(DayGlyphStyle.jade)
        .navigationTitle("设置")
        .task {
            reminderDate = dateFromStoredTime()
            await reminderService.refreshAuthorizationStatus()
        }
    }

    private var permissionText: String {
        switch reminderService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            "通知已开启"
        case .denied:
            "通知已关闭，可在系统设置中开启通知"
        case .notDetermined:
            "开启后会请求通知权限"
        @unknown default:
            "通知状态未知"
        }
    }

    private func handleReminderToggle() {
        if reminderEnabled {
            Task {
                let granted = await reminderService.requestAuthorization()
                if granted {
                    updateStoredTime(from: reminderDate)
                    await reminderService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
                } else {
                    reminderEnabled = false
                }
            }
        } else {
            reminderService.cancelDailyReminder()
        }
    }

    private func updateReminderTime() {
        updateStoredTime(from: reminderDate)
        guard reminderEnabled else { return }
        Task {
            await reminderService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
        }
    }

    private func updateStoredTime(from date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        reminderHour = components.hour ?? 21
        reminderMinute = components.minute ?? 30
    }

    private func dateFromStoredTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = reminderHour
        components.minute = reminderMinute
        return Calendar.current.date(from: components) ?? .now
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
