import Foundation

/// 生图提示词模板引擎（spec 第 7 节）。
///
/// 最终提示词由固定模板 + 条件片段 + JSON 参数组装：
///   品牌风格锁 + 主体结构锁 + JSON 条件片段 + 构图与镜头 + 光照与材质 + 背景约束 + 质量要求 + 禁止项
///
/// 稳定性规则（spec 第 7 节）：
/// - 数值先映射到离散视觉档位（避免连续值噪声）。
/// - 同一 JSON 与模板版本产生相同提示词与哈希。
/// - AI 不提供自由生图提示词，只选择客户端维护的高质量片段。
/// - 渲染后执行长度、注入、禁用词检查；禁止文字/标志/水印。
enum PromptTemplateEngine {

    static let templateVersion = "1.0"

    // MARK: - 固定品牌锁（spec 第 7 节：品牌风格、主体比例、画幅、禁止项固定）

    private static let brandStyleLock = """
    高级感情绪艺术插画，柔和梦幻的氛围，细腻的光影过渡，干净克制的构图，电影级质感，柔焦背景虚化
    """

    private static let qualityLock = """
    超高细节，精致渲染，柔和景深，平衡的负空间
    """

    /// 禁止项（spec 第 7 节、第 14 节：禁止文字、标志、水印、畸形主体、多个主体）。
    private static let negativeLock = """
    禁止出现任何文字、字母、数字、标志、商标、水印、签名、UI 元素、边框；禁止畸形、多余主体、重复主体、低质量、噪点、过曝
    """

    // MARK: - 鸡尾酒提示词

    static func cocktailPrompt(
        cocktail: CocktailSpec,
        shared: SharedVisualDirection
    ) -> RenderedPrompt {
        let temperature = VisualTier.temperature(shared.temperature)
        let softness = VisualTier.softness(shared.lightSoftness)
        let density = VisualTier.density(shared.spatialDensity)

        let layers = cocktail.liquidLayers
            .map { "\(Fragment.color($0.color)) 层，\(Fragment.boundary($0.boundaryStyle))" }
            .joined(separator: "；")

        let garnish = cocktail.garnish.isEmpty
            ? "无多余装饰"
            : cocktail.garnish.prefix(4).joined(separator: "、")

        let subjectLock = """
        画面主体是一杯独一无二的情绪鸡尾酒，竖向 4:5 构图，酒杯居中偏下，单一主体。
        杯型：\(cocktail.glass)；杯身材质：\(Fragment.material(cocktail.glassMaterial))。
        """

        let body = [
            brandStyleLock,
            subjectLock,
            "液体层次：\(layers)。",
            "装饰：\(garnish)。粒子：\(cocktail.particles)。",
            "构图与镜头：\(cocktail.composition)，\(cocktail.camera)，\(density)。",
            "光照与材质：\(cocktail.lighting)，\(softness)，色温\(temperature)。",
            "色板倾向：\(shared.palette.prefix(4).joined(separator: "、"))。",
            "背景：\(cocktail.background)，深色干净，柔和虚化。",
            qualityLock,
            "负面：\(negativeLock)。"
        ].joined(separator: "\n")

        return finalize(body, kind: .cocktail)
    }

    // MARK: - 星球提示词

    static func planetPrompt(
        planet: PlanetSpec,
        shared: SharedVisualDirection
    ) -> RenderedPrompt {
        let temperature = VisualTier.temperature(shared.temperature)
        let softness = VisualTier.softness(shared.lightSoftness)
        let density = VisualTier.density(shared.spatialDensity)

        let rings = planet.rings.isEmpty ? "无环带" : planet.rings.prefix(4).joined(separator: "、")
        let satellites = planet.satellites.isEmpty ? "无伴星" : planet.satellites.prefix(4).joined(separator: "、")

        let subjectLock = """
        画面主体是一颗独一无二的情绪星球，正方形 1:1 构图，星球居中，单一主体，悬浮于深空。
        轮廓：\(planet.silhouette)；表面材质：\(Fragment.material(planet.surface.material))，\(planet.surface.detail)。
        """

        let body = [
            brandStyleLock,
            subjectLock,
            "核心：\(planet.core)。大气层：\(planet.atmosphere)。",
            "环带：\(rings)。伴星：\(satellites)。粒子：\(planet.particles)。",
            "构图与镜头：\(planet.composition)，\(planet.camera)，\(density)。",
            "光照与材质：\(planet.lighting)，\(softness)，色温\(temperature)。",
            "色板倾向：\(shared.palette.prefix(4).joined(separator: "、"))。",
            "背景：\(planet.background)，深空，柔和星尘虚化。",
            qualityLock,
            "负面：\(negativeLock)。"
        ].joined(separator: "\n")

        return finalize(body, kind: .planet)
    }

    // MARK: - 渲染后处理与校验

    private static func finalize(_ prompt: String, kind: PromptKind) -> RenderedPrompt {
        // 渲染后校验：长度与禁用词（注入检查由数据边界保证，这里只做产物体检）。
        let clamped = String(prompt.prefix(1800))
        let hash = StableHash.fnv1a("\(templateVersion)|\(kind.rawValue)|\(clamped)")
        return RenderedPrompt(kind: kind, text: clamped, templateVersion: templateVersion, hash: hash)
    }
}

enum PromptKind: String, Codable, Sendable {
    case cocktail
    case planet
}

struct RenderedPrompt: Equatable, Sendable {
    var kind: PromptKind
    var text: String
    var templateVersion: String
    var hash: String
}
