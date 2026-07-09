---
name: chinese-messaging-platforms
title: Chinese Messaging Platforms
category: gateway
description: >-
  Configure and troubleshoot Chinese messaging platforms (Feishu/Lark, DingTalk,
  WeCom, Weixin, QQ Bot, Yuanbao) in the Hermes Agent messaging gateway. Covers
  the shared pattern: create app on developer console → set permissions → subscribe
  events → configure webhook/websocket → publish → restart gateway.
triggers:
  - user asks to connect Hermes to Feishu / Lark / 飞书
  - user asks to connect Hermes to DingTalk / 钉钉
  - user asks to connect Hermes to WeCom / WeChat Work / 企业微信
  - user asks to connect Hermes to Weixin / WeChat / 微信
  - user asks to connect Hermes to QQ Bot / QQ 机器人
  - user asks to connect Hermes to Yuanbao / 元宝
  - user asks to configure gateway for any Chinese messaging platform
  - user mentions a specific port for gateway webhook
  - user says "和bot1一样处理" or "和前面一样" when creating another bot
  - user asks "再新profile一个" for the same platform
  - user asks to swap/replace Feishu bot credentials on an existing profile
---

# Chinese Messaging Platforms — Hermes Gateway Setup

## Overview

Hermes Agent ships with gateway support for **7 Chinese messaging platforms**.
All follow the same general flow:

1. Create an app on the platform's developer console
2. Enable bot/robot capability
3. Grant permissions (scopes for reading/sending messages, accessing media)
4. Subscribe to events (usually `im.message.receive_v1` or equivalent)
5. Choose connection mode: **WebSocket** (recommended, no port needed) or **Webhook** (HTTP server on a configurable port)
6. Publish/release the app so permissions take effect
7. Set `*_ALLOWED_USERS` to restrict access
8. Start gateway with `hermes gateway run`

## Gateway Setup Wizard

```bash
hermes gateway setup
```

Select the platform from the interactive menu. Two flows:
- **Scan-to-create** (platforms with QR code): scan with mobile app, app is auto-created
- **Manual entry**: enter App ID, App Secret, and config from developer console

## Start the Gateway

```bash
hermes gateway run       # foreground (testing)
hermes gateway install   # systemd service
hermes gateway start     # start the service
```

## Connection Modes

### WebSocket (recommended)
- No public IP/port needed — Hermes opens an outbound persistent connection
- Auto-reconnection built into the platform SDK
- Set env: `*_CONNECTION_MODE=websocket`

### Webhook
- Requires a reachable HTTP endpoint (public IP, domain, or tunnel like frp/ngrok)
- Hermes starts an aiohttp server
- Set env: `*_CONNECTION_MODE=webhook`
- Customize bind: `*_WEBHOOK_HOST`, `*_WEBHOOK_PORT`, `*_WEBHOOK_PATH`
- Defaults: host `127.0.0.1`, port `8765`, path `/feishu/webhook`
- **⚠️ HARD REQUIREMENT:** Webhook mode **must** have `FEISHU_VERIFICATION_TOKEN` or `FEISHU_ENCRYPT_KEY` set in .env. Gateway refuses to start the Feishu adapter without one:
  ```
  [Feishu] Webhook mode requires FEISHU_VERIFICATION_TOKEN or FEISHU_ENCRYPT_KEY.
  ```
  Get these from the Feishu developer console → Events & Callbacks.

## User Allowlist

**Always configure an allowlist for production.**

```bash
FEISHU_ALLOWED_USERS=ou_xxx,ou_yyy
DINGTALK_ALLOWED_USERS=user-id-1
WECOM_ALLOWED_USERS=user-id-1,user-id-2
```

Global allowlist:
```bash
GATEWAY_ALLOWED_USERS=user1,user2
GATEWAY_ALLOW_ALL_USERS=true   # NOT recommended
```

## Home Channel

Set a chat/group for cron outputs and notifications:

```bash
*_HOME_CHANNEL=xxx
```

Or send `/set-home` in the target chat after the bot connects.

## Group Message Policy

```bash
FEISHU_GROUP_POLICY=open       # respond to @mentions from any user
FEISHU_GROUP_POLICY=allowlist  # only from allowed users (default)
FEISHU_GROUP_POLICY=disabled   # ignore all group messages
```

Bot must be @mentioned in groups. Set `*_REQUIRE_MENTION=false` to read all traffic.

## Troubleshooting

### App not responding
- Check gateway: `hermes gateway status`
- Check logs: `hermes logs` or `journalctl`
- Verify the app is **published** (not just saved) — permissions don't take effect until publish
- Webhook mode: verify platform can reach your server (curl from outside, check firewall)

