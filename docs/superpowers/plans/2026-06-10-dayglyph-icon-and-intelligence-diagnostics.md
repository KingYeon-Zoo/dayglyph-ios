# DayGlyph Icon and Intelligence Diagnostics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current App Icon with the approved “一笔日痕” design and expose accurate Foundation Models availability diagnostics throughout the app.

**Architecture:** Add a small app-owned availability model that translates `SystemLanguageModel` states into stable UI-facing status values. Keep Foundation Models types inside the service layer, inject status into SwiftUI views, and generate all App Icon variants from a deterministic drawing script.

**Tech Stack:** Swift 6, SwiftUI, Foundation Models, Swift Testing, Xcode Asset Catalog, Python standard library.

---

## File Structure

- Create `DayGlyph/Services/AppleIntelligenceStatus.swift`: app-owned availability enum, display copy, environment label, and Foundation Models adapter.
- Create `DayGlyphTests/AppleIntelligenceStatusTests.swift`: availability copy and behavior tests independent of device eligibility.
- Modify `DayGlyph/Services/FoundationEmotionAnalyzer.swift`: reuse the shared availability adapter before creating a model session.
- Modify `DayGlyph/Views/TodayView.swift`: render live availability instead of static Apple Intelligence copy.
- Modify `DayGlyph/Views/SettingsView.swift`: add a diagnostic section and Apple support link.
- Modify `DayGlyph/Models/Emotion.swift`: make fallback source wording accurate and concise.
- Modify `tools/generate_dayglyph_app_icons.py`: draw the approved continuous stroke and endpoint variants.
- Regenerate `DayGlyph/Assets.xcassets/AppIcon.appiconset/*.png`: default, dark, and tinted 1024 px assets.

### Task 1: Add Apple Intelligence Status Model

**Files:**
- Create: `DayGlyphTests/AppleIntelligenceStatusTests.swift`
- Create: `DayGlyph/Services/AppleIntelligenceStatus.swift`

- [ ] **Step 1: Write failing status tests**

```swift
import Testing
@testable import DayGlyph

struct AppleIntelligenceStatusTests {
    @Test func availableStatusCanUseFoundationModels() {
        let status = AppleIntelligenceStatus.available
        #expect(status.canUseFoundationModels)
        #expect(status.title == "Apple Intelligence 已就绪")
    }

    @Test func deviceNotEligibleExplainsLocalFallback() {
        let status = AppleIntelligenceStatus.deviceNotEligible
        #expect(status.canUseFoundationModels == false)
        #expect(status.title == "此设备不符合运行条件")
        #expect(status.detail.contains("本地分析"))
    }

    @Test func modelNotReadyDoesNotClaimAvailability() {
        let status = AppleIntelligenceStatus.modelNotReady
        #expect(status.canUseFoundationModels == false)
        #expect(status.detail.contains("准备"))
    }
}
```

- [ ] **Step 2: Run the new test and verify RED**

Run through XcodeBuildMCP with the current project, scheme, and simulator.

Expected: build failure because `AppleIntelligenceStatus` does not exist.

- [ ] **Step 3: Implement the app-owned status type**

```swift
import Foundation
import FoundationModels

enum AppleIntelligenceStatus: Equatable {
    case available
    case appleIntelligenceNotEnabled
    case modelNotReady
    case deviceNotEligible
    case unknown

    var canUseFoundationModels: Bool { self == .available }

    var title: String {
        switch self {
        case .available: "Apple Intelligence 已就绪"
        case .appleIntelligenceNotEnabled: "Apple Intelligence 尚未开启"
        case .modelNotReady: "Apple Intelligence 正在准备"
        case .deviceNotEligible: "此设备不符合运行条件"
        case .unknown: "暂时无法使用 Apple Intelligence"
        }
    }

    var detail: String {
        switch self {
        case .available:
            "DayGlyph 会优先使用设备端模型理解记录。"
        case .appleIntelligenceNotEnabled:
            "请在系统设置中开启 Apple Intelligence；当前继续使用本地分析。"
        case .modelNotReady:
            "系统模型仍在准备或下载；当前继续使用本地分析。"
        case .deviceNotEligible:
            "设备、地区或系统资格不满足要求；当前继续使用本地分析。"
        case .unknown:
            "系统没有返回可识别的状态；当前继续使用本地分析。"
        }
    }
}

extension AppleIntelligenceStatus {
    static var current: Self {
        switch SystemLanguageModel.default.availability {
        case .available:
            .available
        case .unavailable(.appleIntelligenceNotEnabled):
            .appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            .modelNotReady
        case .unavailable(.deviceNotEligible):
            .deviceNotEligible
        @unknown default:
            .unknown
        }
    }
}
```

- [ ] **Step 4: Run the status tests and verify GREEN**

Expected: all `AppleIntelligenceStatusTests` pass.

- [ ] **Step 5: Commit**

```bash
git add DayGlyph/Services/AppleIntelligenceStatus.swift DayGlyphTests/AppleIntelligenceStatusTests.swift
git commit -m "Add Apple Intelligence availability model"
```

### Task 2: Use Shared Availability in Analysis and Source Copy

**Files:**
- Modify: `DayGlyph/Services/FoundationEmotionAnalyzer.swift`
- Modify: `DayGlyph/Models/Emotion.swift`
- Modify: `DayGlyphTests/UnifiedEmotionAnalyzerTests.swift`

- [ ] **Step 1: Add a failing assertion for honest fallback copy**

