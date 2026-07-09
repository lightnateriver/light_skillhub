---
name: hermes-ops
category: ops
description: "Hermes Agent operations: web dashboard setup, auth configuration, server management, and troubleshooting common issues."
triggers:
  - "dashboard not working / login broken"
  - "web UI crashes when clicking chat"
  - "auth provider errors (NotImplementedError, OAuth flow)"
  - "setting up basic_auth for web dashboard"
  - "dashboard --host 0.0.0.0 exposed externally"
  - "stopping / restarting / debugging hermes dashboard"
  - "missing TUI workspace error"
---

# Hermes Ops — Dashboard Operations & Troubleshooting

## Web Dashboard Quick Reference

```bash
# Start dashboard (default port 9119, localhost only)
hermes dashboard

# Expose externally (requires auth)
hermes dashboard --host 0.0.0.0 --port 9119 --no-open

# Stop all dashboard processes
hermes dashboard --stop

# Check running status
hermes dashboard --status

# Skip frontend rebuild (use existing dist)
hermes dashboard --skip-build
```

## Authentication Configuration

### basic_auth (password-only, no OAuth IDP)

Configure in `~/.hermes/config.yaml`:

```yaml
dashboard:
  basic_auth:
    username: admin
    password_hash: "scrypt$16384$8$1$..."
    secret: "<32+ random bytes, base64 or hex>"
```

Generate a password hash:

```python
from plugins.dashboard_auth.basic import hash_password
print(hash_password("your-password"))
```

### Auth Provider Architecture

Two distinct login flows exist, and providers implement only one:

| Provider Type | Supports | Login Endpoint | Session Support |
|---|---|---|---|
| **OAuth** (Portal, OIDC) | `start_login()` → redirect to IDP | `GET /auth/login?provider=<name>` | `supports_session=True` |
| **Password** (basic_auth) | `complete_password_login()` | `POST /auth/password-login` (form body) | `supports_password=True` |

The login page (`GET /login`) auto-detects: password providers get a credential form, OAuth providers get a sign-in button link.

## Common Issues & Fixes

### 1. NotImplementedError: BasicAuthProvider is password-only

**Symptoms:** User logs in, but clicking "chat" or any page after session expiry crashes with:
```
NotImplementedError: BasicAuthProvider is password-only; there is no OAuth redirect flow.
```

**Root cause:** `_auto_sso_response()` in `dashboard_auth/middleware.py` auto-redirects unauthenticated HTML page loads to `GET /auth/login?provider=basic` (an OAuth endpoint). `BasicAuthProvider.start_login()` raises `NotImplementedError`.

**Fix:** In `_auto_sso_response`, filter out password-only providers from the SSO candidate list:

```python
# OLD (broken):
providers = list_session_providers()

# NEW (fixed):
providers = [
    p for p in list_session_providers()
    if not getattr(p, "supports_password", False)
]
```

After the fix, unauthenticated requests go to `GET /login` (password form) instead of `GET /auth/login?provider=basic` (OAuth redirect).

**Verification:** Access the dashboard root without cookies:
```bash
curl -s -D - http://127.0.0.1:9119/ | head -5
# Expected: HTTP/1.1 302 Found → location: /login?next=%2F
# NOT: location: /auth/login?provider=basic
```

### 2. `Error: the TUI workspace is missing`

**Symptom:** Stderr shows `Expected directory: /usr/local/lib/python3.11/site-packages/ui-tui` on startup.

**Impact:** Cosmetic only — does NOT affect the web dashboard or API server. Only affects `hermes chat --tui`.

**Fix:** `hermes update --force` to restore the TUI directory.

### 3. Dashboard process won't start / port in use

