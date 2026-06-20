import SwiftUI

struct UniverseDaySummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var day: UniverseDaySummary
    var entry: DayEntry?
    var previousAction: (() -> Void)?
    var nextAction: (() -> Void)?

    private var generatedPlanetImage: UIImage? {
        guard let entry else { return nil }
        return GeneratedImageProvider(context: modelContext).images(for: entry).planet
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    UniversePlanetView(
                        visual: MonthlyPlanetVisual(
                            seed: day.planet.seed,
                            baseHue: day.planet.baseHue,
                            secondaryHue: day.planet.secondaryHue,
                            textureComplexity: day.planet.textureComplexity,
                            glow: day.planet.glow,
                            sizeScale: 0.62,
                            rings: day.planet.rings,
                            satellites: day.planet.satellites,
                            rotationSpeed: day.planet.rotationSpeed,
                            recordDots: []
                        ),
                        size: 180,
                        generatedImage: generatedPlanetImage
                    )
                    .frame(height: 160)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(day.date, format: .dateTime.year().month().day().weekday())
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.68))
                        Text(day.cocktailName)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("\(day.weatherType) · \(day.keywords.joined(separator: " · "))")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    HStack(spacing: 12) {
                        navigationButton(title: "上一条", systemImage: "chevron.left", action: previousAction)
                        navigationButton(title: "下一条", systemImage: "chevron.right", action: nextAction)
                    }

                    if let entry {
                        NavigationLink {
                            EntryDetailView(entry: entry)
                        } label: {
                            Label("查看完整记录", systemImage: "arrow.up.right")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(DayGlyphStyle.universe)
                    } else {
                        Text("这条记录已经不存在，摘要会在关闭后同步更新。")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(20)
            }
            .background(DayGlyphStyle.universeBackground.ignoresSafeArea())
            .navigationTitle("日期摘要")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(330), .large])
        .presentationDragIndicator(.visible)
    }

    private func navigationButton(
        title: String,
        systemImage: String,
        action: (() -> Void)?
    ) -> some View {
        Button {
            action?()
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glass)
        .disabled(action == nil)
    }
}
