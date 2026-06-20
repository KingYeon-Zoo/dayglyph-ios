import SwiftUI

/// 当日分享卡渲染器（contextual personalization spec 5.4、§8 ShareCardRenderer）。
///
/// 由 SwiftUI 渲染静态卡片，AI 只提供标题、短句与受控版式枚举，不生成带文字图片。
/// 隐私按构造保证（spec 5.4）：只渲染白名单内容——当日图片、当日名称、一句短句、
/// 低精度日期与品牌标识；绝不渲染日记原文、识别依据、置信度、风险信息或行动回声。
struct ShareCardRenderer: View {
    var spec: ShareCardSpec
    var cocktailImage: Data?
    var planetImage: Data?
    var date: Date = .now

    /// 卡片渲染尺寸（点）。固定竖向比例，导出后用于系统分享。
    static let canvasSize = CGSize(width: 320, height: 460)

    private var focusImage: Data? {
        // visual_focus 已由校验限定为 cocktail / planet。
        let primary = spec.visualFocus == "planet" ? planetImage : cocktailImage
        return primary ?? cocktailImage ?? planetImage
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 18) {
            visual
            VStack(alignment: alignment, spacing: 8) {
                Text(spec.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(textAlignment)
                Text(spec.caption)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(textAlignment)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: frameAlignment)

            Spacer(minLength: 0)

            HStack {
                Text("DayGlyph")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                // 低精度日期：只到年月（spec 5.4：日期的低精度显示）。
                Text(date, format: .dateTime.year().month())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
        .padding(26)
        .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
        .background(
            LinearGradient(
                colors: [DayGlyphStyle.universeBackground, Color(red: 0.16, green: 0.12, blue: 0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    @ViewBuilder
    private var visual: some View {
        let height: CGFloat = spec.layoutVariant == "minimal" ? 120 : 230
        if let data = focusImage, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            // 图片缺失时用品牌占位（不阻塞分享）。
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.08))
                .frame(height: height)
                .overlay {
                    Image(systemName: spec.visualFocus == "planet" ? "circle.dotted" : "wineglass")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                }
        }
    }

    // MARK: - 版式（受控枚举 → 布局参数）

    private var alignment: HorizontalAlignment {
        spec.layoutVariant == "minimal" ? .leading : .center
    }

    private var frameAlignment: Alignment {
        spec.layoutVariant == "minimal" ? .leading : .center
    }

    private var textAlignment: TextAlignment {
        spec.layoutVariant == "minimal" ? .leading : .center
    }

    /// VoiceOver 描述（spec 12.2：可读取标题、短句与主视觉描述）。
    var accessibilityDescription: String {
        let focus = spec.visualFocus == "planet" ? "日星球" : "情绪鸡尾酒"
        return "分享卡，标题\(spec.title)，\(spec.caption)，主视觉是当日\(focus)。"
    }
}
