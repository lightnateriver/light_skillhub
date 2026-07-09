# TUI Bundled-Bypass Troubleshooting — `Chat unavailable: 1`

## Symptom

Opening the web dashboard chat tab shows a red xterm.js message:

```
Chat unavailable: 1
```

Dashboard log shows `pty accepted`, then a rapid `ws closed` with `reaped_sessions=1`:

```
INFO hermes_cli.web_server: pty accepted peer=... mode=gated cred=ticket
INFO tui_gateway.ws: ws closed peer=... reason=client_disconnect(code=1005,reason=) messages=1 reaped_sessions=1
```

No other Python traceback or crash in any log.

## Root Cause

The error `1` is the string representation of `SystemExit(1)` — the child process called `sys.exit(1)` before the PTY could render its UI.

The system exit happens inside `_make_tui_argv()` in `hermes_cli/main.py`. This function is called by the `/api/pty` WebSocket handler to determine what command to spawn as the chat TUI.

**Call chain:**

```python
# web_server.py line 12680
argv, cwd, env = await _resolve_chat_argv_async(**resolve_kwargs)

# web_server.py line 12388 (inside _resolve_chat_argv_async)
argv, cwd = _make_tui_argv(PROJECT_ROOT / "ui-tui", tui_dev=False)

# main.py line 1753 (OLD broken code — runs FIRST)
_ensure_tui_workspace(tui_dir)   # tui_dir = /usr/local/lib/python3.11/site-packages/ui-tui
```

Since the `ui-tui/` directory does NOT exist in a pip install (only the prebuilt `tui_dist/entry.js` bundle is shipped), `_ensure_tui_workspace` falls through to `sys.exit(1)`.

## Two Fixes Applied

### Fix 1: Reorder checks in _make_tui_argv

**File:** `/usr/local/lib/python3.11/site-packages/hermes_cli/main.py`
**Function:** `_make_tui_argv` (around line 1750)

The bundled-TUI check (`_find_bundled_tui() → tui_dist/entry.js`) must run BEFORE `_ensure_tui_workspace`:

| Step | Old order | New order |
|------|-----------|-----------|
| 1 | `_ensure_tui_workspace(tui_dir)` ← dies here | `_find_bundled_tui()` → returns entry.js |
| 2 | `_find_bundled_tui()` → never reached | Return early with bundled argv |
| 3 | (never reached) | `_ensure_tui_workspace(tui_dir)` ← only reached if no bundled TUI |

### Fix 2: Kill stale dashboard process

Even after Fix 1, if a dashboard started BEFORE the code change is still running, it holds the port and any new `hermes dashboard --host 0.0.0.0 --port 9119` will fail with `address already in use`.

```bash
# See what's listening on 9119
ss -tlnp | grep 9119

# Identify the stale Python process
ps aux | grep "dashboard" | grep -v grep

# Kill the old one
kill <PID>

# Then start fresh
hermes dashboard --host 0.0.0.0 --port 9119 --no-open
```

## Verification

```python
python3 -c "
from hermes_cli.main import _make_tui_argv
from pathlib import Path
import os

# Ensure HERMES_TUI_DIR is not set
os.environ.pop('HERMES_TUI_DIR', None)

argv, cwd = _make_tui_argv(Path('/nonexistent/ui-tui'), tui_dev=False)
print(f'argv: {\" \".join(argv)}')
print(f'cwd: {cwd}')
# Expected:
#   argv: /.../node --expose-gc /.../tui_dist/entry.js
#   cwd: /usr/local/lib/python3.11/site-packages/hermes_cli/tui_dist
# (NOT sys.exit(1))
"
```

## Key Files

| File | Role |
|------|------|
| `/usr/local/lib/python3.11/site-packages/hermes_cli/main.py` | Contains `_make_tui_argv` and `_ensure_tui_workspace` |
| `/usr/local/lib/python3.11/site-packages/hermes_cli/web_server.py` | PTY handler at `/api/pty` that catches SystemExit |
| `/usr/local/lib/python3.11/site-packages/hermes_cli/tui_dist/entry.js` | Prebuilt TUI bundle (3.3MB) shipped in the wheel |
| `/root/.hermes/logs/gui.log` | Dashboard log — shows `pty accepted` / `ws closed` |
| `/root/.hermes/logs/errors.log` | Error log — may show related warnings |

## Log Anatomy

A failing TUI connection in `gui.log`:

```
16:54:35 INFO ws accepted peer=...:57905          ← TUI child connected to /api/ws
16:54:35 INFO pty accepted peer=... mode=gated     ← Browser connected to /api/pty
16:54:37 INFO ws closed peer=...:57905 reason=...  ← TUI child disconnected (1 msg sent)
```

`messages=1` in the close reason means the only message sent was the error text "Chat unavailable: 1".
