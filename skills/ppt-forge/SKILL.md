---
name: ppt-forge
description: >
  华为风格高密度 PPT 全链路工作流 skill：内容规划 → 风格定调 → Slide 制作 → 视觉审查 → 导出验证 → 交付。
  Use when: 做 PPT、做演示文稿、做 slide、做海报、PPT review、视觉审查、华为/Apple/阿里风格对标。
  Not for: 纯代码开发、纯文档写作。
  Output: 高密度 HTML slide + 多角色审查通过 + 导出验证。
---

# PPT Forge — 华为风格 PPT 生产线

## 核心原则

**PPT 不是一个人的活，是作者 + 两位独立审查员的流水线。**

| 角色 | 职责 |
|------|------|
| author（作者） | 内容规划 + HTML 制作 + density gate 自检 |
| D1 reviewer | 布局/信息审查 + Export Truth Gate |
| D2 reviewer | 审美/品牌审查 + 风格定调 |

三条贯穿全流程的原则：

1. **愿景优先 > 局部门禁** — 不为满足单一数值门禁（字号、留白、整洁）把页面改成另一种 archetype。
2. **混合布局 >> 单一 grid** — 每页至少混合 3 种以上填充手段。
3. **先审"对不对"，再审"像不像"** — D1 未过不进 D2。

## 开局参数（必须声明）

| 参数 | 说明 | 示例 |
|------|------|------|
| 页型（archetype） | 决定密度、字号矩阵和信息组织方式 | 华为高密战略页 / KPI Dashboard / 发布会结论页 |
| 品牌 | 对标公司的视觉基因 | 华为 / Apple / 阿里 |
| 受众 | 谁看这个 PPT | CTO / 投资人 / 技术团队 |
| 场景 | PPT 用在哪 | 年会汇报 / 客户提案 / 内部分享 |
| 主观看模式 | 影响字号/密度/留白标准 | presentation（大屏）/ document（PDF 阅读） |

**没有开局参数 = 开工和审查都没有标准。开工前必须先锁这 5 项。**

## 场景路由

| 触发 | 场景 | 主导 | 详细文档 |
|------|------|------|---------|
| 铲屎官说"做个 PPT" | **A: 内容规划** | author | 本文件内联（下方） |
| 大纲确认 | **B: 风格定调** | D2 reviewer 审 + author 做 | [01-style-tile.md](01-style-tile.md) |
| 风格确认 | **C: Slide 批量制作** | author | [02-slide-authoring.md](02-slide-authoring.md) |
| Slide 做完 | **D: 视觉审查 Gate** | D1(布局) + D2(审美) | [03-visual-review.md](03-visual-review.md) |
| 审查通过 | **E: Export Truth Gate** | D1 reviewer | 本文件内联（下方） |
| 导出验证通过 | **F: 交付** | author | [04-delivery.md](04-delivery.md) |
| 需要对比竞品 | **G: Benchmark 对拍** | D1 + D2 | 本文件内联（下方） |
| 铲屎官不满意 / 连续 2 轮 P1>0 | **R: 翻盘重来** | 全员 | 本文件内联（下方） |

## 共享契约：6 件套视觉审查输入包

每次发起视觉审查（D 场景），author 必须附带以下 6 项。缺任何一项 → 不进审，打回补齐。

| # | 内容 | 说明 |
|---|---|---|
| 1 | 品牌+受众 brief | 目标公司、受众角色 |
| 1b | **页型（archetype）** | 华为高密战略页 / 发布会结论页 / KPI Dashboard / PDF handout 等 |
| 1c | **主观看模式** | presentation（大屏投影）/ document（PDF/打印）/ hybrid — **必须选主模式** |
| 2 | 本页目的 | 一句话：这页要让读者得到什么结论 |
| 3 | 截图/预览 URL | 浏览器渲染结果 |
| 4 | HTML/CSS 源码路径 | 定位布局 bug 的依据 |
| 5 | 密度数据 | whitespace%、element count、text nodes、overflow |
| 6 | 导出真相（如已导出） | native text / chart / table / screenshot fallback |

> 没有 6 件套 = 观感点评；有 6 件套 = P1/P2 级审查。

## 共享契约：页型字号矩阵

**页型决定字号，不是字号决定页型。** reviewer 不能在不改 archetype 的情况下要求不匹配的字号。

| 页型 | 正文下限 | 辅助信息下限 | 典型场景 |
|------|---------|------------|---------|
| 发布会 / 对外 keynote | 14px | 12px | Steve Jobs 风、产品发布 |
| 华为高密战略页 | 10px | 8px | 内部战略分析、组件状态矩阵、行业对比 |
| KPI Dashboard | 12px（正文）| 9px（标签）| 数据看板、指标监控 |
| PDF handout / document | 9px | 8px | 会后阅读材料、打印稿 |

> **血泪教训**：R3 事件证明"一刀切 14px"会逼迫作者砍内容来满足字号，最终把高密战略页改成低密结论页。字号门禁必须跟着 archetype 走。

## A: 内容规划（内联最小真相源）

