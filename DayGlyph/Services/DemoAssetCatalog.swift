import Foundation

/// 演示产物目录（只读）。
///
/// 读取打包进 App bundle 的演示资源：每套包含一份经 `GenerationSchemaValidator` 校验的
/// `DayGenerationResponse`（manifest）与两张真实豆包出图（鸡尾酒 / 星球 JPEG）。
///
/// 产物由本机一次性脚本生成后扁平化为平铺命名，规避文件系统同步组对同名文件的冲突：
///   demo-index.json（[{slug, text}]）
///   demo-NN.json / demo-NN-cocktail.jpeg / demo-NN-planet.jpeg
///
/// 任一套缺文件或 manifest 校验失败时跳过该套，不影响其余套与 App 启动。
nonisolated struct DemoAssetCatalog {

    struct Entry: Sendable {
        var slug: String
        /// 该套对应的原始记录文本（写入 DayEntry.text）。
        var text: String
        /// 已校验的统一生成响应。
        var response: DayGenerationResponse
        /// 鸡尾酒真图 bundle URL。
        var cocktailURL: URL
        /// 星球真图 bundle URL。
        var planetURL: URL
    }

    private struct IndexItem: Decodable {
        var slug: String
        var text: String
    }

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// 读取并校验全部演示套；顺序与 demo-index.json 一致。
    func load() -> [Entry] {
        guard let indexURL = bundle.url(forResource: "demo-index", withExtension: "json"),
              let indexData = try? Data(contentsOf: indexURL),
              let items = try? JSONDecoder().decode([IndexItem].self, from: indexData)
        else {
            return []
        }

        return items.compactMap { item in
            guard
                let manifestURL = bundle.url(forResource: item.slug, withExtension: "json"),
                let manifestData = try? Data(contentsOf: manifestURL),
                let response = try? JSONDecoder().decode(DayGenerationResponse.self, from: manifestData),
                (try? GenerationSchemaValidator.validate(response)) != nil,
                let cocktailURL = bundle.url(forResource: "\(item.slug)-cocktail", withExtension: "jpeg"),
                let planetURL = bundle.url(forResource: "\(item.slug)-planet", withExtension: "jpeg")
            else {
                return nil
            }
            return Entry(
                slug: item.slug,
                text: item.text,
                response: response,
                cocktailURL: cocktailURL,
                planetURL: planetURL
            )
        }
    }
}
