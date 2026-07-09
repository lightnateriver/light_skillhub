# Codex CLI Integration Reference

## Version detected
- **Version:** Codex CLI v0.142.0
- **Binary:** `/root/.nvm/versions/node/v22.22.0/bin/codex`
- **Config dir:** `~/.codex/config.toml`
- **Data dir:** `~/.codex/` (history, logs, state, sessions)
- **Rules dir:** `~/.codex/rules/default.rules`
- **Auth:** `~/.codex/auth.json`

## Config snapshot (as of this session)

```toml
model_provider                 = "oaiapi"
model                          = "gpt-5.4"
model_reasoning_effort         = "xhigh"
network_access                 = "enabled"
disable_response_storage       = true
model_verbosity                = "medium"
personality                    = "friendly"
approval_policy                = "untrusted"
shell_environment_policy.inherit = "all"

[model_providers.oaiapi]
name                  = "oaiapi"
base_url              = "https://code.oai1.online/v1"
wire_api              = "responses"
requires_openai_auth  = true

[projects."/root"]
trust_level = "trusted"

[projects."/tmp"]
trust_level = "trusted"
```

Key config settings:
- `approval_policy = "untrusted"` — trusted commands run without asking; untrusted commands still prompt
- `shell_environment_policy.inherit = "all"` — skip shell env inheritance prompts
- `[projects."<path>"] trust_level = "trusted"` — mark directories as trusted (avoids first-use prompt)

## ACP / MCP support
- `--acp` flag: **NOT present** (unlike Copilot CLI)
- `exec-server --listen stdio`: available but NOT standard ACP protocol
- `mcp-server`: available, stdio MCP mode, exposes only 2 tools:
  1. `codex` — start a new Codex agent session (takes `prompt`, `cwd`, `model`, `sandbox`, `approval-policy`)
  2. `codex-reply` — continue an existing session (takes `threadId`, `prompt`)

**Assessment:** MCP mode is a full-agent wrapper, not granular tools. Shell-level `codex exec` is equally capable and simpler — no daemon, no config, no protocol layer. Prefer direct subprocess delegation.

## Working `exec` invocation (full bypass)

Complete silent non-interactive invocation:

```bash
codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  --dangerously-bypass-hook-trust \
  --sandbox danger-full-access \
  --skip-git-repo-check \
  -C <workdir> \
  "concise task description" \
  --output-last-message /tmp/codex_out.txt
```

**Do NOT use:** `--ignore-user-config` — it strips API credentials, agent cannot call its model.

**Behaviour:** stdout includes session metadata (header + reasoning + token usage). Use `--output-last-message` for clean final-answer extraction.

**Timeout:** Wrap with `timeout 120` (shell) or set `timeout=130` on Hermes terminal() call. Simple tasks: 7-15s. Deep reasoning: 30-60s. Token consumption: ~6K-32K tokens per call.

**Exit codes:** 0 = success, 124 = timeout, non-zero = Codex internal error.

## Permission automation (3 layers)

See the umbrella skill `external-agent-coordination` for the full 3-layer defense. Codex-specific details for each layer:

**Layer 1 (CLI bypass):** Use the full flag set above.

**Layer 2 (Config/rules):**
- `~/.codex/rules/default.rules` — prefix-match execpolicy rules:
  ```
  prefix_rule(pattern=["python3"], decision="allow")
  prefix_rule(pattern=["git"], decision="allow")
  prefix_rule(pattern=["rm", "-rf"], decision="deny")  # also supports deny
  ```
- Config settings: `approval_policy = "untrusted"` (or `"never"` for fully silent)

**Layer 3 (PTY auto-respond):** If a new prompt type appears, run in background PTY, poll for keywords, submit 'y' via `process(action='submit', data='y')`.

## Hermes integration patterns

### Simple shell delegation (terminal tool)

```bash
timeout 120 codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  --dangerously-bypass-hook-trust \
  --sandbox danger-full-access \
  --skip-git-repo-check \
  -C /path/to/project \
  --output-last-message /tmp/_cx_result.txt \
  "refactor this module: ..."
```

### execute_code integration with verification

```python
from hermes_tools import terminal

# 1. Call Codex
r = terminal(
    command=(
        'cd /tmp && timeout 120 codex exec '
        '--dangerously-bypass-approvals-and-sandbox '
        '--dangerously-bypass-hook-trust '
        '--sandbox danger-full-access '
        '--skip-git-repo-check '
        '-C /tmp '
        '--output-last-message /tmp/_cx_out.txt '
        '"task"'
    ),
    timeout=130
)

# 2. Read result
out = terminal(command='cat /tmp/_cx_out.txt', timeout=5)

# 3. Verify file changes
terminal(command='python3 -m py_compile /tmp/your_file.py', timeout=10)
verified = terminal(command='cat /tmp/your_file.py', timeout=5)

# 4. Return only the summary (keep context lean)
print(f"Codex: {out['output'][:500]}")
```

### Error handling

```python
if r['exit_code'] != 0:
    if r['exit_code'] == 124:
        print("Codex timed out — task too complex or model stuck")
    else:
        print(f"Codex failed with exit {r['exit_code']}")
    # Fallback: handle with Hermes directly
```

## Division of labor guidelines

| Scenario | Use | Reason |
|---|---|---|
| Multi-file refactor / complex coding | Codex | gpt-5.4 + xhigh reasoning deeper for code |
| Research / planning / decisions | Hermes | Better at structured reasoning |
| Simple code changes (1-2 functions) | Hermes | Avoids agent startup token overhead |
| Cross-session memory | Hermes | Codex sessions are ephemeral |
| Parallel coding tasks | Hermes delegates to Codex x N | Hermes can fan-out via terminal() |
| Scheduled / CRON tasks | Hermes | Built-in cron system |
| IDE-style interactive session | Codex (manual) | User runs `codex` directly |

## Model info
- **Provider:** `oaiapi` (custom OpenAI-compatible endpoint at `code.oai1.online`)
- **Wire API:** `responses` (OpenAI Responses API, not Chat Completions)
- **Model:** `gpt-5.4` with reasoning effort `xhigh`
- Browser use, computer use, image generation features all stable

## Relevant Hermes features
- `delegate_task` with `acp_command` — only works for agents with `--acp --stdio` (Copilot CLI, NOT Codex)
- Hermes ACP mode (`hermes acp`) — Hermes acts as ACP server for editors; unrelated to Codex coordination
- Hermes MCP client — can consume `codex mcp-server` but only 2 coarse tools exposed
