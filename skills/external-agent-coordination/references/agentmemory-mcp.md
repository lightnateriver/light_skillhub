# agentmemory MCP Server

[agentmemory](https://github.com/rohitg00/agentmemory) is a persistent memory server for AI coding agents, providing 43+ MCP tools and 95.2% retrieval accuracy on LongMemEval-S.

## Connection Details (deployed instance)

- **MCP URL:** `http://106.52.214.47:8082/mcp`
- **Protocol:** Streamable HTTP (MCP v2024-11-05)
- **Auth:** Bearer token via `Authorization` header
- **Server version:** agentmemory v0.9.27 (as of July 2026)

## Config in Hermes

```yaml
# ~/.hermes/config.yaml
mcp_servers:
  agentmemory:
    url: http://106.52.214.47:8082/mcp
    headers:
      Authorization: Bearer ${MCP_AGENTMEMORY_API_KEY}
```

```bash
# ~/.hermes/.env
MCP_AGENTMEMORY_API_KEY=<bearer-token>
```

## How agentmemory works

- Runs a standalone MCP server (not local stdio — remote HTTP endpoint)
- Tools appear as native Hermes tools once configured
- Memories are cross-agent: shared with Claude Code, Cursor, Codex CLI, etc.
- Hybrid search: BM25 + vector + knowledge graph
- No external database dependencies

## Hermes integration options

The agentmemory repo has a dedicated Hermes plugin at `integrations/hermes/`:
- Plugin: `__init__.py` (MemoryProvider with 6 lifecycle hooks)
- Config: `plugin.yaml`
- Plugin hooks: `prefetch`, `sync_turn`, `on_session_end`, `on_pre_compress`, `on_memory_write`, `system_prompt_block`

For deep integration (pre-LLM context injection, turn-level capture, memory mirroring), copy the `integrations/hermes/` directory to `~/.hermes/plugins/agentmemory/`. The basic MCP connection (config above) gives you all 43+ tools without the plugin.

## MCP protocol details

The Streamable HTTP transport requires:
- `Content-Type: application/json`
- `Accept: application/json, text/event-stream`
- POST to the MCP endpoint with JSON-RPC 2.0 payloads
- Supports `2024-11-05` protocol version

## Verification

```bash
# Test with hermes CLI
hermes mcp test agentmemory

# Manual curl probe
curl -s "http://106.52.214.47:8082/mcp" \
  -H "Authorization: Bearer ${MCP_AGENTMEMORY_API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"hermes-test","version":"1.0"}},"id":1}'
```
