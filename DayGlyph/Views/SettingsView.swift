import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @Query private var entries: [DayEntry]
    @Query private var actions: [ActionInstance]
    @Query private var responses: [ActionResponse]
    @Query private var letters: [TimeLetter]
    @Query private var empathyCopies: [EmpathyCopy]

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 21
    @AppStorage("reminderMinute") private var reminderMinute = 30
    @AppStorage("echoRemindersEnabled") private var echoRemindersEnabled = false
    @AppStorage("letterRemindersEnabled") private var letterRemindersEnabled = false
    @AppStorage("prefersIndoorActions") private var prefersIndoorActions = false
    @AppStorage("prefersSoloActions") private var prefersSoloActions = false
    @AppStorage("avoidsStrongStimulation") private var avoidsStrongStimulation = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @StateObject private var reminderService = ReminderService()
    @State private var reminderDate = Date()
    @State private var showsClearConfirmation = false
    @State private var shareItem: UniverseShareItem?
    @State private var exportError: String?

    private let appleIntelligenceStatus = AppleIntelligenceStatus.current

    var body: some View {
        Form {
            Section("记录提醒") {
                Toggle("每日记录提醒", isOn: $reminderEnabled)
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

                if reminderService.authorizationStatus == .denied {
                    Button("前往系统通知设置") {
                        openURL(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }
            }

            Section("行动与来信") {
                Toggle("行动回声提醒", isOn: $echoRemindersEnabled)
                    .onChange(of: echoRemindersEnabled) { handleEchoReminderToggle() }
                Toggle("时间来信提醒", isOn: $letterRemindersEnabled)
                    .onChange(of: letterRemindersEnabled) { handleLetterReminderToggle() }
                Toggle("优先室内行动", isOn: $prefersIndoorActions)
                Toggle("优先独处行动", isOn: $prefersSoloActions)
                Toggle("避免强刺激行动", isOn: $avoidsStrongStimulation)
            }

            Section("隐私与本地数据") {
                Text("日记原文、分析结果、行动与回声默认保存在本机。公开副本前会再次征得你的确认。")
                    .foregroundStyle(DayGlyphStyle.mutedInk)

                Button {
                    exportData()
                } label: {
                    Label("导出本地记录", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showsClearConfirmation = true
                } label: {
                    Label("清空全部本地数据", systemImage: "trash")
                }
            }

            Section("演示数据") {
                Button {
                    DemoDataSeeder.seed(into: modelContext)
                    DemoDataSeeder.seedSupportData(into: modelContext)
                } label: {
                    Label("填充演示月", systemImage: "calendar.badge.plus")
                }

                Button(role: .destructive) {
                    DemoDataSeeder.clearDemoEntries(in: modelContext)
                    DemoDataSeeder.clearDemoSupportData(in: modelContext)
                } label: {
                    Label("仅清除演示记录", systemImage: "trash.slash")
                }
            }

            Section("使用帮助") {
                Button("重新查看新手引导") {
                    hasCompletedOnboarding = false
                }
            }

            Section("设备端分析状态") {
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

        }
        .scrollContentBackground(.hidden)
        .listSectionSpacing(18)
        .background(DayGlyphBackground())
        .tint(DayGlyphStyle.mine)
        .navigationTitle("设置与隐私")
        .task {
            reminderDate = dateFromStoredTime()
            await reminderService.refreshAuthorizationStatus()
        }
        .confirmationDialog("清空全部本地数据？", isPresented: $showsClearConfirmation, titleVisibility: .visible) {
            Button("永久清空", role: .destructive) {
                DemoDataSeeder.clearAllLocalData(
                    entries: entries,
                    actions: actions,
                    responses: responses,
                    letters: letters,
                    empathyCopies: empathyCopies,
                    in: modelContext
                )
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("记录、行动、回声、时间来信和共情海副本都会删除，且无法恢复。")
        }
        .sheet(item: $shareItem) { item in
            UniverseActivityView(items: [item.url])
        }
        .alert("暂时无法导出", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(exportError ?? "请稍后再试。")
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

    private func cancelDisabledNotifications() {
        let identifiers = NotificationScheduler.identifiersToCancel(
            dailyEnabled: reminderEnabled,
            echoEnabled: echoRemindersEnabled,
            lettersEnabled: letterRemindersEnabled,
            actionIDs: actions.map(\.id),
            letterIDs: letters.map(\.id)
        )
        reminderService.cancel(identifiers: identifiers)
    }

    private func handleEchoReminderToggle() {
        guard echoRemindersEnabled else {
            cancelDisabledNotifications()
            return
        }
        Task {
            let granted = await reminderService.requestAuthorization()
            guard granted else {
                echoRemindersEnabled = false
                return
            }
            for action in actions where action.state == .completed {
                guard let date = action.followUpAt, date > .now else { continue }
                await reminderService.scheduleActionEcho(id: action.id, title: action.actionTitle, date: date)
            }
        }
    }

    private func handleLetterReminderToggle() {
        guard letterRemindersEnabled else {
            cancelDisabledNotifications()
            return
        }
        Task {
            let granted = await reminderService.requestAuthorization()
            guard granted else {
                letterRemindersEnabled = false
                return
            }
            for letter in letters where letter.state == .waiting && letter.notBefore > .now {
                await reminderService.scheduleTimeLetter(id: letter.id, date: letter.notBefore)
            }
        }
    }

    private func exportData() {
        do {
            shareItem = UniverseShareItem(url: try LocalDataExporter.export(entries: entries))
        } catch {
            exportError = "无法生成本地导出文件，请稍后再试。"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