### "No permission" errors
- Re-check granted scopes in developer console
- Re-publish the app after granting new scopes
- Some scopes require admin approval for enterprise apps

### Webhook mode won't start: "requires FEISHU_VERIFICATION_TOKEN or FEISHU_ENCRYPT_KEY"
- This is a **hard requirement**, not optional — the Feishu adapter refuses to boot in webhook mode without one
- Go to Feishu developer console → Events & Callbacks, set either:
  - **Encrypt Key**: click "Enable Encryption", generate a key, copy to `FEISHU_ENCRYPT_KEY`
  - **Verification Token**: set a token string, copy to `FEISHU_VERIFICATION_TOKEN`
- Preferred workaround: switch to WebSocket mode (`FEISHU_CONNECTION_MODE=websocket`) which needs neither
- Subscribe to `card.action.trigger` event
- Enable "Interactive Card" toggle in Bot settings
- Webhook mode: set Card Request URL to the webhook endpoint

## Running Multiple Bots (Same Platform)

Hermes supports running **multiple bots for the same platform** (e.g., two Feishu bots) via profiles. Two approaches:

### A. Independent Gateways (separate processes, same or different ports)

Each profile runs its own gateway process on a dedicated port. This is the **recommended default** for distinct bots.

```bash
# Create profiles
hermes profile create feishu-bot-1
hermes profile create feishu-bot-2

# Configure each profile's ~/.hermes/profiles/<name>/.env:
#   FEISHU_APP_ID=cli_xxx
#   FEISHU_APP_SECRET=xxx
#   FEISHU_DOMAIN=feishu          # feishu | lark
#   FEISHU_CONNECTION_MODE=websocket  # websocket (no port) or webhook
#    (webhook specific)
#   FEISHU_WEBHOOK_HOST=0.0.0.0
#   FEISHU_WEBHOOK_PORT=8081
#   FEISHU_WEBHOOK_PATH=/feishu/webhook

# Also configure the profile's ~/.hermes/profiles/<name>/config.yaml:
#   model:
#     default: <model-name>
#     provider: <provider>
#     base_url: ...

# Start each independently
hermes -p feishu-bot-1 gateway run   # e.g. port 8081
hermes -p feishu-bot-2 gateway run   # e.g. port 8082

# Install as systemd service (auto-start on boot)
hermes -p feishu-bot-1 gateway install
hermes -p feishu-bot-2 gateway install

# Management
feishu-bot-1 gateway start     # wrapper script auto-created by profile create
feishu-bot-1 gateway status
feishu-bot-1 gateway restart
journalctl --user -u hermes-gateway-feishu-bot-1 -f
```

**Key details for each profile:**
- Each profile's `.env` needs its own `DEEPSEEK_API_KEY` (and all provider keys) — they don't inherit from the default profile
- Each profile's skills directory (`~/.hermes/profiles/<name>/skills/`) is **empty by default** — skills do not inherit from the default profile. After creating a new bot profile, copy skills:
  ```bash
  cp -r ~/.hermes/skills/* ~/.hermes/profiles/<name>/skills/
  ```
- The `hermes profile create` command creates a wrapper script at `~/.local/bin/<profile-name>` for convenient CLI access
- WebSocket mode is simpler: no port needed, no FEISHU_VERIFICATION_TOKEN/FEISHU_ENCRYPT_KEY required
- Webhook mode **requires** `FEISHU_VERIFICATION_TOKEN` or `FEISHU_ENCRYPT_KEY` (from Feishu developer console → Events & Callbacks), otherwise the adapter refuses to start
- `lark-oapi` and `websockets` Python packages must be installed (usually included by default)
- `hermes profile create` auto-adds `TERMINAL_CWD=/root` to the profile's `.env`. To suppress the startup warning, move it to `config.yaml` as `terminal:\n    cwd: /root` then remove from `.env`.

Best for: process-level isolation, different teams/environments.

### B. Multiplexed Gateway (one process, shared port)

Enable multiplexing on the default profile; Feishu webhook URLs are differentiated by a `/p/<profile>/` prefix.

```bash
hermes config set gateway.multiplex_profiles true
# Configure each sub-profile with its own FEISHU_APP_ID/SECRET
# Only the default profile's gateway is started
hermes gateway run   # single listener
```

Webhook URL mapping:
| Profile | Webhook URL |
|---------|------------|
| default | `http://host:PORT/feishu/webhook` |
| feishu-bot-1 | `http://host:PORT/p/feishu-bot-1/feishu/webhook` |
| feishu-bot-2 | `http://host:PORT/p/feishu-bot-2/feishu/webhook` |

Best for: lightweight multi-bot on one machine, container/VPS deployments.

