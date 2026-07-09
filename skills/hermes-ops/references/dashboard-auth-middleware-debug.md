# Dashboard Auth Middleware Debug — NotImplementedError Fix

## Reproduction

1. Configure `basic_auth` in `~/.hermes/config.yaml`
2. Start dashboard: `hermes dashboard --host 0.0.0.0 --port 9119 --no-open`
3. Open browser, log in via password form
4. Wait for session to expire (or clear cookies)
5. Click any non-API page (chat, settings, etc.)

## Error Traceback

```
@router.get("/auth/login", name="auth_login")
async def auth_login(request: Request, provider: str, next: str = ""):
    p = get_provider(provider)
    # ...
    ls = p.start_login(redirect_uri=_redirect_uri(request))
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
NotImplementedError: BasicAuthProvider is password-only; ...
```

## Full Middleware Call Chain (bottom-up from traceback)

```
_auth_login (routes.py:197)  ← p.start_login() raises NotImplementedError
exceptions middleware
CORS middleware
host_header_middleware (web_server.py:477)
_plugin_api_runtime_gate (web_server.py:544)
gated_auth_middleware (middleware.py:271)  ← _auto_sso_response redirects here
_auth_middleware (web_server.py:574)  ← skip if auth_required
_token_auth_seam (web_server.py:596)  ← skip, not a token route
```

## Key Code Paths

### _auto_sso_response (middleware.py:140-205)

Triggered when:
- Request is NOT an API path (`/api/`)
- No session cookie present
- No prior SSO attempt cookie
- Exactly ONE session provider registered

If these conditions hold, redirects to `GET /auth/login?provider=<name>`.

Bug: password-only providers passed the "exactly one" check but can't handle the OAuth redirect.

### gated_auth_middleware (middleware.py:250-...)

```
1. auth_required=False → pass through (loopback mode)
2. token_authenticated → pass through (service routes)
3. path is public (/login, /auth/*, /fonts/*) → pass through
4. No access/refresh cookie → _auto_sso_response → fallback to _unauth_response
5. Has cookie → verify_session → if expired try refresh → if both fail → _unauth_response
```

## Repair Steps

1. Locate `middleware.py` in installed package:
   `/usr/local/lib/python3.11/site-packages/hermes_cli/dashboard_auth/middleware.py`

2. Find `_auto_sso_response` function, around line 180:
   ```python
   providers = list_session_providers()
   ```

3. Change to:
   ```python
   providers = [
       p for p in list_session_providers()
       if not getattr(p, "supports_password", False)
   ]
   ```

4. Restart dashboard: `hermes dashboard --stop && hermes dashboard --host 0.0.0.0 --port 9119 --no-open --skip-build`

## Verification

```bash
# Before fix — wrong redirect
curl -s -D - http://127.0.0.1:9119/ | grep -i location
# location: /auth/login?provider=basic

# After fix — correct redirect
curl -s -D - http://127.0.0.1:9119/ | grep -i location
# location: /login?next=%2F
```
