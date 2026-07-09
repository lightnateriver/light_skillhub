# Feishu / Lark Setup — Hermes Gateway

Full step-by-step for connecting Hermes to Feishu (飞书, China) or Lark (国际版).

## Quickstart — Validated Recipe (Twice-Tested Pattern)

Use this condensed workflow when creating a new Feishu bot profile. Validated with two bots in production.

```bash
# 1. Create profile
hermes profile create <name>       # e.g. feishu-bot-2

# 2. Write ~/.hermes/profiles/<name>/config.yaml
# model:
#   default: deepseek-v4-flash
#   provider: deepseek
#   base_url: https://api.deepseek.com

# 3. Write ~/.hermes/profiles/<name>/.env
#   (WebSocket mode — avoids FEISHU_VERIFICATION_TOKEN requirement)
#   FEISHU_APP_ID=cli_xxx
#   FEISHU_APP_SECRET=xxx
#   FEISHU_DOMAIN=feishu
#   FEISHU_CONNECTION_MODE=websocket
#   DEEPSEEK_API_KEY=sk-xxx       # provider key — NOT inherited from default profile!
#   DEEPSEEK_BASE_URL=...          # if custom
#   GATEWAY_ALLOW_ALL_USERS=true   # for testing only

# 4. Copy all skills (profile skills dir is empty by default)
cp -r ~/.hermes/skills/* ~/.hermes/profiles/<name>/skills/

# 5. Test
hermes -p <name> gateway run
# Ctrl+C after confirming [Lark] [INFO] connected to wss://...

# 6. Install as systemd service (survives reboot)
hermes -p <name> gateway install

# 7. Verify
hermes -p <name> gateway status
journalctl --user -u hermes-gateway-<name> --no-pager | tail -3
```

**Key rule:** Webhook mode seems intuitive but will fail immediately with `[Feishu] Webhook mode requires FEISHU_VERIFICATION_TOKEN or FEISHU_ENCRYPT_KEY.` unless that token is pre-configured. When the user doesn't push back and says "和bot1一样处理" (handle same as bot-1), the default answer is **WebSocket mode** — it works immediately and needs no verification token or port exposure.

## Step 1: Create Feishu App

Go to https://open.feishu.cn/ (Feishu China) or https://open.larksuite.com/ (Lark International):
1. Create an enterprise self-built app
2. Credentials & Basic Info → copy **App ID** and **App Secret**
3. App Features → enable **Bot** capability
4. Permission Management → add these scopes (bulk-import available in the permissions page):

| Scope | Purpose |
|-------|---------|
| `im:message` | Receive and read messages |
| `im:message:send_as_bot` | Send messages as bot |
| `im:resource` | Access images, files, audio |
| `im:chat` | Access chat/group metadata |
| `im:chat:readonly` | Read chat list and membership |
| `im:message.reactions:readonly` | (Optional) Receive reactions |
| `admin:app.info:readonly` | (Optional) Auto-detect bot identity |
| `contact:user.id:readonly` | (Optional) Resolve user IDs |

5. Events & Callbacks → subscribe to `im.message.receive_v1`
6. Version Management → create version & **publish** (required for permissions to take effect)

## Pre-Flight Checks

Before configuring Hermes, verify Python dependencies are installed:

```bash
pip list 2>/dev/null | grep -iE 'lark|websocket'
# Expected:
# lark-oapi                   x.x.x     # Lark SDK (required for both modes)
# aiohttp                     x.x.x     # Required for webhook mode
# websockets                  x.x.x     # Required for websocket mode
```

Install missing ones:
```bash
pip install lark-oapi aiohttp websockets
```

## Step 2: .env Configuration

Add to `~/.hermes/.env` (default profile) or `~/.hermes/profiles/<name>/.env` (named profile):

