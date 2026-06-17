import SwiftUI

struct EchoPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("回声")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(DayGlyphStyle.textPrimary)
                    Text("做过什么，以及后来感受如何。")
                        .font(.subheadline)
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(DayGlyphStyle.echo)
                        .frame(width: 56, height: 56)
                        .background(DayGlyphStyle.echo.opacity(0.14), in: Circle())

                    Text("完成一个小行动后，这里会留下回声")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(DayGlyphStyle.textPrimary)

                    Text("回声会记录行动后的感受变化，帮你看见哪些照顾方式真正有用。")
                        .font(.body)
                        .foregroundStyle(DayGlyphStyle.textSecondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .paperCard(cornerRadius: DayGlyphStyle.heroRadius)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
        .background(DayGlyphBackground())
        .navigationTitle("回声")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EchoPlaceholderView()
}
