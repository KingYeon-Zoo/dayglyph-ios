import Foundation

/// 豆包接口集中配置。
///
/// 所有字段均来自 2026-06-20 真实接口探针验证结果，不靠产品展示名称猜测：
/// - 文本：`POST /api/v3/chat/completions`，`response_format: {"type":"json_object"}`，
///   `choices[0].message.content` 承载 JSON 字符串；Seed 2.0 Lite 为推理模型，单次约 7 秒。
/// - 生图：`POST /api/v3/images/generations`，size 像素总数必须 ≥ 3686400，
///   返回 `data[].url`（JPEG，TOS 临时地址，X-Tos-Expires=86400 即 24 小时），单图约 20 秒。
nonisolated struct AIConfiguration: Sendable {
    var baseURL: URL
    var apiKey: String
    var textModelID: String
    var imageModelID: String

    /// 文本请求超时。Seed 2.0 Lite 含推理，实测约 7s，留足余量。
    var textTimeout: TimeInterval
    /// 生图请求超时。Seedream 单图实测约 20s。
    var imageTimeout: TimeInterval
    /// 图片下载超时。实测 <0.5s。
    var downloadTimeout: TimeInterval

    /// 鸡尾酒主视觉尺寸（4:5）。1728×2160 = 3,732,480 像素，满足最低像素约束。
    var cocktailSize: String
    /// 日星球主视觉尺寸（1:1）。2048×2048 = 4,194,304 像素。
    var planetSize: String

    static let chatCompletionsPath = "/chat/completions"
    static let imageGenerationsPath = "/images/generations"

    /// Seedream 最低像素约束（实测错误信息：image size must be at least 3686400 pixels）。
    static let minimumImagePixels = 3_686_400

    static let demo = AIConfiguration(
        baseURL: URL(string: "https://ark.cn-beijing.volces.com/api/v3")!,
        apiKey: AISecrets.arkAPIKey,
        textModelID: "doubao-seed-2-0-lite-260428",
        imageModelID: "doubao-seedream-5-0-260128",
        textTimeout: 60,
        imageTimeout: 90,
        downloadTimeout: 30,
        cocktailSize: "1728x2160",
        planetSize: "2048x2048"
    )
    var hasValidAPIKey: Bool {
        !apiKey.isEmpty && !apiKey.hasPrefix("PUT_YOUR_")
    }
}