```bash
# — Feishu / Lark —
FEISHU_APP_ID=cli_xxxxxxxxxxxx
FEISHU_APP_SECRET=secret_xxxxxxxxxxxx
FEISHU_DOMAIN=feishu            # feishu for China, lark for international

# Connection mode: websocket (no port) or webhook (port-based)
FEISHU_CONNECTION_MODE=websocket  # recommended — no port, no verification token needed

# Webhook-only settings (ignored in websocket mode):
# FEISHU_WEBHOOK_HOST=0.0.0.0    # default: 127.0.0.1
# FEISHU_WEBHOOK_PORT=8081       # default: 8765
# FEISHU_WEBHOOK_PATH=/feishu/webhook

# ⚠ WEBHOOK MODE HARD REQUIREMENT: you MUST set at least one of these:
# FEISHU_ENCRYPT_KEY=your-key    # from developer console → Events & Callbacks
# FEISHU_VERIFICATION_TOKEN=your-token
# Without one, the gateway refuses to start: "[Feishu] Webhook mode requires FEISHU_VERIFICATION_TOKEN or FEISHU_ENCRYPT_KEY."

# Security — strongly recommended
FEISHU_ALLOWED_USERS=ou_xxx,ou_yyy
FEISHU_HOME_CHANNEL=oc_xxxx    # group for cron results

# Optional settings
FEISHU_GROUP_POLICY=allowlist  # open / allowlist / disabled
FEISHU_REQUIRE_MENTION=true    # default: true (bot must be @mentioned in groups)
FEISHU_REACTIONS=true          # default: true (typing indicator)
FEISHU_ALLOW_BOTS=none         # none / mentions / all (bot-to-bot messages)
```

## Step 3: Start Gateway (Default Profile)

```bash
hermes gateway run    # foreground, test first
```

Expected success output (WebSocket mode):
```
┌─────────────────────────────────────────────────────────┐
│           ⚕ Hermes Gateway Starting...                  │
├─────────────────────────────────────────────────────────┤
│  Messaging platforms + cron scheduler                    │
└─────────────────────────────────────────────────────────┘
[Lark] [INFO] connected to wss://msg-frontier.feishu.cn/ws/v2?...
```

The `[Lark] connected to wss://...` line confirms the WebSocket connection is alive. If you only see the banner and no Lark line, check FEISHU_APP_ID/FEISHU_APP_SECRET.

## Alternative: Profile-Based Setup (Independent Gateway per Bot)

For running multiple Feishu bots as separate processes (推荐用于多飞书独立网关):

```bash
# 1. Create a named profile
hermes profile create feishu-bot-1

# 2. Write credentials to the profile's .env
# File: ~/.hermes/profiles/feishu-bot-1/.env
#   FEISHU_APP_ID=cli_xxx
#   FEISHU_APP_SECRET=secret_xxx
#   FEISHU_DOMAIN=feishu
#   FEISHU_CONNECTION_MODE=websocket
#   GATEWAY_ALLOW_ALL_USERS=true   # for testing; replace with ALLOWED_USERS later

# 3. The profile needs a model config (no model = no agent replies)
# File: ~/.hermes/profiles/feishu-bot-1/config.yaml
#   model:
#     default: deepseek-v4-flash
#     provider: deepseek
#     base_url: https://api.deepseek.com

# 4. Test the gateway
hermes -p feishu-bot-1 gateway run

# 5. Install as systemd service
hermes -p feishu-bot-1 gateway install
# → Created: hermes-gateway-feishu-bot-1.service
# → Auto-starts on boot

# 6. Check status
hermes -p feishu-bot-1 gateway status
```

**Important:** The profile's .env does NOT inherit the default profile's API keys. If the profile uses a provider (e.g. deepseek), either:
- Add `DEEPSEEK_API_KEY` to the profile's `.env`
- Or configure a model that uses env vars already set for the profile

**Important:** The profile's skills directory (`~/.hermes/profiles/<name>/skills/`) is **empty by default**. Skills do NOT inherit from the default profile. After creating a new bot profile, copy skills:

```bash
cp -r ~/.hermes/skills/* ~/.hermes/profiles/<name>/skills/
```

Otherwise the bot will respond but have no access to procedural skills (memory, Chinese-platform knowledge, etc.).

Then message the bot on Feishu. It should reply.

## Step 4: Set Home Channel

Cron job results and cross-platform notifications need a home channel. Two ways:

**A. Runtime (in Feishu chat):** Send `/set-home` in the target group. This sets it for the current gateway session only.

**B. Persist in .env:** Write `FEISHU_HOME_CHANNEL=oc_xxxxx` to the profile's `.env` so it survives gateway restarts:

