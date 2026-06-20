import Foundation

/// 文本生成客户端协议，便于测试注入。
protocol SeedTextGenerating: Sendable {
    func generate(record: String) async throws -> DayGenerationResponse
}

/// Seed 2.0 Lite 文本客户端（spec 第 6 节、模块边界 SeedTextClient）。
///
/// 真实契约（2026-06-20 探针验证）：
/// - `POST /api/v3/chat/completions`，Bearer 鉴权，`response_format: {"type":"json_object"}`。
/// - `choices[0].message.content` 是 JSON 字符串；Seed 2.0 Lite 为推理模型，单次约 7 秒。
///
/// 失败处理（spec 第 6、8 节）：
/// - 网络瞬断/超时/5xx：自动重试一次。
/// - 非法 JSON 或语义校验失败：发一条修复指令做修复性重试，仅一次。
struct SeedTextClient: SeedTextGenerating {
    var configuration: AIConfiguration
    var session: URLSession

    init(configuration: AIConfiguration = .demo, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func generate(record: String) async throws -> DayGenerationResponse {
        guard configuration.hasValidAPIKey else { throw DoubaoClientError.missingAPIKey }

        let systemPrompt = GenerationPromptBuilder.systemPrompt()
        let userMessage = GenerationPromptBuilder.userMessage(record: record)

        // 第一次：正常请求 + 瞬时错误重试一次。
        let firstContent = try await requestContentWithTransientRetry(
            messages: [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ]
        )

        do {
            return try decodeAndValidate(firstContent)
        } catch {
            // 第二次：修复性重试（仅一次），把上次输出与错误回灌，要求只修结构。
            let repairContent = try await requestContentWithTransientRetry(
                messages: [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": userMessage],
                    ["role": "assistant", "content": firstContent],
                    ["role": "user", "content": repairInstruction(for: error)]
                ]
            )
            return try decodeAndValidate(repairContent)
        }
    }

    // MARK: - 请求

    private func requestContentWithTransientRetry(messages: [[String: String]]) async throws -> String {
        do {
            return try await requestContent(messages: messages)
        } catch let error as DoubaoClientError {
            // 限流：按接口 Retry-After 等待一次再重试（上限 10 秒）。
            if case .rateLimited(let after) = error {
                let wait = min(after ?? 3, 10)
                try? await Task.sleep(for: .seconds(wait))
                return try await requestContent(messages: messages)
            }
            if error.isTransient {
                return try await requestContent(messages: messages)
            }
            throw error
        }
    }

    private func requestContent(messages: [[String: String]]) async throws -> String {
        let url = configuration.baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.textTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": configuration.textModelID,
            "messages": messages,
            "response_format": ["type": "json_object"],
            "temperature": 0.6
        ])

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw DoubaoClientError.cancelled
        } catch {
            throw DoubaoClientError.invalidResponse
        }

        guard let http = response as? HTTPURLResponse else { throw DoubaoClientError.invalidResponse }
        try Self.checkStatus(http, data: data)

        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = root["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw DoubaoClientError.invalidResponse
        }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DoubaoClientError.emptyContent }
        return trimmed
    }

    // MARK: - 解码与校验

    private func decodeAndValidate(_ content: String) throws -> DayGenerationResponse {
        let jsonString = Self.stripCodeFence(content)
        guard let data = jsonString.data(using: .utf8) else {
            throw DoubaoClientError.decodingFailed("内容无法编码为 UTF-8")
        }
        let response: DayGenerationResponse
        do {
            response = try JSONDecoder().decode(DayGenerationResponse.self, from: data)
        } catch {
            throw DoubaoClientError.decodingFailed(String(describing: error))
        }
        try GenerationSchemaValidator.validate(response)
        return response
    }

    private func repairInstruction(for error: Error) -> String {
        """
        你上一条回复不符合约定结构，错误是：\(error.localizedDescription)。
        请仅修正结构与字段，重新输出一个完整、合法的 JSON 对象，不要任何额外文字或 Markdown 代码块。
        """
    }

    // MARK: - 工具

    static func checkStatus(_ http: HTTPURLResponse, data: Data) throws {
        switch http.statusCode {
        case 200...299:
            return
        case 429:
            let retryAfter = (http.value(forHTTPHeaderField: "Retry-After")).flatMap(TimeInterval.init)
            throw DoubaoClientError.rateLimited(retryAfter: retryAfter)
        default:
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { ($0["error"] as? [String: Any])?["message"] as? String }
                ?? String(data: data, encoding: .utf8)
                ?? ""
            throw DoubaoClientError.httpStatus(http.statusCode, message)
        }
    }

    /// 容错剥离可能的 Markdown 代码围栏（探针显示通常无围栏，但防御性处理）。
    static func stripCodeFence(_ content: String) -> String {
        var s = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.hasPrefix("```") else { return s }
        if let firstNewline = s.firstIndex(of: "\n") {
            s = String(s[s.index(after: firstNewline)...])
        }
        if let fenceRange = s.range(of: "```", options: .backwards) {
            s = String(s[..<fenceRange.lowerBound])
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
