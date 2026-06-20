import Testing
import Foundation
@testable import DayGlyph

/// URLProtocol mock：按请求顺序返回预设响应，验证网络失败矩阵与解码。
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responses: [(statusCode: Int, data: Data)] = []
    nonisolated(unsafe) static var requestCount = 0

    static func reset(_ responses: [(Int, Data)]) {
        self.responses = responses
        requestCount = 0
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let index = min(Self.requestCount, Self.responses.count - 1)
        let entry = Self.responses[index]
        Self.requestCount += 1

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: entry.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: entry.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
@Suite(.serialized)
struct DoubaoNetworkTests {

@Suite(.serialized)
struct SeedTextClientTests {

    private func makeClient() -> SeedTextClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        var aiConfig = AIConfiguration.demo
        aiConfig.apiKey = "ark-test-key" // 绕过占位符检查
        return SeedTextClient(configuration: aiConfig, session: session)
    }

    @Test func decodesValidContent() async throws {
        let json = GenerationFixtures.encodedJSONString(GenerationFixtures.validResponse())
        MockURLProtocol.reset([(200, GenerationFixtures.chatCompletionEnvelope(contentJSON: json))])

        let response = try await makeClient().generate(record: "今天还不错")
        #expect(response.emotionAnalysis.emotions.isEmpty == false)
    }

    @Test func stripsMarkdownCodeFence() async throws {
        let json = GenerationFixtures.encodedJSONString(GenerationFixtures.validResponse())
        let fenced = "```json\n\(json)\n```"
        MockURLProtocol.reset([(200, GenerationFixtures.chatCompletionEnvelope(contentJSON: fenced))])

        let response = try await makeClient().generate(record: "今天还不错")
        #expect(response.schemaVersion == "1.0")
    }

    @Test func retriesOnceOnServerError() async throws {
        let json = GenerationFixtures.encodedJSONString(GenerationFixtures.validResponse())
        MockURLProtocol.reset([
            (500, Data("{\"error\":{\"message\":\"server\"}}".utf8)),
            (200, GenerationFixtures.chatCompletionEnvelope(contentJSON: json))
        ])

        let response = try await makeClient().generate(record: "今天还不错")
        #expect(response.schemaVersion == "1.0")
        #expect(MockURLProtocol.requestCount == 2)
    }

    @Test func repairRetryOnInvalidJSON() async throws {
        let validJSON = GenerationFixtures.encodedJSONString(GenerationFixtures.validResponse())
        MockURLProtocol.reset([
            (200, GenerationFixtures.chatCompletionEnvelope(contentJSON: "{不是合法JSON")),
            (200, GenerationFixtures.chatCompletionEnvelope(contentJSON: validJSON))
        ])

        let response = try await makeClient().generate(record: "今天还不错")
        #expect(response.schemaVersion == "1.0")
        // 一次正常 + 一次修复 = 2 次请求。
        #expect(MockURLProtocol.requestCount == 2)
    }

    @Test func throwsOnPersistentHTTPError() async {
        MockURLProtocol.reset([
            (400, Data("{\"error\":{\"message\":\"bad\"}}".utf8))
        ])
        await #expect(throws: DoubaoClientError.self) {
            _ = try await makeClient().generate(record: "今天还不错")
        }
    }
}

@Suite(.serialized)
struct SeedImageClientTests {

    private func makeClient() -> SeedImageClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        var aiConfig = AIConfiguration.demo
        aiConfig.apiKey = "ark-test-key"
        return SeedImageClient(configuration: aiConfig, session: session)
    }

    @Test func generatesAndDownloadsImage() async throws {
        let imageBytes = Data([0xFF, 0xD8, 0xFF, 0xAA])
        MockURLProtocol.reset([
            (200, GenerationFixtures.imageEnvelope(url: "https://example.com/x.jpeg")),
            (200, imageBytes)
        ])
        let result = try await makeClient().generate(prompt: "p", size: "1728x2160")
        #expect(result.data == imageBytes)
        #expect(result.size == "1728x2160")
    }

    @Test func throwsOnInvalidParameterStatus() async {
        MockURLProtocol.reset([
            (400, Data("{\"error\":{\"message\":\"size too small\"}}".utf8))
        ])
        await #expect(throws: DoubaoClientError.self) {
            _ = try await makeClient().generate(prompt: "p", size: "100x100")
        }
    }
}

} // DoubaoNetworkTests
