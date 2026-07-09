# light_skillhub

个人 AI Agent skills 仓库，跨 Hermes / Codex / Claude Code 多端同步。
基于 `SKILL.md` 格式（YAML frontmatter + markdown 指令），统一管理、一键部署。

---

## 在新服务器上安装

```bash
# 1. 克隆到约定位置
git clone https://github.com/lightnateriver/light_skillhub /root/clawcos/skills

# 2. 安装到当前机器的 AI 工具
cd /root/clawcos/skills
bash sync.sh --all        # 检测并安装到 Hermes + Codex + Claude Code
```

AI agent（你）在接管新服务器后，看到 `AGENTS.md` 或用户提及 skills，就应该执行以上两步。

---

## sync.sh 用法

| 参数 | 作用 |
|------|------|
| `--all` | 安装到所有已检测到的工具 |
| `--hermes` | 仅 Hermes (`~/.hermes/skills/`) |
| `--codex` | 仅 Codex (`~/.codex/skills/`) |
| `--claude` | 仅 Claude Code (`~/.claude/skills/`) |
| `--link` | 软链接模式（默认，更新仓库即时生效） |
| `--copy` | 复制模式（更新后需重新运行） |
| `--dry-run` | 预览不执行 |

无参数时进入交互选择模式。

---

## 目录结构

```
/root/clawcos/skills/
├── skills/               ← 所有 skill，每个目录含 SKILL.md + 附属文件
│   ├── paper-deep-read/     论文精读（3 层分析 + PDF 解析）
│   ├── ppt-forge/           华为风格高密度 PPT 制作
│   ├── html-ppt/            HTML 幻灯片制作
│   ├── chinese-messaging-platforms/  飞书/钉钉/企微等网关配置
│   ├── hermes-ops/          Hermes 运维
│   ├── external-agent-coordination/  多 agent 协作
│   ├── ascend-dmi/          Ascend NPU 诊断工具
│   └── ... 共 54 个
├── sync.sh
├── README.md
└── .gitignore
```

---

## 日常维护

- **添加 skill**：在 `skills/` 下建目录，写 `SKILL.md` → `git add && commit && push`
- **更新**：编辑对应文件 → 提交推送
- **删除**：`git rm -r skills/<name>/` → 提交推送
- **同步到其他服务器**：`git pull && bash sync.sh --all`

---

## 支持的 AI 工具

| 工具 | skill 路径 | 同步方式 |
|------|-----------|--------|
| Hermes Agent | `~/.hermes/skills/<name>/SKILL.md` | 软链接 |
| Codex CLI | `~/.codex/skills/<name>/SKILL.md` | 软链接 |
| Claude Code | `~/.claude/skills/<name>.md` | 复制（单文件） |
