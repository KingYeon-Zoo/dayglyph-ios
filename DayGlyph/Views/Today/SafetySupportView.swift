import SwiftUI

/// 高风险安全支持页（spec 第 9 节）。
///
/// 当记录明确包含自伤、自杀或即时危险时展示：暂停艺术生图，提供安全支持、
/// 紧急联系方式与寻求现实帮助的入口。不诊断、不浪漫化、不绝对化。
struct SafetySupportView: View {
    var rationale: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(DayGlyphStyle.today)
                Text("先照顾好此刻的你")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DayGlyphStyle.textPrimary)
            }

            Text("你的记录已经安全保存。此刻看起来很不容易，你并不孤单，也值得被认真对待。如果有伤害自己的念头，请优先和能立刻帮助你的人联系。")
                .font(.body)
                .foregroundStyle(DayGlyphStyle.textPrimary)
                .lineSpacing(5)

            VStack(alignment: .leading, spacing: 12) {
                contactRow(
                    title: "全国心理援助热线",
                    detail: "12356",
                    systemImage: "phone.fill",
                    url: URL(string: "tel://12356")
                )
                contactRow(
                    title: "北京心理危机研究与干预中心",
                    detail: "010-82951332",
                    systemImage: "phone.fill",
                    url: URL(string: "tel://01082951332")
                )
                contactRow(
                    title: "紧急情况请拨打",
                    detail: "120 / 110",
                    systemImage: "cross.case.fill",
                    url: URL(string: "tel://120")
                )
            }
            .padding(16)
            .background(DayGlyphStyle.todaySoft.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("如果身边有信任的家人或朋友，现在就告诉他们你的感受，也是非常好的一步。")
                .font(.footnote)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineSpacing(4)
        }
        .padding(22)
        .paperCard(cornerRadius: DayGlyphStyle.heroRadius)
        .accessibilityElement(children: .contain)
    }

    private func contactRow(title: String, detail: String, systemImage: String, url: URL?) -> some View {
        Button {
            if let url { UIApplication.shared.open(url) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(DayGlyphStyle.today)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DayGlyphStyle.textPrimary)
                    Text(detail)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(DayGlyphStyle.today)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DayGlyphStyle.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)，\(detail)，点击拨打")
    }
}

#Preview {
    SafetySupportView(rationale: nil)
        .padding()
        .background(DayGlyphBackground())
}
