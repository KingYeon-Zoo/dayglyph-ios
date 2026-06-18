# DayGlyph v2 Today 支持模块 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 T-04 情绪天气与名言、T-05 今天迈一小步、T-06 时间来信和 T-07 共情海本地 Demo 闭环。

**Architecture:** 在 Stage 1 稳定的 `DayEntry`、`EmotionRecipe` 和 `MoodWeather` 之上增加三个独立 SwiftData 对象，分别保存行动实例、时间来信和匿名公开副本。推荐与内容选择由无副作用的本地目录服务完成，SwiftUI 视图只持有页面交互状态并通过 `ModelContext` 持久化；不提前接入 Stage 4 的通知、行动回声反馈或网络审核。

**Tech Stack:** SwiftUI、SwiftData、Swift Testing、SF Symbols、系统 Dynamic Type。

---

## 文件结构

新增文件：

- `DayGlyph/Models/TodaySupportModels.swift`：`MicroAction`、`ActionInstance`、`TimeLetter`、`EmpathyCopy` 及状态枚举。
- `DayGlyph/Services/MicroActionCatalog.swift`：确定性候选、明确禁用项过滤和单卡替换。
- `DayGlyph/Services/WeatherQuoteCatalog.swift`：天气图标、主题名言、产品自有支持文案与每日切换限制。
- `DayGlyph/Services/EmpathySeaDemoCatalog.swift`：本地打捞内容、固定回应和联系方式检测。
- `DayGlyph/Views/Today/WeatherQuoteSection.swift`：T-04 两张纵向卡及说明 Sheet。
- `DayGlyph/Views/Today/MicroActionSection.swift`：T-05 三候选、开始/取消/完成/跳过闭环。
- `DayGlyph/Views/Today/TimeLetterSection.swift`：T-06 今日来信或写给未来入口。
- `DayGlyph/Views/Today/EmpathySeaSection.swift`：T-07 入口、编辑副本、二次确认、审核中和本地回应。
- `DayGlyphTests/MicroActionCatalogTests.swift`、`WeatherQuoteCatalogTests.swift`、`TodaySupportPersistenceTests.swift`、`EmpathySeaDemoTests.swift`。

修改文件：

- `DayGlyph/DayGlyphApp.swift`：注册三个 Stage 2 SwiftData 模型。
- `DayGlyph/Views/Today/TodayHomeView.swift`：按天气/名言、微行动、时间来信、共情海顺序挂载模块，并让空状态也显示微行动。
- `DayGlyph/Views/Today/CocktailResultView.swift`：移除 Stage 1 内嵌天气摘要，避免 T-04 重复。
- `DayGlyph/Views/Today/TodaySupportPlaceholders.swift`：删除占位实现。

本阶段不修改 `ReminderService`、回声 Tab、宇宙 Tab、Mine 统计和网络层。

### Task 1: 微行动模型、筛选和状态机

**Files:**
- Create: `DayGlyph/Models/TodaySupportModels.swift`
- Create: `DayGlyph/Services/MicroActionCatalog.swift`
- Test: `DayGlyphTests/MicroActionCatalogTests.swift`
- Test: `DayGlyphTests/TodaySupportPersistenceTests.swift`

- [ ] **Step 1: 写失败测试**

覆盖：候选固定返回三项；明确禁用类别绝不出现；“换成更容易的”只替换指定卡；`ActionInstance` 可保存 `startedAt`、`completedAt` 与 `state`。

- [ ] **Step 2: 运行测试确认因类型不存在而失败**

Run: `xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests/MicroActionCatalogTests -only-testing:DayGlyphTests/TodaySupportPersistenceTests test`

Expected: FAIL，提示 `MicroActionCatalog`、`ActionInstance` 不存在。

- [ ] **Step 3: 实现最小模型与纯函数目录**

`MicroAction` 使用 `id/category/title/estimatedMinutes/constraints/difficultyBand`；`ActionInstance` 使用 `actionId/entryId/startedAt/completedAt/followUpAt/stateRawValue`。目录按情绪锚点和稳定 seed 排序，过滤发生在排序前，候选不足时只放宽难度，不恢复明确禁用类别。

- [ ] **Step 4: 运行定向测试确认通过**

- [ ] **Step 5: 提交**

`git commit -m "feat: add micro action recommendation model"`

### Task 2: T-05 微行动 UI

**Files:**
- Create: `DayGlyph/Views/Today/MicroActionSection.swift`
- Modify: `DayGlyph/Views/Today/TodayHomeView.swift`

- [ ] **Step 1: 先用可测试文案函数补失败测试**

覆盖未开始、进行中、完成和今天跳过四种按钮/状态文案。

- [ ] **Step 2: 实现三张纵向行动卡**

