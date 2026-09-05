#!/bin/bash
# 在 macOS 上执行核心逻辑测试；不启动应用，也不调用在线模型。
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
core_dir="$(mktemp -d "${TMPDIR:-/tmp}/dayglyph-core.XXXXXX")"
trap 'rm -rf "$core_dir"' EXIT
mkdir -p "$core_dir/Sources/DayGlyph" "$core_dir/Tests/DayGlyphTests"

# 直接复制生产文件和现有测试，不替换实现。完整 iOS 工程仍需通过 Xcode 验证。
for source in \
  Models/Emotion.swift \
  Models/DayGenerationResponse.swift \
  Services/EmotionLexicon.swift \
  Services/GenerationAnalysisMapper.swift \
  Services/GenerationSchemaValidator.swift \
  Services/DemoFallbackCatalog.swift \
  Glyph/GlyphSignature.swift \
  Glyph/SeededRandom.swift; do
  cp "$repo_dir/DayGlyph/$source" "$core_dir/Sources/DayGlyph/"
done
for test_file in EmotionAnalysisTests.swift GlyphSignatureTests.swift GenerationAnalysisMapperTests.swift GenerationFixtures.swift; do
  cp "$repo_dir/DayGlyphTests/$test_file" "$core_dir/Tests/DayGlyphTests/"
done

cat > "$core_dir/Package.swift" <<'SWIFT'
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DayGlyphCoreChecks",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "DayGlyph", swiftSettings: [.defaultIsolation(MainActor.self)]),
        .testTarget(name: "DayGlyphTests", dependencies: ["DayGlyph"])
    ],
    swiftLanguageModes: [.v5]
)
SWIFT
xcrun swift --version
xcrun swift test --package-path "$core_dir"
