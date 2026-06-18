# DayGlyph 接近正式版本 README 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 将仓库首页升级为产品展示优先、工程信息完整的接近正式版本说明。

**架构：** 仅修改根目录 `README.md`，使用仓库现有图片和文档相对链接。首页先解释产品价值与四模块体验，再提供架构、运行、验证和版本边界。

**技术栈：** GitHub Flavored Markdown、SwiftUI 项目现有文档与图片资产

---

### 任务 1：重写产品与工程 README

**文件：**
- 修改：`README.md`

- [ ] **步骤 1：替换过时产品状态**

删除“产品原型”“模块占位”等旧描述，首屏使用以下定位：

```markdown
# DayGlyph

把难以描述的感受，调制成一杯情绪鸡尾酒，凝结为一颗属于今天的星球。

DayGlyph 是一款本地优先、非医疗化的 iOS 情绪记录与自我观察应用。
```

- [ ] **步骤 2：写入产品展示结构**

按“核心体验、四个模块、产品原则、当前版本能力”的顺序说明完整闭环，使用 `images/47c5c838fbdc6ea02f64344358eb48d9e82f8587ca5eb0e13d691c5a0d78bdce.jpg` 作为核心视觉。

- [ ] **步骤 3：写入工程结构**

准确列出 SwiftUI、SwiftData、Foundation Models 统一分析入口、RealityKit、Charts、App Intents、UserNotifications 和 Swift Testing，并给出 `DayGlyph.xcodeproj` 的启动、构建和测试命令。

- [ ] **步骤 4：加入文档入口与边界**

链接 `产品文档.md`、`设计路线图.md`、`docs/superpowers/specs/`、`docs/superpowers/plans/` 和专项测试要求，明确当前仍持续迭代、公开社交为本地演示、产品不提供医疗诊断或治疗建议。

### 任务 2：验证并发布

**文件：**
- 验证：`README.md`

- [ ] **步骤 1：校验相对链接**

运行脚本提取 `README.md` 中的本地 Markdown 链接，逐个确认目标存在；预期输出为 `全部本地链接有效`。

- [ ] **步骤 2：校验内容与格式**

运行：

```bash
rg -n '占位|暂不代表正式发布版本|TBD|TODO' README.md
git diff --check
```

预期：第一条无匹配，第二条退出码为 0。

- [ ] **步骤 3：提交并推送**

```bash
git add README.md docs/superpowers/plans/2026-06-18-dayglyph-release-readme.zh-CN.md
git commit -m "docs: present dayglyph as release candidate"
git push origin main
```

- [ ] **步骤 4：核对远端**

确认 `git rev-parse HEAD` 与 `git rev-parse origin/main` 一致，并提供建议仓库名及 GitHub 描述给用户。
