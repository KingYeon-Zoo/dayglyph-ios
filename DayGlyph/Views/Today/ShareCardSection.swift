import SwiftUI
import UIKit

/// 分享卡入口区（contextual personalization spec 5.4、§10）。
///
/// 两步流程（spec 5.4）：用户点击“生成分享卡”后才用 `ShareCardRenderer` + 本地图片渲染静态图片；
/// 只有再次点击系统分享按钮，才打开系统分享面板。渲染失败保留规格并允许重试，不重新调用文本模型。
struct ShareCardSection: View {
    var spec: ShareCardSpec
    var cocktailImage: Data?
    var planetImage: Data?

    @State private var renderedImage: UIImage?
    @State private var shareURL: ShareItem?
    @State private var renderFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("生成今日分享卡", systemImage: "square.and.arrow.up.on.square")
                .font(.headline)
                .foregroundStyle(DayGlyphStyle.textPrimary)
            Text("由 DayGlyph 排版生成一张只含情绪向内容的卡片，不包含日记原文。")
                .font(.subheadline)
                .foregroundStyle(DayGlyphStyle.textSecondary)
                .lineSpacing(3)

            if let renderedImage {
                Image(uiImage: renderedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .accessibilityLabel(
                        ShareCardRenderer(spec: spec, cocktailImage: cocktailImage, planetImage: planetImage)
                            .accessibilityDescription
                    )

                Button {
                    share(renderedImage)
                } label: {
                    Label("分享这张卡片", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glassProminent)
                .tint(DayGlyphStyle.today)
            } else {
                Button {
                    render()
                } label: {
                    Label("生成分享卡", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)
            }

            if renderFailed {
                Text("分享卡渲染失败，可再试一次。")
                    .font(.footnote)
                    .foregroundStyle(DayGlyphStyle.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .paperCard(cornerRadius: DayGlyphStyle.largeRadius)
        .sheet(item: $shareURL) { item in
            ShareActivityView(items: [item.url])
        }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(
            content: ShareCardRenderer(spec: spec, cocktailImage: cocktailImage, planetImage: planetImage)
        )
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else {
            renderFailed = true
            return
        }
        renderFailed = false
        renderedImage = image
    }

    private func share(_ image: UIImage) {
        // 写入临时文件，便于系统分享面板以图片形式分享。
        guard let data = image.jpegData(compressionQuality: 0.92) else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dayglyph-share-\(UUID().uuidString).jpg")
        do {
            try data.write(to: url, options: .atomic)
            shareURL = ShareItem(url: url)
        } catch {
            renderFailed = true
        }
    }
}

private struct ShareItem: Identifiable {
    var id: URL { url }
    var url: URL
}

private struct ShareActivityView: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
