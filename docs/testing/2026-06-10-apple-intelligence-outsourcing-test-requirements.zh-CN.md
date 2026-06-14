# DayGlyph Apple Intelligence 外包测试需求

版本：1.0
日期：2026-06-10
测试基线：`main` 分支，commit `aed6e0fafc465f4b3ee303904fd77309448b7d6e`
测试目标：确认 DayGlyph 在真正可用的 Apple Intelligence 环境中调用 Foundation Models，而不是走本地规则回退。

## 1. 最重要的结论

“美版 Mac”本身不能证明测试环境合格。

候选人必须先证明：

```text
SystemLanguageModel.default.availability == available
```

只有返回 `available`，才能进入正式测试。以下状态均不合格：

- `deviceNotEligible`
- `appleIntelligenceNotEnabled`
- `modelNotReady`
- 任何编译失败、模块缺失或无法确认的状态

## 2. 候选人硬性要求

### 2.1 Mac

- 必须是 Apple silicon Mac，最低 M1。
- 优先选择在美国或其他非中国大陆市场购买的 Mac。
- 不接受中国大陆购买型号作为本次真实 Apple Intelligence 测试机。
- 必须是实体 Mac，不接受虚拟机、云 Mac 或远程模拟出的设备信息。
- 推荐 16 GB 或更高内存。Apple 没有把 16 GB 列为 Apple Intelligence 的硬性门槛，但 Xcode、iOS 模拟器和本地模型同时运行时更稳定。
- 建议至少保留 30 GB 可用磁盘空间。Apple Intelligence 模型本身可能占用约 7 GB，Xcode 和 iOS Simulator 还需要额外空间。

### 2.2 系统与开发环境

- macOS 26.2 或更高版本。
- 推荐使用 macOS 26.5.x，与当前项目开发环境接近。
- Xcode 26.5，Build 17F42。
- 必须安装 iOS 26.5 Simulator Runtime。
- 推荐测试设备：iPhone 17 模拟器，iOS 26.5。
- 当前项目 Deployment Target 为 iOS 26.5。

如果只能使用更高版本 Xcode，必须在报告中记录完整版本；不允许为了构建而修改项目 Deployment Target 或业务代码。

### 2.3 Apple Intelligence

- Mac 的“系统设置 > Apple Intelligence 与 Siri”中必须已开启 Apple Intelligence。
- 系统模型必须已经完成下载，不能处于“正在准备”状态。
- 设备语言和 Siri 语言必须设置为同一种 Apple Intelligence 支持语言。
- 为减少中文输出差异，优先使用：
  - 设备语言：简体中文
  - Siri 语言：普通话（中国大陆）
- 若中文配置无法使系统状态变为 `available`，可先使用英语（美国）完成环境验证，但正式中文情绪测试仍需要把 App 输入设为简体中文。
- 优先选择测试人员实际位于中国大陆以外的环境。
- Apple Account 国家或地区不能是中国大陆。

### 2.4 可选但优先

如果候选人还拥有以下实体设备，应优先录用：

- iPhone 15 Pro、iPhone 15 Pro Max，或更新且支持 Apple Intelligence 的 iPhone。
- iOS 26.5 或更高版本。
- Apple Intelligence 已启用并完成模型下载。

模拟器验证可以确认集成路径；Apple 官方仍建议在实体设备上完成最终验证。

## 3. 候选人预筛选

候选人在报价前必须提供以下材料。序列号必须打码，不需要提交 Apple ID、邮箱或其他隐私信息。

### 3.1 截图

1. “关于本机”截图：
   - 芯片型号
   - 内存
   - macOS 版本
2. “系统设置 > Apple Intelligence 与 Siri”截图：
   - Apple Intelligence 已开启
   - 不处于下载或准备状态
3. Xcode “About Xcode”截图：
   - Xcode 版本
   - Build 版本

### 3.2 终端输出

候选人执行：

```bash
sw_vers
xcodebuild -version
uname -m
system_profiler SPHardwareDataType | sed -n '1,20p'
xcrun swift -e 'import FoundationModels; print(SystemLanguageModel.default.availability)'
```

注意：

- `system_profiler` 输出中的序列号、Hardware UUID、Provisioning UDID 必须打码。
- 最后一条命令必须返回 `available`。
- 如果返回 `deviceNotEligible`、`appleIntelligenceNotEnabled` 或 `modelNotReady`，不得进入正式测试。

