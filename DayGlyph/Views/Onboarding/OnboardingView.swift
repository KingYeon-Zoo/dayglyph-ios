import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var page: OnboardingPage = .value
    @State private var dailyReminder = false
    @AppStorage("prefersIndoorActions") private var prefersIndoorActions = false
    @AppStorage("prefersSoloActions") private var prefersSoloActions = false
    @AppStorage("avoidsStrongStimulation") private var avoidsStrongStimulation = false
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @StateObject private var reminderService = ReminderService()

    var body: some View {
        ZStack {
            DayGlyphBackground()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("跳过") { onComplete() }
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                        .accessibilityIdentifier("onboarding.skip")
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(OnboardingPage.allCases) { item in
                        pageView(item).tag(item)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(page.primaryActionTitle) { advance() }
                    .buttonStyle(.glassProminent)
                    .tint(DayGlyphStyle.today)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
                    .accessibilityIdentifier("onboarding.primary")
            }
        }
        .interactiveDismissDisabled()
    }

    private func pageView(_ item: OnboardingPage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Image(systemName: symbol(for: item))
                    .font(.system(size: 70, weight: .semibold))
                    .foregroundStyle(color(for: item))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
                    .accessibilityHidden(true)
                Text(item.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(item.points, id: \.self) { point in
                        Label(point, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(DayGlyphStyle.textPrimary)
                    }
                }
                .padding(20)
                .paperCard()

                if item == .preferences { preferenceControls }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 80)
        }
    }

    private var preferenceControls: some View {
        VStack(spacing: 14) {
            Toggle("开启每日记录提醒", isOn: $dailyReminder)
            Toggle("优先室内行动", isOn: $prefersIndoorActions)
            Toggle("优先独处行动", isOn: $prefersSoloActions)
            Toggle("避免强刺激行动", isOn: $avoidsStrongStimulation)
        }
        .tint(DayGlyphStyle.mine)
        .padding(20)
        .paperCard()
    }

    private func advance() {
        guard page != .preferences else {
            if dailyReminder {
                Task {
                    let granted = await reminderService.requestAuthorization()
                    reminderEnabled = granted
                    if granted { await reminderService.scheduleDailyReminder(hour: 21, minute: 30) }
                    onComplete()
                }
            } else {
                onComplete()
            }
            return
        }
        withAnimation(.easeInOut) {
            page = OnboardingPage(rawValue: page.rawValue + 1) ?? .preferences
        }
    }

    private func symbol(for page: OnboardingPage) -> String {
        switch page {
        case .value: "sparkles"
        case .privacy: "lock.shield.fill"
        case .preferences: "slider.horizontal.3"
        }
    }

    private func color(for page: OnboardingPage) -> Color {
        switch page {
        case .value: DayGlyphStyle.today
        case .privacy: DayGlyphStyle.mine
        case .preferences: DayGlyphStyle.echo
        }
    }
}
