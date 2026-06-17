import SwiftUI

struct UniversePlaceholderView: View {
    var body: some View {
        ZStack {
            DayGlyphStyle.universeBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        DayGlyphStyle.universe.opacity(0.82),
                                        DayGlyphStyle.today.opacity(0.28),
                                        .white.opacity(0.06)
                                    ],
                                    center: .topLeading,
                                    startRadius: 12,
                                    endRadius: 132
                                )
                            )
                            .frame(width: 196, height: 196)
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            }
                            .shadow(color: DayGlyphStyle.universe.opacity(0.42), radius: 42)

                        Circle()
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                            .frame(width: 270, height: 112)
                            .rotationEffect(.degrees(-18))
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("你的宇宙还在等待第一颗星球")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Text("当你留下第一杯心情鸡尾酒，它会在这里点亮。")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
        .navigationTitle("宇宙")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("情绪宇宙")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.white)
            Text("每一天都会慢慢组成只属于你的情绪星系。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
        }
    }
}

#Preview {
    UniversePlaceholderView()
}
