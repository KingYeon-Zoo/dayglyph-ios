import Foundation

/// 豆包网络层错误（文本与生图共用）。
enum DoubaoClientError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidResponse
    case httpStatus(Int, String)
    case rateLimited(retryAfter: TimeInterval?)
    case decodingFailed(String)
    case emptyContent
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "未配置豆包 API Key。"
        case .invalidResponse: "服务端返回了无法解析的响应。"
        case .httpStatus(let code, let message): "请求失败（HTTP \(code)）：\(message)"
        case .rateLimited(let after):
            if let after { "请求过于频繁，请约 \(Int(after)) 秒后重试。" }
            else { "请求过于频繁，请稍后重试。" }
        case .decodingFailed(let detail): "结果解析失败：\(detail)"
        case .emptyContent: "服务端返回了空内容。"
        case .cancelled: "请求已取消。"
        }
    }

    /// 是否属于可自动重试一次的瞬时错误（spec 第 8 节：网络瞬断、超时、5xx）。
    var isTransient: Bool {
        switch self {
        case .invalidResponse, .emptyContent: true
        case .httpStatus(let code, _): code >= 500
        default: false
        }
    }
}
