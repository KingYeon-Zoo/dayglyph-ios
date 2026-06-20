#!/usr/bin/env swift
//
// 豆包接口契约探针 — DayGlyph 阶段 1
//
// 目的：以真实请求验证火山方舟接口契约，不靠产品展示名称猜字段。
// 运行：
//   export ARK_API_KEY="你的key"
//   swift Tools/DoubaoProbe/probe.swift
// 或把 key 作为第一个参数：
//   swift Tools/DoubaoProbe/probe.swift "你的key"
//
// 探针会：
//   1. 调用 Seed 2.0 Lite chat/completions，使用 response_format=json_object，
//      要求模型只返回一个 JSON 对象，打印原始返回与解码后的字段。
//   2. 调用 Seedream images/generations 生成一张 4:5 图，response_format=url，
//      打印返回结构、url、size，并尝试下载首图，记录耗时与字节数。
//
// 这是一次性诊断工具，不属于 app target。结果用于确认 SeedTextClient /
// SeedImageClient 的真实字段，再进入全量建设。

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - 配置（与 AIConfiguration 保持一致的真实值）

let arkBaseURL = "https://ark.cn-beijing.volces.com/api/v3"
let textModelID = "doubao-seed-2-0-lite-260428"
let imageModelID = "doubao-seedream-5-0-260128"

func resolveAPIKey() -> String? {
    if CommandLine.arguments.count > 1, !CommandLine.arguments[1].isEmpty {
        return CommandLine.arguments[1]
    }
    if let env = ProcessInfo.processInfo.environment["ARK_API_KEY"], !env.isEmpty {
        return env
    }
    return nil
}

guard let apiKey = resolveAPIKey() else {
    FileHandle.standardError.write(Data("缺少 API Key。用法：swift probe.swift \"<ARK_API_KEY>\" 或设置环境变量 ARK_API_KEY。\n".utf8))
    exit(2)
}

// MARK: - 工具

func section(_ title: String) {
    print("\n" + String(repeating: "=", count: 64))
    print("  \(title)")
    print(String(repeating: "=", count: 64))
}

func prettyPrint(_ data: Data) {
    guard
        let object = try? JSONSerialization.jsonObject(with: data),
        let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .withoutEscapingSlashes])
    else {
        print(String(data: data, encoding: .utf8) ?? "<无法解码为 UTF-8>")
        return
    }
    print(String(data: pretty, encoding: .utf8) ?? "<无法解码>")
}

func post(path: String, body: [String: Any]) async -> (Data, HTTPURLResponse, TimeInterval)? {
    guard let url = URL(string: arkBaseURL + path) else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 120
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let start = Date()
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        let elapsed = Date().timeIntervalSince(start)
        guard let http = response as? HTTPURLResponse else {
            print("非 HTTP 响应")
            return nil
        }
        return (data, http, elapsed)
    } catch {
        print("请求失败：\(error)")
        return nil
    }
}

// MARK: - 1. 文本接口探针

func probeText() async {
    section("1. Seed 2.0 Lite 文本接口（chat/completions, json_object）")

    let systemPrompt = """
    你是一个情绪分析引擎。只返回一个 JSON 对象，不要任何额外文字、解释或 Markdown 代码块。
    JSON 结构：{"emotions":[{"term":"标准情绪词","intensity":0到1的小数,"evidence":"原文依据"}],"summary":"一句克制的解释"}
    emotions 最多 8 项，按显著度排序。
    """
    let userPrompt = """
    请分析这段中文记录的情绪：
    <用户记录>
    今天我把准备很久的方案交上去了，既松了一口气，又有点担心被挑毛病，还夹着一点没被理解的委屈。
    </用户记录>
    """

    let body: [String: Any] = [
        "model": textModelID,
        "messages": [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ],
        "response_format": ["type": "json_object"],
        "temperature": 0.6
    ]

    guard let (data, http, elapsed) = await post(path: "/chat/completions", body: body) else {
        print("文本探针未获得响应")
        return
    }

    print("HTTP 状态：\(http.statusCode)")
    print(String(format: "耗时：%.2f 秒", elapsed))
    print("\n--- 原始响应 ---")
    prettyPrint(data)

    guard http.statusCode == 200 else {
        print("\n⚠️ 文本接口非 200，请核对接入点 ID 与权限。")
        return
    }

    // 解析 OpenAI 兼容结构：choices[0].message.content 是字符串化 JSON
    guard
        let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let choices = root["choices"] as? [[String: Any]],
        let message = choices.first?["message"] as? [String: Any],
        let content = message["content"] as? String
    else {
        print("\n⚠️ 未找到 choices[0].message.content，OpenAI 兼容结构可能不同。")
        return
    }

    print("\n--- message.content（应为纯 JSON 字符串）---")
    print(content)

    if let contentData = content.data(using: .utf8),
       let parsed = try? JSONSerialization.jsonObject(with: contentData) {
        print("\n✅ content 可解码为 JSON 对象：")
        if let prettyData = try? JSONSerialization.data(withJSONObject: parsed, options: [.prettyPrinted, .withoutEscapingSlashes]) {
            print(String(data: prettyData, encoding: .utf8) ?? "")
        }
        print("\n结论：json_object 模式可用，content 字段承载结构化 JSON 字符串。")
    } else {
        print("\n⚠️ content 不是合法 JSON——可能含 Markdown 围栏或多余文字，需在客户端剥离后再解码。")
    }
}