See [Section 5](#5-dashboard-process-wont-start--port-in-use) for in-depth handling — the short version:

```bash
ss -tlnp | grep 9119       # check who's holding the port
hermes dashboard --stop    # clean stop
fuser -k 9119/tcp          # nuclear option if --stop misses an orphan
hermes dashboard --host 0.0.0.0 --port 9119 --no-open
```

## Middleware Stack (auth flow order)

Requests pass through these middleware layers (outermost runs first):

```
token_auth_seam       → bearer-token auth for service routes
auth_middleware       → legacy session-token (loopback only)
_dashboard_auth_gate  → gated_auth_middleware (cookie-based, for public binds)
_plugin_api_runtime   → plugin routing
host_header_middleware → host validation
CORS
exceptions
FastAPI routing
```

For a public bind (`--host 0.0.0.0`), `gated_auth_middleware` is active and enforces cookies. The flow:

1. Request hits `_dashboard_auth_gate` → `gated_auth_middleware`
2. No valid cookie → `_auto_sso_response()` tries silent OAuth redirect
3. If auto-SSO fails/unsuitable → `_unauth_response()` → `GET /login`
4. SPA JS POSTs to `POST /auth/password-login` (password) or redirects to IDP (OAuth)
5. Success sets session cookies → subsequent requests pass verification

### 4. `Chat unavailable: 1` — TUI bundled-bypass fix

**Symptom:** Web dashboard chat tab opens xterm.js terminal showing red `Chat unavailable: 1`. Dashboard log shows `pty accepted` then quick `ws closed` with `reaped_sessions=1`.

**Root cause:** `_make_tui_argv()` in `main.py` calls `_ensure_tui_workspace()` BEFORE checking for the bundled TUI (`tui_dist/entry.js`). In a pip install, the `ui-tui/` workspace directory doesn't exist (only the prebuilt `hermes_cli/tui_dist/entry.js` bundle is shipped), so `_ensure_tui_workspace` calls `sys.exit(1)`. The exit code `1` is caught by the PTY handler and sent to the browser as `Chat unavailable: 1`.

**Fix:** In `_make_tui_argv`, move the bundled-TUI check (`_find_bundled_tui()` → `hermes_cli/tui_dist/entry.js`) to BEFORE `_ensure_tui_workspace`. File: `/usr/local/lib/python3.11/site-packages/hermes_cli/main.py`.

```python
# OLD (broken):
if not ext_dir:
    _ensure_tui_workspace(tui_dir)

# 1b. Bundled in wheel (pip install)
bundled = _find_bundled_tui()

# NEW (fixed):
# 1b. Bundled in wheel — check BEFORE _ensure_tui_workspace
bundled = _find_bundled_tui()
if bundled is not None:
    node = _node_bin("node")
    return [node, "--expose-gc", str(bundled)], bundled.parent

# 2. Workspace-based — only reached if no bundled TUI
if not ext_dir:
    _ensure_tui_workspace(tui_dir)
```

**Verification:**
```bash
python3 -c "
from hermes_cli.main import _make_tui_argv
from pathlib import Path
argv, cwd = _make_tui_argv(Path('/nonexistent/ui-tui'), tui_dev=False)
print('entry.js' in ' '.join(argv))
# → True (uses bundled TUI, not ui-tui/)
"
```

**Quick-check the running process:**
```bash
hermes dashboard --stop          # stop ALL dashboard processes
hermes dashboard --host 0.0.0.0  # restart with fresh code
```

> **⚠ Trapping:** `hermes dashboard --stop` only works on processes it knows about — it kills the wrapper bash processes but often leaves the actual `hermes`/uvicorn server process alive. The orphan keeps the port. Always verify after stop: `ss -tlnp | grep 9119`. If a stale PID remains, `kill -9 <PID>` directly.\n\n**Diagnostic signature for `Chat unavailable: 1`:** look for this repeating pattern in `gui.log`:\n```\npty accepted peer=...\ntui_gateway.ws: ws accepted\ntui_gateway.ws: ws closed ... messages=1 reaped_sessions=1\n```\n`messages=1` means the TUI subprocess sent exactly 1 message (the error text) before dying. `reaped_sessions=1` confirms a session was created and immediately reaped. This means the PTY and gateway accepted, but the TUI subprocess crashed on init — the fix is in `_make_tui_argv` (section 4 above).\n\n**Patch-install `.pyc` pitfall:** After patching installed Python sources (e.g. `/usr/local/lib/python3.11/site-packages/hermes_cli/`), Python's bytecode cache can stay stale and override your edit. Always clear it:\n```bash\nfind /usr/local/lib/python3.11/site-packages/hermes_cli/__pycache__/ \\\n  -name 'main*.pyc' -o -name 'web_server*.pyc' -o -name 'middleware*.pyc' \\\n  -delete\n```\nThen `hermes dashboard --stop && hermes dashboard --host 0.0.0.0 --port 9119 --no-open` to force a fresh compile.\n\n### 5. Dashboard process won't restart / port in use

```bash
# Check what's listening
ss -tlnp | grep 9119

# Force stop if --stop fails
fuser -k 9119/tcp          # kills everything on that port
hermes dashboard --stop    # clean up PID tracking
hermes dashboard --host 0.0.0.0 --port 9119 --no-open

# Verify fresh start
hermes dashboard --status  # should show one process with recent PID
```

### 6. Multi-User Session Isolation

**Symptom:** With `basic_auth` (single admin user), the dashboard session list shows ALL conversations from all users. User asks: "Can I isolate sessions so User A only sees their own chats?"

**Current limitation:** Hermes v0.18.0 has **no built-in multi-user isolation** in the dashboard. The `sessions` table has a `user_id` column, but dashboard/TUI sessions all write `user_id=NULL`, and the `/api/sessions` endpoint returns all rows unfiltered. The `basic_auth` provider supports only a single credential pair.

**Best approach: Profiles-as-tenants**

Each Hermes Profile has its own `state.db` (session database), config, skills, and memory. Give each user their own profile + own dashboard port for complete session isolation:

```bash
# 1. Create a profile per user
hermes profile create user-zhang
hermes profile create user-li

# 2a. Start User Zhang's dashboard
hermes dashboard --host 0.0.0.0 --port 9120 --no-open --isolated

# 2b. Start User Li's dashboard (separate terminal / process)
hermes dashboard --host 0.0.0.0 --port 9121 --no-open --isolated
```

The `--isolated` flag scopes the dashboard to that profile's directory, so each instance reads/writes its own `state.db`. Result:

| User | URL | Profile Dir | Session Data |
|------|-----|-------------|--------------|
| Zhang | `http://server:9120` | `~/.hermes/profiles/user-zhang/` | Zhang's sessions only |
| Li | `http://server:9121` | `~/.hermes/profiles/user-li/` | Li's sessions only |

**Can OAuth solve multi-user?** Switching from `basic_auth` to the `self_hosted` OIDC provider (Keycloak, Authentik, Google, GitHub) lets multiple users authenticate — but the dashboard `/api/sessions` still shows ALL sessions in that profile's `state.db`, unfiltered by `user_id`. OAuth solves "who can log in" but not "who can see what". Profile separation remains the only true isolation mechanism.

**Reference for auth providers available in v0.18.0:**

| Provider | Directory | Supports | Multi-User? |
|----------|-----------|----------|-------------|
| `basic` | `plugins/dashboard_auth/basic/` | single username+password | ❌ |
| `self_hosted` | `plugins/dashboard_auth/self_hosted/` | OIDC (Keycloak, Google, GitHub…) | ✅ login only, ❌ session isolation |
| `nous` | `plugins/dashboard_auth/nous/` | Nous Portal OAuth | ✅ login only, ❌ session isolation |
| `drain` | `plugins/dashboard_auth/drain/` | service-level token auth | N/A |

## References

- `references/dashboard-auth-middleware-debug.md` — full traceback walkthrough for the NotImplementedError fix
- `references/tui-bundled-troubleshooting.md` — TUI bundled-bypass repair steps and verification
