# Hermes/Codex/Claude Code Skills 同步仓库

将个人 AI Agent skills 统一管理、多端同步。

## 目录结构

```
skills/
├── skills/               ← 所有 skill 目录（扁平化），每个含 SKILL.md
│   ├── paper-deep-read/
│   ├── ppt-forge/
│   ├── html-ppt/
│   ├── chinese-messaging-platforms/
│   ├── hermes-ops/
│   └── ... 共 54 个
├── sync.sh               ← 一键同步到本地各工具
├── README.md
└── .gitignore
```

## 新服务器首次部署

```bash
git clone <你的仓库URL> /root/clawcos/skills
cd /root/clawcos/skills
bash sync.sh --all
```

## sync.sh 用法

| 参数 | 说明 |
|------|------|
| `--all` | 同步到所有已安装的工具 |
| `--hermes` | 只同步到 Hermes (`~/.hermes/skills/`) |
| `--codex` | 只同步到 Codex (`~/.codex/skills/`) |
| `--claude` | 只同步到 Claude Code (`~/.claude/skills/`) |
| `--link` | 使用软链接（默认），更新仓库即生效 |
| `--copy` | 使用文件复制，更新后需重新运行 |
| `--dry-run` | 预览，不实际执行 |

不传参数时进入交互模式，可选同步目标。

## 维护指南

- **添加 skill**：在 `skills/` 下新建目录，内含 `SKILL.md` + 参考文件，提交 git
- **更新 skill**：直接修改对应目录下的文件，提交即可
- **删除 skill**：`git rm -r skills/<name>/`，提交
- **多服务器更新**：每台服务器 `git pull && bash sync.sh --all`

## 支持的工具

| 工具 | 格式 | 同步方式 |
|------|------|---------|
| Hermes Agent | `<name>/SKILL.md`（目录） | 软链接/复制 |
| Codex CLI | `<name>/SKILL.md`（目录） | 软链接/复制 |
| Claude Code | `<name>.md`（单文件） | 复制 SKILL.md 为 `.md` |
