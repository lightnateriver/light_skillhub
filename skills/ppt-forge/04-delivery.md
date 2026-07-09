---
name: ppt-delivery
description: PPT 交付流程 — 强制 browser-preview 内嵌浏览器预览 + 密度报告 + 等铲屎官确认。F 场景详细流程。
---

# 04 · 交付（F 场景）

> 触发：视觉审查（D）通过 + 导出验证（E）通过后。

## 核心原则

**交付不是"文件丢过去"，是"让铲屎官看到效果"。**

- 铲屎官不应该需要切窗口、找文件、手动打开浏览器
- 交付 = 打开预览 + 说清楚做了什么 + 等确认

## 交付物清单

每次交付必须包含：

| 项目 | 格式 | 说明 |
|------|------|------|
| HTML 预览 | 浏览器内打开 | **强制用 browser-preview** |
| 截图 | PNG 1280×720 | Playwright 截图存档 |
| 密度报告 | 文字 | elements / text nodes / chars / overflow / fill% |
| 源文件 | HTML | 路径 + commit SHA |
| PPTX（如有） | .pptx | V2 compiler pipeline 输出 |

## 交付流程

```
1. 确认 HTTP server 在跑（python3 -m http.server {port}）
2. 用 browser-preview skill 打开到 workspace 内嵌浏览器
3. 发消息给铲屎官，附：
   - 预览已开到 workspace 浏览器（不用切窗口）
   - 密度报告一行摘要
   - 和上一版的关键变化点
4. 等铲屎官确认
```

### 浏览器预览（硬要求）

**完成 PPT HTML 后，必须用 `browser-preview` skill 打开到 workspace 内嵌浏览器。**

不要只报 URL 让铲屎官自己去开。不要只贴截图。

如果 browser-preview 不可用（MCP 断连等），降级顺序：

1. 用 Chrome MCP `navigate` 打开到铲屎官当前浏览器
2. 截图 + URL 作为最后手段

### 消息模板

```markdown
PPT 交付：{页面标题}

预览已开到 workspace 浏览器。

密度：{N} elements / {N} text / {N} chars / 0 overflow / {N}% fill
变化：{和上一版的 1-2 句差异}
源文件：`{path}` @ {commit SHA}

请确认或提修改意见。
```

## 铲屎官反馈处理

| 反馈 | 处理 |
|------|------|
| "可以" / "不错" | 交付完成（如需衔接 feature 归档，走外部 feat-lifecycle skill） |
| "这里改一下" | 回 02-slide-authoring，改完重新交付 |
| "方向不对" | **STOP**，回 A 场景内容规划重新对齐（见 SKILL.md R: 翻盘重来）|
| "和{竞品}比一下" | 进 G 场景 Benchmark 对拍（见 SKILL.md）|

## Common Mistakes

| 错误 | 后果 | 修复 |
|------|------|------|
| 只报路径不打开预览 | 铲屎官要自己找、自己开 | 强制 browser-preview |
| 没等铲屎官确认就进下一步 | 方向偏了不知道 | 交付必须等确认 |
| 截图分辨率太低 | 铲屎官看不清细节 | Playwright 1280×720 截图 |
| HTTP server 没开 | 预览打不开 | 交付前确认 server 在跑 |
