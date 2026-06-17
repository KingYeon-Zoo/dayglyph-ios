import SwiftData
import SwiftUI

struct MineHomePlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(DayGlyphStyle.mine)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("情绪旅人")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(DayGlyphStyle.textPrimary)
                            Text("管理你的记录偏好和本地隐私设置。")
                                .font(.subheadline)
                                .foregroundStyle(DayGlyphStyle.textSecondary)
                        }
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack {
                            Label("设置与隐私", systemImage: "gearshape")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                        }
                        .font(.headline)
                        .foregroundStyle(DayGlyphStyle.mine)
                        .frame(minHeight: 48)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(24)
                .paperCard(cornerRadius: DayGlyphStyle.heroRadius)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
        .background(DayGlyphBackground())
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("我的")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text("收藏、偏好和设置会集中在这里。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        MineHomePlaceholderView()
            .modelContainer(for: DayEntry.self, inMemory: true)
    }
}