```bash
# ~/.hermes/.env or ~/.hermes/profiles/<name>/.env
FEISHU_HOME_CHANNEL=oc_xxxxx
```

**Best practice:** Do both — `/set-home` to confirm it works, then verify it auto-persisted to `.env` (the gateway runtime writes it on `/set-home`). No manual edit needed in most cases.

## Webhook Mode Requirements

- Port must be reachable from the internet (or use frp/ngrok tunnel)
- Feishu developer console → Events & Callbacks → set **Request URL**:
  `http://<your-public-ip-or-domain>:8081/feishu/webhook`
- Firewall must allow inbound traffic on the port

## WebSocket Mode (no port needed)

Set `FEISHU_CONNECTION_MODE=websocket`. Requires `websockets` Python package:
```bash
pip install websockets
```

## Interactive Cards (Button Clicks)

For card approval buttons (dangerous command confirmations) to work:

1. Subscribe to `card.action.trigger` in Events
2. Enable **Interactive Card** in App Features → Bot
3. Webhook mode only: set Card Request URL to same endpoint as event webhook

Without all three, clicking card buttons returns **error 200340**.

## Document Comment Replies

Feature for replying to @mentions on Feishu documents. Requires:
- Drive event: `drive.notice.comment_add_v1`
- Permissions: `docs:doc:readonly`, `drive:drive:readonly`
- ACL rules in `~/.hermes/feishu_comment_rules.json`

CLI:
```bash
python -m gateway.platforms.feishu_comment_rules status
python -m gateway.platforms.feishu_comment_rules pairing add <user_open_id>
```

## Media Support

| Type | Extensions | Behavior |
|------|-----------|----------|
| Images | jpg, png, gif, webp, bmp | Downloaded & cached |
| Audio | ogg, mp3, wav, m4a, aac, flac, opus, webm | Downloaded |
| Video | mp4, mov, avi, mkv, webm, m4v, 3gp | Downloaded |
| Files | pdf, doc, xls, ppt, etc. | Downloaded; small text files auto-injected |

## Burst Protection

- Text batching: 0.6s quiet window, max 8 messages per batch, 4000 chars max
- Media batching: 0.8s quiet window
- Per-chat serial processing (separate chats processed concurrently)
- Webhook rate limit: 120 req/min per (app_id, path, IP)

## Common Issues

### Multi-Bot / Multi-Instance Configuration

Hermes can run **multiple Feishu bots simultaneously** via profiles.

**Per-profile credential isolation:** Each profile stores its own Feishu credentials in `~/.hermes/profiles/<name>/.env`. Credentials are never shared across profiles.

**Webhook URL per profile in multiplex mode:**
- default profile: `http://host:PORT/feishu/webhook`
- profile `foo`: `http://host:PORT/p/foo/feishu/webhook`

Configure each bot's webhook URL in the Feishu developer console's Event & Callbacks → Request URL field.

**Profile management commands:**
```bash
hermes profile create <name>         # create profile
hermes -p <name> gateway setup       # configure with interactive wizard
hermes -p <name> gateway run         # run gateway for that profile (standalone mode)
```

### Provider API Keys in Named Profiles

Each Hermes profile has its own isolated `.env` at `~/.hermes/profiles/<name>/.env`. It does **not** inherit provider API keys (e.g. `DEEPSEEK_API_KEY`) from the default profile.

When a profile's `config.yaml` specifies a model provider, that provider's API key must be present in the profile's own `.env`:

```bash
# ~/.hermes/profiles/<name>/.env
DEEPSEEK_API_KEY=sk-xxx
FEISHU_APP_ID=cli_xxx
FEISHU_APP_SECRET=xxx
FEISHU_DOMAIN=feishu
FEISHU_CONNECTION_MODE=websocket
GATEWAY_ALLOW_ALL_USERS=true   # or FEISHU_ALLOWED_USERS=ou_xxx
```

Without the provider key, the Feishu connection succeeds but the bot stays silent — it receives messages but cannot generate replies.

