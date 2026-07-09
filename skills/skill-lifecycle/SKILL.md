---
name: skill-lifecycle
category: ops
description: >
  Cross-tool skill lifecycle management: centralize skills in a Git repo,
  sync to Hermes / Codex CLI / Claude Code on multiple servers, and keep
  them in sync. Covers repo structure conventions, symlink-based sync,
  install-from-archive workflow, and first-time setup on new machines.
  Use when: setting up skills on a new server, organizing a skill repo,
  syncing skills across machines, or onboarding a new AI coding agent.
  Not for: writing individual skills (that's the skill's own domain),
  runtime agent coordination (see external-agent-coordination), or
  dashboard/server ops (see hermes-ops).
---
# Skill Lifecycle — Cross-Tool Centralized Skill Management

## Core Idea

Maintain a **single GitHub repo** as the source of truth for all your skills.
Each server (home dev box, cloud GPU instance, CI runner) clones the repo
and uses a `sync.sh` script to install/update skills for every AI tool on
that machine.

```
GitHub Repo (source of truth)
  └─ skills/                ← each skill = one subdirectory
       ├── paper-deep-read/
       ├── ppt-forge/
       └── ...

Server A                    Server B                    Server C
  ├─ ~/.hermes/skills/*       ├─ ~/.hermes/skills/*       ├─ ~/.hermes/skills/*
  ├─ ~/.codex/skills/*        └─ ~/.claude/skills/*       └─ ...
  └─ ~/.claude/skills/*
```

## Repository Structure Convention

Skills must be compatible with **both** Hermes and Codex CLI's formats
(they share the same convention). Claude Code expects plain `.md` files
and can use symlinks.

```
skill-repo/
├── README.md                    ← overview + quick-start
├── sync.sh                      ← the sync script (copy or symlink)
├── skills/                      ← one dir per skill
│   ├── my-skill-name/           ← directory name = skill slug
│   │   ├── SKILL.md             ← required: YAML frontmatter + body
│   │   ├── references/          ← optional: session-specific detail
│   │   │   ├── deep-dive.md
│   │   │   └── ...
│   │   ├── templates/           ← optional: starter files (boilerplate)
│   │   ├── scripts/             ← optional: re-runnable actions
│   │   └── _meta.json           ← optional: metadata (version, owner)
│   ├── another-skill/
│   └── ...
└── .gitignore
```

### SKILL.md Frontmatter (Hermes / Codex Compatible)

```yaml
---
name: my-skill-name
description: >
  One-paragraph description. Use when: <trigger cases>.
  Not for: <exclusions>.
---
```

Required fields: `name`, `description`. Optional: `tags`, `category`, `triggers`.

### File Naming Rules

| File | Requirement |
|------|-------------|
| Directory name | Lowercase, hyphens or underscores, max 64 chars. Must match the `name` in SKILL.md frontmatter. |
| `SKILL.md` | Always uppercase S-K-I-L-L dot md. Required in every skill dir. |
| `references/` | Support files that inform the agent's work (error transcripts, API docs, domain notes). |
| `templates/` | Starter files meant to be copied and modified (boilerplate configs, scaffolding). |
| `scripts/` | Statically re-runnable actions the skill can invoke (verification, fixtures, probes). |
| `_meta.json` | JSON with `ownerId`, `publishedAt` (epoch ms), `slug`, `version`. Optional. |

## The Sync Script (`sync.sh`)

Place this at the repo root. It detects which tools are installed and
symlinks/installs skills to the right places.

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"

# ── Tools & their skill directories ──
declare -A TOOL_DIRS
TOOL_DIRS[hermes]="$HOME/.hermes/skills"
TOOL_DIRS[codex]="$HOME/.codex/skills"
# Claude Code: plain .md files in ~/.claude/skills/ — handled separately below

echo "=== Syncing skills ==="