### 3.3 预筛选通过标准

- Apple silicon：通过。
- macOS 与 Xcode 满足版本要求：通过。
- Apple Intelligence 设置已开启：通过。
- Foundation Models 命令返回 `available`：通过。

最后一项是决定性条件。前三项满足但最后一项不满足，仍然淘汰。

## 4. 项目运行说明

### 4.1 项目信息

- Xcode 工程：`DayGlyph.xcodeproj`
- Scheme：`DayGlyph`
- Bundle ID：`dev.chinyen.DayGlyph`
- 测试目标：`DayGlyphTests`
- 推荐模拟器：iPhone 17，iOS 26.5
- Foundation Models 集成文件：
  - `DayGlyph/Services/AppleIntelligenceStatus.swift`
  - `DayGlyph/Services/FoundationEmotionAnalyzer.swift`
  - `DayGlyph/Services/UnifiedEmotionAnalyzer.swift`

### 4.2 构建

1. 打开 `DayGlyph.xcodeproj`。
2. 选择 `DayGlyph` Scheme。
3. 选择 iPhone 17、iOS 26.5 模拟器。
4. 执行 Product > Build。
5. 执行 Product > Run。

模拟器构建不需要开发者签名。测试人员不得修改业务代码、Bundle ID、Deployment Target 或 Foundation Models 实现。

### 4.3 自动化测试

执行：

```bash
xcodebuild \
  -project DayGlyph.xcodeproj \
  -scheme DayGlyph \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:DayGlyphTests \
  test
```

当前基线为 21 项单元测试。验收要求：

- 21 项全部通过。
- 0 个失败。
- 0 个编译错误。
- 不得因为修改项目配置而跳过测试。

## 5. 正式测试用例

## AI-ENV-001：宿主 Mac Foundation Models 可用

步骤：

1. 执行预筛选命令。
2. 保存完整终端输出。

预期：

```text
available
```

不通过条件：

- 返回任何 `unavailable`。
- 无法导入 `FoundationModels`。
- 测试人员只提供设置截图，但拒绝提供命令输出。

## AI-ENV-002：iOS 模拟器状态可用

步骤：

1. 在 iPhone 17、iOS 26.5 模拟器运行 DayGlyph。
2. 打开“今日”页。
3. 查看输入框下方的 Apple Intelligence 状态卡片。
4. 再打开“设置”页查看诊断区。

预期：

- 今日页显示：`Apple Intelligence 已就绪`
- 详情显示：`DayGlyph 会优先使用设备端模型理解记录。`
- 设置页状态同样显示已就绪。
- 不能显示：
  - `Apple Intelligence 尚未开启`
  - `Apple Intelligence 正在准备`
  - `此设备不符合运行条件`

## AI-FUNC-001：真实 Foundation Models 路径

步骤：

1. 在今日页输入：`今天很早就把那个事情搞完了，整个人松了一口气。`
2. 点击“生成今日一划”。
3. 等待结果出现。

预期：

- App 不崩溃、不冻结。
- 结果来源必须显示：`Apple Intelligence 已参与理解`
- 不能显示：`已使用本地回退`
- 情绪应为“平静”或“喜悦”。
- 主题应为“工作”。
- 解释文案非空，且能表达“完成、放松或释放感”。
- 关键词为 1 到 4 个。

这是本次外包测试最关键的通过条件。

## AI-FUNC-002：结构化输出完整性

对每条输入检查：

- 情绪只能是：平静、喜悦、低落、焦虑、激动、疲惫、感恩、混合。
- 主题只能是：工作、关系、成长、休息、家庭、健康、创造、日常。
- 能量值必须在 0% 到 100% 之间。
- 解释必须是简短中文且非空。
- 结果来源必须为 `Apple Intelligence 已参与理解`。
- 保存后重新进入页面，结果不能丢失。

## 6. 中文语义质量测试

每条语句连续测试 3 次，共 21 次。模型输出允许存在合理波动，不要求逐字相同。