// MARK: - 2. 生图接口探针

func probeImage() async {
    section("2. Seedream 生图接口（images/generations, 4:5）")

    let body: [String: Any] = [
        "model": imageModelID,
        "prompt": "一杯艺术鸡尾酒，半透明矿物质感杯身，内部柔和扩散的暖橙到深蓝液体层次，细微悬浮粒子，柔光，深色干净背景，无文字无标志，竖向构图",
        "size": "1664x2048",
        "sequential_image_generation": "disabled",
        "stream": false,
        "response_format": "url",
        "watermark": false
    ]

    guard let (data, http, elapsed) = await post(path: "/images/generations", body: body) else {
        print("生图探针未获得响应")
        return
    }

    print("HTTP 状态：\(http.statusCode)")
    print(String(format: "耗时：%.2f 秒", elapsed))
    print("\n--- 原始响应 ---")
    prettyPrint(data)

    guard http.statusCode == 200 else {
        print("\n⚠️ 生图接口非 200，请核对生图模型 ID、size 取值与 watermark 是否被接受。")
        return
    }

    guard
        let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let dataArray = root["data"] as? [[String: Any]],
        let first = dataArray.first
    else {
        print("\n⚠️ 未找到 data 数组，响应结构可能不同。")
        return
    }

    print("\n--- data[0] ---")
    print("size: \(first["size"] ?? "无")")
    let hasURL = first["url"] != nil
    let hasB64 = first["b64_json"] != nil
    print("含 url: \(hasURL)  含 b64_json: \(hasB64)")

    guard let urlString = first["url"] as? String, let imageURL = URL(string: urlString) else {
        print("\n⚠️ 无 url 字段；若 response_format=url 仍无 url，需改用 b64_json。")
        return
    }

    print("url: \(urlString)")
    print("\n尝试下载首图……")
    let start = Date()
    do {
        let (imageData, dlResp) = try await URLSession.shared.data(from: imageURL)
        let dlElapsed = Date().timeIntervalSince(start)
        let status = (dlResp as? HTTPURLResponse)?.statusCode ?? -1
        print(String(format: "下载 HTTP %d，%.2f 秒，%d 字节", status, dlElapsed, imageData.count))
        // 探测格式头
        let head = [UInt8](imageData.prefix(12))
        let isJPEG = head.starts(with: [0xFF, 0xD8, 0xFF])
        let isPNG = head.starts(with: [0x89, 0x50, 0x4E, 0x47])
        let isWebP = head.count >= 12 && Array(head[0..<4]) == [0x52, 0x49, 0x46, 0x46] && Array(head[8..<12]) == [0x57, 0x45, 0x42, 0x50]
        print("格式：JPEG=\(isJPEG) PNG=\(isPNG) WebP=\(isWebP)")
        print("\n✅ 生图 + 下载链路可用。url 为临时地址，客户端必须立即下载落本地。")
    } catch {
        print("下载失败：\(error)")
    }
}

// MARK: - 主流程

await probeText()
await probeImage()

section("探针结束")
print("把上面的 HTTP 状态、字段结构与耗时反馈给实现，确认契约后进入全量建设。")
