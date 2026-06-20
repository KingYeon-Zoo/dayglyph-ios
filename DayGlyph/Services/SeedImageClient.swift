import Foundation

/// 单张图生成结果：图片字节 + 返回尺寸。
struct GeneratedImageData: Sendable {
    var data: Data
    var size: String?
}

/// 生图客户端协议，便于测试注入。
protocol SeedImageGenerating: Sendable {
    func generate(prompt: String, size: String) async throws -> GeneratedImageData
}

/// Seedream 生图客户端（spec 模块边界 SeedImageClient）。
///
/// 真实契约（2026-06-20 探针验证）：
/// - `POST /api/v3/images/generations`，Bearer 鉴权。
/// - body: model / prompt / size / sequential_image_generation=disabled / stream=false /
///   response_format=url / watermark=false。
/// - size 像素总数必须 ≥ 3,686,400，否则 400 InvalidParameter。
/// - 返回 `data[0].url`（JPEG，TOS 临时地址 24 小时有效）+ `data[0].size`；单图约 20 秒。
/// - url 必须立即下载落本地。
struct SeedImageClient: SeedImageGenerating {
    var configuration: AIConfiguration
    var session: URLSession

    init(configuration: AIConfiguration = .demo, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func generate(prompt: String, size: String) async throws -> GeneratedImageData {
        guard configuration.hasValidAPIKey else { throw DoubaoClientError.missingAPIKey }

        let urlString = try await requestImageURLWithTransientRetry(prompt: prompt, size: size)
        guard let imageURL = URL(string: urlString.url) else {
            throw DoubaoClientError.invalidResponse
        }
        let data = try await download(imageURL)
        return GeneratedImageData(data: data, size: urlString.size)
    }

    // MARK: - 请求生图

    private func requestImageURLWithTransientRetry(prompt: String, size: String) async throws -> (url: String, size: String?) {
        do {
            return try await requestImageURL(prompt: prompt, size: size)
        } catch let error as DoubaoClientError {
            // 限流：按接口 Retry-After 等待一次再重试（上限 10 秒，避免演示卡死）。
            if case .rateLimited(let after) = error {
                let wait = min(after ?? 3, 10)
                try? await Task.sleep(for: .seconds(wait))
                return try await requestImageURL(prompt: prompt, size: size)
            }
            // 网络瞬断/超时/5xx：重试一次。
            if error.isTransient {
                return try await requestImageURL(prompt: prompt, size: size)
            }
            throw error
        }
    }

    private func requestImageURL(prompt: String, size: String) async throws -> (url: String, size: String?) {
        let url = configuration.baseURL.appendingPathComponent("images/generations")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.imageTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": configuration.imageModelID,
            "prompt": prompt,
            "size": size,
            "sequential_image_generation": "disabled",
            "stream": false,
            "response_format": "url",
            "watermark": false
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
        try SeedTextClient.checkStatus(http, data: data)

        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let dataArray = root["data"] as? [[String: Any]],
            let first = dataArray.first,
            let imageURL = first["url"] as? String
        else {
            throw DoubaoClientError.invalidResponse
        }
        return (imageURL, first["size"] as? String)
    }

    // MARK: - 下载

    private func download(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = configuration.downloadTimeout

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw DoubaoClientError.cancelled
        } catch {
            throw DoubaoClientError.invalidResponse
        }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DoubaoClientError.invalidResponse
        }
        guard !data.isEmpty else { throw DoubaoClientError.emptyContent }
        return data
    }
}