```swift
@Test func fallbackCopyDoesNotClaimAppleIntelligenceParticipation() {
    #expect(AnalysisSource.fallback.title == "已使用本地回退")
    #expect(AnalysisSource.fallback.title.contains("已参与") == false)
}
```

- [ ] **Step 2: Run the focused test and verify RED**

Expected: fallback title mismatch.

- [ ] **Step 3: Update fallback wording and availability guard**

Set `.fallback` title to `已使用本地回退`. In `FoundationEmotionAnalyzer`, read `AppleIntelligenceStatus.current`, require `.available`, and throw an unavailable error using the status detail before constructing `LanguageModelSession`.

- [ ] **Step 4: Run analyzer tests and verify GREEN**

Expected: source copy and existing fallback behavior pass.

- [ ] **Step 5: Commit**

```bash
git add DayGlyph/Models/Emotion.swift DayGlyph/Services/FoundationEmotionAnalyzer.swift DayGlyphTests/UnifiedEmotionAnalyzerTests.swift
git commit -m "Report Foundation Models fallback accurately"
```

### Task 3: Show Live Diagnostics in Today and Settings

**Files:**
- Modify: `DayGlyph/Services/AppleIntelligenceStatus.swift`
- Modify: `DayGlyph/Views/TodayView.swift`
- Modify: `DayGlyph/Views/SettingsView.swift`

- [ ] **Step 1: Add failing tests for environment and help copy**

```swift
@Test func statusProvidesActionableSuggestion() {
    #expect(AppleIntelligenceStatus.appleIntelligenceNotEnabled.suggestion.contains("系统设置"))
    #expect(AppleIntelligenceStatus.deviceNotEligible.suggestion.contains("符合条件"))
}
```

- [ ] **Step 2: Run the tests and verify RED**

Expected: `suggestion` is missing.

- [ ] **Step 3: Add diagnostic presentation properties**

Add `suggestion`, `symbolName`, and `environmentTitle`. Compile simulator/device environment labels with `#if targetEnvironment(simulator)`.

- [ ] **Step 4: Update SwiftUI views**

`TodayView` stores `AppleIntelligenceStatus.current` and shows its title/detail. `SettingsView` adds an “Apple Intelligence” section with status, environment, suggestion, and:

```swift
Link("查看 Apple 官方可用性说明",
     destination: URL(string: "https://support.apple.com/zh-cn/121115")!)
```

- [ ] **Step 5: Run status tests and build**

Expected: tests pass and both views compile.

- [ ] **Step 6: Commit**

```bash
git add DayGlyph/Services/AppleIntelligenceStatus.swift DayGlyph/Views/TodayView.swift DayGlyph/Views/SettingsView.swift DayGlyphTests/AppleIntelligenceStatusTests.swift
git commit -m "Show Apple Intelligence diagnostics"
```

### Task 4: Generate Approved App Icon

**Files:**
- Modify: `tools/generate_dayglyph_app_icons.py`
- Regenerate: `DayGlyph/Assets.xcassets/AppIcon.appiconset/dayglyph-icon-default.png`
- Regenerate: `DayGlyph/Assets.xcassets/AppIcon.appiconset/dayglyph-icon-dark.png`
- Regenerate: `DayGlyph/Assets.xcassets/AppIcon.appiconset/dayglyph-icon-tinted.png`

- [ ] **Step 1: Inspect current icon dimensions before replacement**

Run:

```bash
sips -g pixelWidth -g pixelHeight DayGlyph/Assets.xcassets/AppIcon.appiconset/*.png
```

Expected: all current files are 1024 x 1024.

- [ ] **Step 2: Replace drawing geometry**

Update the script to draw a smooth, thick, almost-closed continuous circular stroke with round caps and one small endpoint dot. Use separate approved palettes for default, dark, and tinted modes; remove the current gauge-like diagonal line and extra ring structure.

- [ ] **Step 3: Generate the three icon files**

Run:

```bash
python3 tools/generate_dayglyph_app_icons.py
```

Expected: three PNG paths printed with no exception.

- [ ] **Step 4: Validate dimensions and visually inspect**

Run `sips` again and inspect the three output images. Expected: 1024 x 1024, no text, no transparent corners, consistent stroke geometry.

- [ ] **Step 5: Commit**

```bash
git add tools/generate_dayglyph_app_icons.py DayGlyph/Assets.xcassets/AppIcon.appiconset
git commit -m "Redesign DayGlyph app icon"
```

### Task 5: Full Verification and Simulator Run

**Files:**
- Verify all changed files.

- [ ] **Step 1: Run the complete iOS test suite**

Use XcodeBuildMCP `test_sim` with the active DayGlyph simulator defaults.

Expected: all tests pass with zero failures.

- [ ] **Step 2: Build and run the app**

Use XcodeBuildMCP `build_run_sim`.

Expected: build succeeds and DayGlyph launches.

- [ ] **Step 3: Inspect Today screen**

Verify the banner reports `此设备不符合运行条件` on the current environment and does not claim Apple Intelligence is active.

- [ ] **Step 4: Inspect Settings screen**

Verify the Apple Intelligence diagnostic section shows simulator environment, actionable suggestion, and official support link.

- [ ] **Step 5: Inspect Home Screen icon**

Return to the Simulator Home Screen and verify the installed icon uses the approved “一笔日痕” shape at small size.

- [ ] **Step 6: Check repository state**

Run:

```bash
git status --short
git log --oneline -8
```

Expected: only intentional changes remain, with implementation commits present.