每卡展示动作、预计耗时和完整约束短语；开始后只显示当前行动，支持取消和完成；“换成更容易的”仅替换当前候选；“今天先不做”保存跳过实例且不显示惩罚性文案。

- [ ] **Step 3: 构建并运行定向测试**

- [ ] **Step 4: 提交**

`git commit -m "feat: implement today micro action flow"`

### Task 3: T-04 天气与名言

**Files:**
- Create: `DayGlyph/Services/WeatherQuoteCatalog.swift`
- Create: `DayGlyph/Views/Today/WeatherQuoteSection.swift`
- Test: `DayGlyphTests/WeatherQuoteCatalogTests.swift`

- [ ] **Step 1: 写失败测试**

覆盖同一天同一配方选择稳定、每个天气都有非颜色文字、名言缺失时使用无伪造出处的产品自有文案、每天最多切换三次。

- [ ] **Step 2: 运行测试确认失败**

- [ ] **Step 3: 实现目录与两张纵向卡**

天气卡提供图标、明确天气词和说明 Sheet；名言卡提供来源、切换与“为什么是这句话”说明，切换次数用日期键的 `AppStorage` 保存。

- [ ] **Step 4: 运行定向测试与构建**

- [ ] **Step 5: 提交**

`git commit -m "feat: add mood weather and quote cards"`

### Task 4: T-06 时间来信

**Files:**
- Modify: `DayGlyph/Models/TodaySupportModels.swift`
- Create: `DayGlyph/Views/Today/TimeLetterSection.swift`
- Modify: `DayGlyph/DayGlyphApp.swift`
- Test: `DayGlyphTests/TodaySupportPersistenceTests.swift`

- [ ] **Step 1: 写失败测试**

覆盖正文 1–500 字、最早七天后、每日最多展示一封到期来信，以及收下/今天先不看的状态转换。

- [ ] **Step 2: 运行测试确认失败**

- [ ] **Step 3: 实现模型、查询帮助函数和写信 Sheet**

未来档位仅提供 7 天、30 天、90 天，保存后只显示“已经收好，会在未来某天出现”；到期卡展示来源、正文和当时配方摘要，不自动比较好坏。

- [ ] **Step 4: 运行定向测试与构建**

- [ ] **Step 5: 提交**

`git commit -m "feat: implement local time letters"`

### Task 5: T-07 共情海本地 Demo

**Files:**
- Modify: `DayGlyph/Models/TodaySupportModels.swift`
- Create: `DayGlyph/Services/EmpathySeaDemoCatalog.swift`
- Create: `DayGlyph/Views/Today/EmpathySeaSection.swift`
- Modify: `DayGlyph/DayGlyphApp.swift`
- Test: `DayGlyphTests/EmpathySeaDemoTests.swift`
- Test: `DayGlyphTests/TodaySupportPersistenceTests.swift`

- [ ] **Step 1: 写失败测试**

覆盖公开副本与原始 `DayEntry.text` 相互独立、1–300 字限制、联系方式只提示不修改、审核中到固定回应状态、打捞内容举报状态。

- [ ] **Step 2: 运行测试确认失败**

- [ ] **Step 3: 实现本地目录和发送流程**

入口打开共情海页面；用户可打捞本地预置内容、发送固定中性回应或举报；匿名发送必须经过独立编辑、风险勾选和二次确认，保存为 `reviewing`，随后在本地 Demo 中转换为固定回应，不修改原记录。

- [ ] **Step 4: 运行定向测试与构建**

- [ ] **Step 5: 提交**

`git commit -m "feat: implement empathy sea demo flow"`

### Task 6: Today 顺序集成与阶段验收

**Files:**
- Modify: `DayGlyph/Views/Today/TodayHomeView.swift`
- Modify: `DayGlyph/Views/Today/CocktailResultView.swift`
- Delete: `DayGlyph/Views/Today/TodaySupportPlaceholders.swift`

- [ ] **Step 1: 集成固定模块顺序**

有记录：鸡尾酒 → 天气与名言 → 微行动 → 时间来信 → 共情海。无记录：空状态 → 微行动 → 时间来信 → 共情海；天气与名言等待生成配方后出现。

- [ ] **Step 2: 运行全量单元测试**

Run: `xcodebuild -project DayGlyph.xcodeproj -scheme DayGlyph -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:DayGlyphTests test`

Expected: `** TEST SUCCEEDED **`。

- [ ] **Step 3: 模拟器验收**

在 iPhone 17 检查有记录和无记录 Today；完整走通开始/完成行动、切换名言、写给未来、匿名副本确认、审核中、固定回应和举报；再用 375 pt 宽度设备检查无横向溢出、大字体下按钮改为纵向排列、命中区不小于 44 pt。

- [ ] **Step 4: 检查阶段边界**

确认未新增网络请求、未改 `ReminderService`、未实现行动回声反馈、未修改宇宙/Mine 业务。

