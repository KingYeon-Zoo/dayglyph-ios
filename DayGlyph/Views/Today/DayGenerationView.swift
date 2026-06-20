import SwiftData
import SwiftUI

/// AI 生成与结果页（spec 第 8、11 节）。
///
/// 逐步展示：文本完成后立即显示情绪、寄语、天气与微行动；两张毛玻璃卡片独立揭示，
/// 第一张完成后不等待第二张。高风险时只展示安全支持。不展示虚假百分比。
struct DayGenerationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var text: String
    var onComplete: (DayEntry?) -> Void

    @State private var viewModel: GenerationProgressViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView().tint(DayGlyphStyle.today)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 96)
        }
        .background(DayGlyphBackground())
        .navigationTitle("正在调制")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard viewModel == nil else { return }
            let vm = GenerationProgressViewModel(text: text, context: modelContext)
            viewModel = vm
            vm.start()
        }
        .onChange(of: viewModel?.contentReady ?? false) { _, ready in
            if ready { viewModel?.persistEntryIfReady() }
        }
    }

    @ViewBuilder
    private func content(_ vm: GenerationProgressViewModel) -> some View {
        // 阶段标题。
        phaseHeader(vm)

        if vm.isBlockedBySafety {
            SafetySupportView(rationale: vm.orchestrator.response?.safety.rationale)
            Button("返回") { dismiss() }
                .buttonStyle(.glass)
        } else if let response = vm.orchestrator.response {
            // 文本就绪：情绪先行展示。
            EmotionDetailSection(payload: response.emotionAnalysis)

            // 结果叙事标题（spec 5.2，缺失则跳过，不阻塞）。
            if let narrative = vm.resultNarrative {
                narrativeCard(narrative)
            }

            // 双图独立揭示，命名优先用结果叙事。
            FrostedImageCard(
                title: vm.cocktailDisplayName,
                aspectRatio: 4.0 / 5.0,
                status: vm.orchestrator.cocktailStatus,
                image: vm.orchestrator.cocktailImage,
                accessibilityDescription: cocktailA11y(response),
                onRetry: { vm.retryCocktail() }
            )

            FrostedImageCard(
                title: vm.planetDisplayName,
                aspectRatio: 1.0,
                status: vm.orchestrator.planetStatus,
                image: vm.orchestrator.planetImage,
                accessibilityDescription: planetA11y(response),
                onRetry: { vm.retryPlanet() }
            )

            // 支持内容。
            weatherCard(response.emotionalWeather)
            messageCard(response.dailyMessage)

            // 三档微行动（spec 5.3）：合法则展示三档，否则回退单档 AI 行动卡。
            if let options = vm.actionOptions {
                AIActionOptionsSection(options: options, entryID: vm.entry?.entryID)
            } else {
                actionCard(response.dailyAction)
            }

            if vm.orchestrator.status == .completed || vm.orchestrator.status == .partiallyReady {
                // 分享卡入口（spec 5.4）：用户主动点击才渲染与分享。
                ShareCardSection(
                    spec: vm.resolvedShareCard,
                    cocktailImage: vm.orchestrator.cocktailImage,
                    planetImage: vm.orchestrator.planetImage
                )

                Button("完成") { onComplete(vm.entry) }
                    .buttonStyle(.glassProminent)
                    .tint(DayGlyphStyle.today)
                    .frame(maxWidth: .infinity)
            }
        } else if vm.isFailed {
            failureCard(vm)
        } else {
            analyzingCard(vm)
        }
    }

    // MARK: - 子视图

    private func phaseHeader(_ vm: GenerationProgressViewModel) -> some View {
        Text(vm.phaseTitle)
            .font(.title3.weight(.semibold))
            .foregroundStyle(DayGlyphStyle.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.updatesFrequently)
    }

    private func analyzingCard(_ vm: GenerationProgressViewModel) -> some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large).tint(DayGlyphStyle.today)
            Text("正在把今天的文字调成一份温和的情绪配方。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func failureCard(_ vm: GenerationProgressViewModel) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(DayGlyphStyle.danger)
            Text(vm.errorMessage ?? "生成遇到问题，请稍后再试。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .multilineTextAlignment(.center)
            HStack {
                Button("返回修改") { dismiss() }
                    .buttonStyle(.glass)
                Button("重试") {
                    viewModel?.start()
                }
                .buttonStyle(.glassProminent)
                .tint(DayGlyphStyle.today)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func narrativeCard(_ narrative: ResultNarrativeSpec) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(narrative.headline)
                .font(.title3.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if !narrative.explanation.isEmpty {
                Text(narrative.explanation)
                    .font(.subheadline)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private func weatherCard(_ weather: EmotionalWeatherSpec) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(weather.title, systemImage: weatherSymbol(weather.symbol))
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text(weather.explanation)
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private func messageCard(_ message: DailyMessageSpec) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.text)
                .font(.body)
                .foregroundStyle(DayGlyphStyle.textPrimary)
                .lineSpacing(5)
            Text("— \(message.attribution)")
                .font(.caption)
                .foregroundStyle(DayGlyphStyle.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    private func actionCard(_ action: DailyActionSpec) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(action.title, systemImage: "leaf")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text(action.instruction)
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textPrimary)
                .lineSpacing(4)
            HStack(spacing: 12) {
                Label("\(action.durationMinutes) 分钟", systemImage: "clock")
                Label(action.difficulty == "easy" ? "轻松" : "适中", systemImage: "dial.low")
            }
            .font(.caption)
            .foregroundStyle(DayGlyphStyle.textSecondary)
            if !action.reason.isEmpty {
                Text(action.reason)
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
    }

    // MARK: - 工具

    private func cocktailA11y(_ r: DayGenerationResponse) -> String {
        let symbols = r.sharedVisualDirection.symbols.prefix(3).joined(separator: "、")
        return "\(r.cocktail.description) 氛围\(r.sharedVisualDirection.motionImpression)。\(symbols)"
    }

    private func planetA11y(_ r: DayGenerationResponse) -> String {
        let symbols = r.sharedVisualDirection.symbols.prefix(3).joined(separator: "、")
        return "\(r.planet.description) 氛围\(r.sharedVisualDirection.motionImpression)。\(symbols)"
    }

    private func weatherSymbol(_ token: String) -> String {
        switch token {
        case "clear": "sun.max"
        case "partly_cloudy": "cloud.sun"
        case "cloudy": "cloud"
        case "drizzle": "cloud.drizzle"
        case "rain": "cloud.rain"
        case "fog": "cloud.fog"
        case "breeze": "wind"
        default: "cloud.sun"
        }
    }
}