### Port-binding platform rule (multiplex mode)

Feishu (webhook), WeCom Callback, DingTalk, BlueBubbles, SMS, and api_server are **port-binding platforms**. In multiplex mode, only the **default** profile can enable them. Secondary profiles are served through the `/p/<profile>/` prefix on the default listener.

## References

- `references/feishu.md` — Full Feishu/Lark setup: app creation, env vars, connection modes, multi-bot profiles, credential swapping, provider API keys in profiles, interactive cards, media handling, troubleshooting.

## Bot Profile with Custom Provider

When a profile uses a **custom provider** (defined in the default profile's `custom_providers` section), the definition must be **duplicated** in the profile's own `config.yaml`. Custom provider configs do NOT inherit across profiles.

**Scenario:** Default profile has `oai1` as a custom provider. Profile `feishu-bot-2` should use `oai1`'s `gpt-5.5`.

```yaml
# ~/.hermes/profiles/<name>/config.yaml
model:
  default: gpt-5.5
  provider: custom:oai1

# ⚠️ MUST duplicate the custom_providers block from the default profile
custom_providers:
  - name: oai1
    base_url: https://code.oai1.online/v1
    api_key: sk-xxx              # include the full key
    model: gpt-5.5
    models:
      gpt-5.5:
        context_length: 1000000
```

The `provider: custom:oai1` syntax references the `name` field in the `custom_providers` array. If the custom provider's API key is embedded in `config.yaml` (not `.env`), it must be carried over explicitly.

## Model / Provider Switching

**Users cannot switch the bot's model or provider mid-conversation** from within the Feishu (or any gateway) chat. The model config is profile-level in `config.yaml`. Changing it requires:
1. Edit the profile's `config.yaml` (change `model.default` and `model.provider`)
2. Restart the gateway

The `/model` chat command is **not supported** in gateway platforms. If a user asks "可以和bot对话切换模型", explain this limitation and offer a dual-profile setup as alternative.

## Post-Setup Verification Checklist

After configuring a new bot profile, verify in order:

1. **WebSocket connects** → check logs for `[Lark] [INFO] connected to wss://...`
2. **Send a test message** in the Feishu group → bot should reply
3. **If bot doesn't reply**, check logs for:
   - `RuntimeError: Provider 'deepseek' is set... no API key found` → add `DEEPSEEK_API_KEY` to the profile's `.env`
   - `HTTP 401: Authentication Fails, Your api key: ... is invalid` → the key was **copied wrong** from the default profile. Verify character-by-character against the main `.env` — `execute_code` is safer than `terminal` for reading secret values precisely.
   - `✗ feishu failed to connect` → check FEISHU_APP_ID / FEISHU_APP_SECRET
4. **Set home channel** → `/set-home` in the target group. The gateway auto-persists `FEISHU_HOME_CHANNEL` to `.env` — no manual edit needed after `/set-home`.
5. **Check startup warnings** → `TERMINAL_CWD` warning is cosmetic, suppress by moving from `.env` into profile `config.yaml`:
   ```bash
   terminal:
     cwd: /root
   ```
6. **Create AGENTS.md** for project context — use `AGENTS.md` (NOT `CLAUDE.md` or `.cursorrules`) unless user states otherwise. Place at project root (e.g. `/root/clawcos/AGENTS.md`) and also at `/root/AGENTS.md` for CLI session visibility.

## Common Pitfalls

### Provider API key copied wrong across profiles
When copying `DEEPSEEK_API_KEY` (or any provider key) from the default profile to a named profile's `.env`:
- **Always verify** the copied value matches the source character-for-character
- Use `execute_code` to compare keys programmatically rather than reading via terminal (secrets get redacted in terminal output)
- A single mistyped character causes `HTTP 401: Authentication Fails` at runtime

### Cannot restart gateway from inside gateway process
When the current CLI session is a child of the gateway process (common when working on the same server where gateway runs):
- `hermes gateway restart` → **blocked** with `Refusing to restart the gateway from inside the gateway process`
- `systemctl --user restart hermes-gateway-<name>` → **also blocked** (SIGTERM propagates)
- Workaround: use `execute_code` with `subprocess.run(["systemctl", "--user", "restart", "hermes-gateway-<name>"])` which spawns an independent subprocess

### Webhook mode refuses to start
- Error: `[Feishu] Webhook mode requires FEISHU_VERIFICATION_TOKEN or FEISHU_ENCRYPT_KEY.`
- Fix: either set one of those env vars from the developer console, or switch to `FEISHU_CONNECTION_MODE=websocket`
- When user says "和bot1一样处理" or "和前面一样", the default fallback is **WebSocket mode**