| 编号 | 输入 | 可接受情绪 | 可接受主题 | 核心语义 |
|---|---|---|---|---|
| Q1 | 今天很早就把那个事情搞完了，整个人松了一口气。 | 平静、喜悦 | 工作 | 完成后的放松 |
| Q2 | 说不上来，脑子很乱，但还是把今天撑过去了。 | 焦虑、混合、低落 | 日常、成长、工作 | 混乱但坚持 |
| Q3 | 今天终于完成了项目，特别感谢同事帮我一起收尾。 | 感恩、喜悦 | 工作、关系 | 项目完成和感谢 |
| Q4 | 今天很累，睡得不好，什么都提不起劲。 | 疲惫、低落 | 休息、健康 | 低能量和睡眠不足 |
| Q5 | 今天去拿了快递，回来的路上买了杯热咖啡。 | 平静、混合 | 日常、休息 | 普通中性日常 |
| Q6 | 今早就搞完惹，终于可以歇会儿了。 | 平静、喜悦 | 工作、休息 | 能理解口语和错别字 |
| Q7 | 公司的钱又没按时发，真的很生气也很失望。 | 低落、焦虑、混合 | 工作 | 负面情绪，不能判为平静或喜悦 |

质量验收门槛：

- 21 次结果中，至少 17 次符合表格中的情绪和主题范围。
- Q1、Q4、Q7 各自至少 2/3 次通过。
- 21 次全部必须显示 `Apple Intelligence 已参与理解`。
- 不允许出现空解释、越界能量值或无法保存。
- Q7 不允许输出“平静”“喜悦”或“感恩”。

上述比例是 DayGlyph 项目验收指标，不是 Apple 官方指标。

## 7. 性能测试

### AI-PERF-001：首次生成

1. 冷启动 App。
2. 输入 Q1。
3. 从点击按钮开始计时，到结果卡完整出现结束。

建议验收：

- 30 秒内完成。
- 点击后立即显示“正在理解今天”，界面不能无反馈。

### AI-PERF-002：模型预热后生成

1. 保持 App 运行。
2. 依次测试 Q2 到 Q7。
3. 记录每次耗时。

项目验收：

- 中位数不高于 8 秒。
- 95 分位不高于 15 秒。
- 不出现永久加载、崩溃或自动退出。

性能门槛为本项目建议值，需同时记录 Mac 型号、芯片和内存。

## 8. 离线测试

Apple Foundation Models 的设计目标是设备端运行。必须验证模型完成下载后的离线行为。

步骤：

1. 先在联网状态确认 AI-ENV-002 和 AI-FUNC-001 通过。
2. 关闭 Mac 的 Wi-Fi，并确认没有其他网络连接。
3. 完全退出并重新启动 DayGlyph。
4. 分别测试 Q1、Q4、Q7。

预期：

- 三次均能完成。
- 三次均显示 `Apple Intelligence 已参与理解`。
- 不因为断网自动变为本地回退。
- 记录能够正常保存。

如果离线失败，必须记录：

- Apple Intelligence 设置状态。
- `SystemLanguageModel.default.availability` 输出。
- 失败前是否已完成模型下载。
- App 显示的是哪一种来源标签。

## 9. 回退测试

本轮外包的主要任务是真实 AI 路径，回退路径已在开发机和自动化测试中验证。

如果测试人员要验证回退，必须放在所有真实 AI 测试完成之后，因为关闭 Apple Intelligence 可能移除本地模型并触发重新下载。

回退预期：

- Apple Intelligence 关闭或不可用时，App 仍可生成和保存记录。
- 结果来源显示：`已使用本地回退`
- 不能显示：`Apple Intelligence 已参与理解`
- 重新开启并等待模型准备完成后，状态恢复为 `Apple Intelligence 已就绪`。

## 10. 稳定性与持久化

### AI-STAB-001：连续生成

- 连续执行 20 次不同文本分析。
- 不允许崩溃、卡死或出现无法点击。
- 每次只保留当天一条记录，后续输入应更新当天记录，而不是无限新增同日记录。

### AI-STAB-002：重启持久化

1. 完成一次 Apple Intelligence 分析。
2. 强制退出 App。
3. 再次打开。

预期：

- 当天文本仍存在。
- 情绪、主题、能量、解释和来源仍存在。
- 来源仍显示 `Apple Intelligence 已参与理解`。

### AI-STAB-003：空输入

- 空输入或只有空格时，“生成今日一划”按钮不可用。
- 不创建空记录。

## 11. 可选实体设备测试

如果测试人员有兼容 iPhone：

1. 使用 iPhone 15 Pro 或更新的兼容设备。
2. iOS 26.5 或更高版本。
3. Apple Intelligence 已开启并完成模型下载。
4. 在 Xcode 中配置个人开发团队；如签名要求冲突，可仅修改签名团队，不得修改业务代码。
5. 重复 AI-ENV-002、AI-FUNC-001、中文质量测试、离线测试和重启测试。

