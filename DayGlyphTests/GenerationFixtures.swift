import Foundation
@testable import DayGlyph

/// 测试夹具：构造合法的 `DayGenerationResponse` 及其字符串化 JSON。
enum GenerationFixtures {

    /// 一份合法的、可通过校验的响应。可用闭包局部改写。
    static func validResponse(_ mutate: (inout DayGenerationResponse) -> Void = { _ in }) -> DayGenerationResponse {
        var response = DemoFallbackCatalog.richSample
        response.requestID = "test"
        mutate(&response)
        return response
    }

    /// OpenAI 兼容的 chat/completions 响应体，content 承载给定 JSON。
    static func chatCompletionEnvelope(contentJSON: String) -> Data {
        let escaped = contentJSON
        let payload: [String: Any] = [
            "id": "test",
            "object": "chat.completion",
            "choices": [
                ["index": 0, "message": ["role": "assistant", "content": escaped], "finish_reason": "stop"]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: payload)
    }

    /// Seedream images/generations 响应体。
    static func imageEnvelope(url: String, size: String = "1728x2160") -> Data {
        let payload: [String: Any] = [
            "model": "doubao-seedream-5-0-260128",
            "created": 1_757_321_139,
            "data": [["url": url, "size": size]],
            "usage": ["generated_images": 1]
        ]
        return try! JSONSerialization.data(withJSONObject: payload)
    }

    static func encodedJSONString(_ response: DayGenerationResponse) -> String {
        let data = try! JSONEncoder().encode(response)
        return String(data: data, encoding: .utf8)!
    }
}