- 先锁 5 项开局参数：`archetype / 品牌 / 受众 / 场景 / 主观看模式`
- 至少产出三样东西：
  1. **本页目的一句话**（如"证明对等判断优于中央编排"）
  2. **证据源列表**（具体到文件/git log/截图路径）
  3. **页面结构草图**（哪里放标题、哪里放 KPI、哪里放流程图）
- 没说清"这页让人看完要得出什么结论" → 不进 B，不进 C

## E: Export Truth Gate（内联最小真相源）

审查每一页的导出质量，任何一项说不清 → 不进 F：

- **native text** — 文字是否导出为原生可选可搜索文本？
- **native chart** — 图表是否导出为原生图表对象（PowerPoint 可编辑）？
- **native table** — 表格是否导出为原生表格（不是截图）？
- **screenshot fallback** — 无法原生化的部分是否有截图兜底？分辨率是否够？
- **repair dialog** — 导出后 PowerPoint 打开是否弹"修复文件"对话框？

关键数值：`PX_PER_INCH = 96`（LAYOUT_WIDE 13.33"×7.5"），CSS px → PPTX pt 系数 = 0.75（px × 72/96）。

## G: Benchmark 对拍（内联最小真相源）

需要和竞品/参考案例对比时：

- **必须同 archetype** — 不能拿发布会页对拍高密战略页
- **必须同主题** — 同一话题不同公司的处理方式
- **必须同主观看模式** — 大屏 vs PDF 的标准不同

至少对拍 4 个维度：
1. **信息密度** — 同尺寸下容纳的有效信息量
2. **事实保留** — 说过的数据/事实/论据是否都在
3. **说服力** — 受众看完是否被说服
4. **品牌贴合度** — 和目标品牌的视觉语言一致性

## R: 翻盘重来（内联最小真相源）

触发条件：
- 连续 2 轮 P1>0（两次审查都有 P1 级问题未修）
- 铲屎官说"方向不对"
- reviewer 对 archetype 有实质分歧

处理流程：
1. **直接回到 A 或 B**，不准在坏页型上继续缝补
2. **先写 Author Synthesis**：说明这次为什么要重开、上一版的根本问题是什么、新方向的 archetype 和目的
3. Author Synthesis 通过后才能开 C

## 审查维度速查

### D1: 布局/信息审查

| 级别 | 维度 | 判定 |
|------|------|------|
| P1 | 布局 bug | 真实 CSS/HTML 错误（如 overflow、grid 错分配） |
| P1 | 信息失败 | 没讲清重点 / 层级错 / 受众看不懂 |
| P1 | 密度失衡 | 该密不密 / 该疏不疏 |
| P1 | 页型漂移 | 修改让页面从既定 archetype 漂到另一类 |

### D2: 审美/品牌审查

| 级别 | 维度 | 判定 |
|------|------|------|
| P1 | 严重审美事故 | 配色完全错误或对比度不可读 |
| P2 | 品牌偏移 | 不像目标公司的设计语言 |
| P2 | 视觉一致性 | 字号/卡片/边框/图标语言不统一 |

审美五维：色彩体系 · 字体排印 · 空间网格 · 视觉元素 · 密度平衡

## 密度填充手法

详见 [references/density-playbook.md](references/density-playbook.md)（8 种填充手段 + SmartArt/截图 CSS 模板 + spike 教训）

## Common Mistakes

| 错误 | 后果 | 修复 |
|------|------|------|
| 没声明开局参数 | 开工和审查没有标准 | 开工前锁 `archetype + 品牌 + 受众 + 场景 + 主观看模式` |
| 20 页全做完才审 | 返工成本爆炸 | B 场景：先做 1-2 页核心页定调 |
| 自己说"没问题"不截图 | 布局 bug 漏检 | 自检必须截图看一遍再交活 |
| 审查只给截图没给 HTML | 只能说"这里怪" | 必须带 6 件套 |
| reviewer 改页型 | 高密战略页被改成低密结论页 | Archetype Guard（见 03-visual-review.md）|
| 跳过 Export Gate | 导出后不可编辑/乱码 | 独立验证导出质量 |
| 只报路径不开预览 | 铲屎官要自己找、自己开 | 04-delivery.md：强制 browser-preview |

## 外部 skill 依赖（可选）

本 skill 只覆盖 PPT 制作本身。以下是可选的上下游 skill：

- **browser-preview** — 04-delivery.md F 场景要求的内嵌浏览器预览。已在 04-delivery.md 内联调用方式和降级顺序（Chrome MCP navigate → 截图+URL），不强制依赖外部实现。
- **feat-lifecycle** — 若本次 PPT 是某 feature 交付物的一部分，F 场景完成后可衔接该外部 skill 做 feature 归档。与本 skill 无直接关系。

## 和其他常见 skill 的区别

- **代码审查 skill** — 审查代码，本 skill D 场景审查 HTML/CSS 渲染结果
- **通用文档写作** — 写纯文字，本 skill 做可视化信息设计
- **通用 design skill** — 做 UI/UX，本 skill 专攻信息型密集 slide