实体设备报告必须与模拟器结果分开，不能混在同一统计表中。

## 12. 必须回传的证据

### 12.1 环境证据

- 关于本机截图，序列号打码。
- Apple Intelligence 设置截图。
- Xcode 版本截图。
- 预筛选终端输出。
- iOS 模拟器设备与系统版本截图。

### 12.2 功能证据

- 今日页显示 `Apple Intelligence 已就绪` 的截图。
- 设置页诊断截图。
- Q1、Q4、Q7 每次结果截图。
- 至少一段从输入到结果出现的完整录屏。
- 离线测试录屏或连续截图。

### 12.3 报告数据

每次测试记录：

| 字段 | 内容 |
|---|---|
| 测试编号 | 例如 AI-FUNC-001 |
| Mac 型号 | 例如 MacBook Air M3 |
| macOS | 完整版本 |
| Xcode | 版本和 Build |
| 模拟器 | 设备名和 iOS 版本 |
| 输入文本 | 原文 |
| 输出情绪 | App 显示值 |
| 输出主题 | App 显示值 |
| 能量 | 百分比 |
| 解释 | App 显示原文 |
| 来源 | 必须记录 |
| 耗时 | 秒 |
| 网络状态 | 在线或离线 |
| 结果 | 通过或失败 |
| 证据文件名 | 截图或视频名称 |

## 13. 失败报告要求

出现失败时不能只写“AI 不可用”。必须提供：

1. 完整复现步骤。
2. 实际显示文案。
3. 期望结果。
4. `SystemLanguageModel.default.availability` 输出。
5. Mac、macOS、Xcode 和模拟器版本。
6. 是否联网。
7. 是否刚开启 Apple Intelligence 或正在下载模型。
8. 截图或录屏。
9. 能否稳定复现，以及复现次数。

不得提交 Apple ID 密码、验证码、完整序列号或其他敏感信息。

## 14. 最终通过标准

必须同时满足：

- 候选人的 Foundation Models 预筛选输出为 `available`。
- DayGlyph 今日页显示 `Apple Intelligence 已就绪`。
- AI-FUNC-001 结果显示 `Apple Intelligence 已参与理解`。
- 21 次中文语义测试至少 17 次通过。
- Q1、Q4、Q7 各至少 2/3 次通过。
- 离线测试 3/3 通过。
- 21 项自动化单元测试全部通过。
- 无崩溃、无永久加载、无数据丢失。
- 所有要求的截图、录屏和测试表完整提交。

任一关键项不满足，本轮真实 Apple Intelligence 验收不通过。

## 15. 可直接发布的外包招募文案

```text
寻找一名拥有非中国大陆版本 Apple silicon Mac 的 iOS 测试人员，
验证一款 iOS 26.5 SwiftUI App 的 Apple Intelligence Foundation Models 集成。

硬性条件：
1. Apple silicon Mac，M1 或更新；
2. macOS 26.2+，优先 macOS 26.5；
3. Xcode 26.5，并安装 iOS 26.5 Simulator；
4. Apple Intelligence 已开启且模型下载完成；
5. Apple Account 国家或地区非中国大陆；
6. 能执行以下命令，并确保结果为 available：
   xcrun swift -e 'import FoundationModels; print(SystemLanguageModel.default.availability)'
7. 能提供屏幕录制、截图、测试表和完整环境信息；
8. 序列号等敏感信息可打码。

优先条件：
- 人在中国大陆以外；
- 另有 iPhone 15 Pro 或更新的 Apple Intelligence 兼容 iPhone；
- 有 iOS/Xcode 测试经验；
- 能测试中文自然语言和离线模型。

请报价前先提交：
- 关于本机截图；
- Apple Intelligence 设置截图；
- Xcode 版本截图；
- Foundation Models availability 命令输出。
只有命令返回 available 才进入正式测试。
```

## 16. 官方参考

- Apple Intelligence 使用要求、支持设备、语言与中国大陆限制：
  https://support.apple.com/zh-cn/121115
- Foundation Models 框架：
  https://developer.apple.com/documentation/FoundationModels
- Xcode 系统要求：
  https://developer.apple.com/support/xcode/
- Apple Developer Forums：Foundation Models 在模拟器中使用宿主 Mac 模型：
  https://developer.apple.com/forums/thread/787199