**Key copy pitfall:** When copying `DEEPSEEK_API_KEY` from the default `.env` to a profile `.env`:
- Always verify the copied value character-for-character
- Use `execute_code` to compare keys programmatically (terminal output redacts secrets, so you can't verify by reading terminal output)
- A single character mismatch causes `HTTP 401: Authentication Fails` at runtime
- Compare in code: read both .env files, extract the key line, and compare with `==`

### Custom Providers in Profiles

Custom provider definitions (the `custom_providers` array in the default profile's `config.yaml`) are **NOT inherited** by named profiles. If a profile uses `provider: custom:oai1`, the full `custom_providers` block must be duplicated in that profile's `config.yaml`:

```yaml
# ~/.hermes/profiles/<name>/config.yaml
model:
  default: gpt-5.5
  provider: custom:oai1

custom_providers:
  - name: oai1
    base_url: https://code.oai1.online/v1
    api_key: sk-xxx              # full key, not redacted placeholder
    model: gpt-5.5
    models:
      gpt-5.5:
        context_length: 1000000
```

### Cannot Restart Gateway from Inside Gateway Process

When the current CLI session runs under the same user as the gateway (e.g. working SSH'd into the server), restart commands are blocked:

```
✗ Refusing to restart the gateway from inside the gateway process.
```

Neither `hermes gateway restart` nor `systemctl --user restart hermes-gateway-<name>` work from within — SIGTERM propagates. Workaround:

```python
# Run via execute_code tool:
import subprocess
subprocess.run(["systemctl", "--user", "restart", "hermes-gateway-<name>"])
```

### Model/Provider Cannot be Switched Mid-Chat

Feishu gateway bots **cannot switch models or providers mid-conversation**. The model is set in the profile's `config.yaml` and persists until the gateway restarts. There is no `/model` chat command for gateway platforms.

Workaround: create two profiles with different models → two independent gateway services, each with its own model config.

### Bot Not Responding After Setup

1. Check gateway is running: `hermes -p <name> gateway status`
2. Check connection: look for `[Lark] [INFO] connected to wss://...` in logs
3. Check for provider auth errors: `journalctl --user -u hermes-gateway-<name> --no-pager | grep -i 'error\|401\|invalid'`
4. If `HTTP 401: Authentication Fails` → API key is wrong in the profile's `.env`
5. If `RuntimeError: Provider ... no API key found` → missing provider key entirely
6. If the app was just created → it needs to be **published** in the developer console for permissions to take effect

| Symptom | Fix |
|---------|-----|
| Bot doesn't respond | Check gateway running, app published, events subscribed |
| Error 200340 on card click | Missing card.action.trigger subscription or Interactive Card toggle |
| Images/files not loaded | Missing `im:resource` scope |
| "No permission" | Re-publish app after granting new scopes |
| Webhook returns non-200 | Check FEISHU_ENCRYPT_KEY / FEISHU_VERIFICATION_TOKEN match developer console |
| Gateway won't start in webhook mode | `[Feishu] Webhook mode requires FEISHU_VERIFICATION_TOKEN or FEISHU_ENCRYPT_KEY.` — switch to websocket or set the env var |
| Allowlist warning: "No env user allowlists configured" | Warning only, gateway still works. For testing, set `GATEWAY_ALLOW_ALL_USERS=true` |
| Profile gateway: no Lark connection, only banner | Profile has no model configured → no agent replies. Add model section to profile's `config.yaml` |
| TERMINAL_CWD warning in profile logs | Harmless but noisy. Move `TERMINAL_CWD` from profile `.env` into `config.yaml` |
| Profile gateway runs but bot doesn't reply | Missing provider API key in profile's `.env`. Check logs for "no API key found" |
| Skills not available in bot profile | Skills don't inherit. Run `cp -r ~/.hermes/skills/* ~/.hermes/profiles/<name>/skills/` |
| `HTTP 401: Authentication Fails` | API key copied wrong from default profile. Compare programmatically |

## Updating Bot Credentials

To replace a Feishu bot's App ID and App Secret on an existing profile:

```bash
# 1. Edit the profile's .env, update FEISHU_APP_ID and FEISHU_APP_SECRET
#    (other settings stay as-is)

# 2. Restart the gateway service
systemctl --user restart hermes-gateway-<profile-name>
```

No other changes needed — the gateway picks up new credentials on restart. Verify with `journalctl` for the `[Lark] [INFO] connected to wss://...` line.
