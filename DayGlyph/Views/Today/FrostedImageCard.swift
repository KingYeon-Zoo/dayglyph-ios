import SwiftUI

/// 固定尺寸毛玻璃图片卡片（spec 第 8、11 节）。
///
/// 生成中显示毛玻璃骨架与阶段文案；完成后由模糊过渡为清晰图片；
/// 失败显示品牌占位图与单独重试。开启减少动态时用静态渐变，不做模糊动画。
/// VoiceOver 读取图片名称、氛围与关键视觉元素。
struct FrostedImageCard: View {
    var title: String
    var aspectRatio: CGFloat        // 宽/高，鸡尾酒 4:5 = 0.8，星球 1:1 = 1
    var status: ImageSlotStatus
    var image: Data?
    var accessibilityDescription: String
    var onRetry: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)

            ZStack {
                RoundedRectangle(cornerRadius: DayGlyphStyle.heroRadius, style: .continuous)
                    .fill(DayGlyphStyle.todaySoft)

                content
            }
            .aspectRatio(aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: DayGlyphStyle.heroRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DayGlyphStyle.heroRadius, style: .continuous)
                    .stroke(DayGlyphStyle.divider, lineWidth: 1)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)。\(accessibilityStatusText)")
    }

    @ViewBuilder
    private var content: some View {
        switch status {
        case .saved:
            if let image, let uiImage = UIImage(data: image) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 1.02)))
            } else {
                missingPlaceholder
            }
        case .failed:
            failurePlaceholder
        case .notStarted, .rendering, .downloading:
            generatingPlaceholder
        }
    }

    private var generatingPlaceholder: some View {
        VStack(spacing: 14) {
            if reduceMotion {
                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(DayGlyphStyle.today)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(DayGlyphStyle.today)
            }
            Text(status == .downloading ? "正在保存画面" : "正在生成画面")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private var failurePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(DayGlyphStyle.textSecondary)
            Text("这张画面没能生成")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
            Button(action: onRetry) {
                Label("重试这张", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var missingPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 32))
                .foregroundStyle(DayGlyphStyle.textSecondary)
            Text("图片暂时丢失，可重新生成")
                .font(.footnote)
                .foregroundStyle(DayGlyphStyle.textSecondary)
            Button("重新生成", action: onRetry)
                .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var accessibilityStatusText: String {
        switch status {
        case .saved: accessibilityDescription
        case .failed: "生成失败，可重试。"
        case .downloading: "正在保存。"
        default: "正在生成。"
        }
    }
}