for tool in "${!TOOL_DIRS[@]}"; do
    target="${TOOL_DIRS[$tool]}"
    if [ ! -d "$target" ]; then
        echo "  [SKIP] $tool: $target not found"
        continue
    fi
    echo "  [SYNC] $tool → $target"
    for skill_dir in "$SKILLS_SRC"/*/; do
        skill_name="$(basename "$skill_dir")"
        # Remove existing symlink/dir then install
        rm -f "$target/$skill_name" 2>/dev/null || true
        ln -sf "$skill_dir" "$target/$skill_name"
    done
done

# ── Claude Code (flat .md files) ──
if [ -d "$HOME/.claude/skills" ]; then
    echo "  [SYNC] claude-code → $HOME/.claude/skills"
    for skill_dir in "$SKILLS_SRC"/*/; do
        skill_file="$skill_dir/SKILL.md"
        if [ -f "$skill_file" ]; then
            skill_name="$(basename "$skill_dir").md"
            ln -sf "$skill_file" "$HOME/.claude/skills/$skill_name"
        fi
    done
fi

echo "=== Done ==="
```

### Usage on New Machine

```bash
git clone https://github.com/YOUR_ORG/skill-repo.git /opt/skills
cd /opt/skills
bash sync.sh
```

For **one-time** install (no repo): download a skill zip/tar, extract into
the tool's skills directory directly:

```bash
# Hermes
unzip skill-package.zip -d ~/.hermes/skills/<name>/

# Codex (same format)
unzip skill-package.zip -d ~/.codex/skills/<name>/

# Claude Code
cp skill/SKILL.md ~/.claude/skills/<name>.md
```

## Tool-Specific Notes

### Hermes Agent

| Feature | Detail |
|---------|--------|
| Skills dir | `~/.hermes/skills/<name>/SKILL.md` |
| Directory-based | One subdirectory per skill, SKILL.md at root |
| `skills_list` | Shows all installed skills by name + description |
| `skill_view` | Loads SKILL.md + linked files |
| Support files | `references/`, `templates/`, `scripts/` subdirectories |
| Category support | `category` field in SKILL.md groups skills |
| Bundled skills | Protected — cannot edit (shipped with Hermes) |
| Pinned skills | Protected from deletion only; content updates still allowed |

### Codex CLI

| Feature | Detail |
|---------|--------|
| Skills dir | `~/.codex/skills/<name>/SKILL.md` |
| Format | **Same as Hermes** — SKILL.md with YAML frontmatter |
| Built-in skills | Stored in `~/.codex/skills/.system/` |
| Custom rules | `~/.codex/rules/default.rules` for approval bypass |

### Claude Code

| Feature | Detail |
|---------|--------|
| Skills dir | `~/.claude/skills/` |
| Format | Flat `.md` files (one file per skill, no subdirectory) |
| Frontmatter | Optional — Claude reads YAML frontmatter but doesn't require it |
| Symlink support | Symlinks work: `ln -s <repo>/<skill>/SKILL.md ~/.claude/skills/<name>.md` |

## Pitfalls

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Skill dir name != `name:` in frontmatter | `skill_view` fails to find it | Keep directory slug and frontmatter name identical |
| Mixing Hermes/Codex dirs with flat Claude files on sync | Symlink conflict | Use script that handles each tool's format separately |
| Adding skills directly in `~/.hermes/skills/` without updating repo | Skills lost on next server | Always add skills to the repo, then sync outward |
| Not running `sync.sh` after `git pull` | Stale skills on the machine | Add a cron job or makefile target: `git pull && bash sync.sh` |
| Installing from zip without checking `_meta.json` | Version confusion | Check or write `_meta.json` for version tracking |

## First-Server Setup Checklist

1. `mkdir -p /root/clawcos/skills && cd /root/clawcos/skills`
2. `git clone <repo-url> .` or copy skill packages here
3. Install each skill:
   - From zip: `unzip <pkg>.zip -d ~/.hermes/skills/<name>/`
   - From cloned repo: `cp -r <repo>/skills/<name>/ ~/.hermes/skills/<name>/`
4. Verify: `skill_view('<name>')` returns success
5. Run `sync.sh` for Codex/Claude if applicable
6. (Optional) Schedule auto-sync:
   ```bash
   hermes cron create \
     --schedule "0 6 * * 1" \
     --prompt "git -C /root/clawcos/skills pull && bash sync.sh" \
     --name "weekly-skill-sync"
   ```

## Related Skills

- **hermes-ops** — Dashboard & server operations (separate concern from skills)
- **external-agent-coordination** — Runtime coordination of Hermes + Codex/Copilot for task execution, not skill management
