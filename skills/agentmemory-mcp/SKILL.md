---
name: agentmemory-mcp
description: 对接远程 agentmemory MCP 服务器到 Hermes Agent 的完整配置流程
---

# agentmemory MCP 集成指南

## 目的
将远程部署的 agentmemory MCP 服务器（Streamable HTTP transport）接入 Hermes Agent，提供跨会话持久化记忆能力。

## 前提条件
- Hermes Agent v0.18.0+
- `mcp` Python 包 >= 1.0.0（支持 `streamable_http` 传输）

## 配置步骤

### 1. 安装/升级 MCP 包
```bash
pip install 'mcp>=1.0.0'
```

### 2. 写入 Bearer Token 到 `.env`
```bash
echo 'MCP_<SERVERNAME>_API_KEY=<your-bearer-token>' >> ~/.hermes/.env
```

### 3. 在 `config.yaml` 添加 MCP Server 定义
```yaml
mcp_servers:
  agentmemory:
    url: http://<host>:<port>/mcp
    headers:
      Authorization: Bearer ${MCP_<SERVERNAME>_API_KEY}
    enabled: true
```

### 4. 测试连接
```bash
hermes mcp test agentmemory
```

### 5. 验证工具可用性
```bash
hermes --oneshot "列出当前可用的 MCP 工具"
```

## 验证标准
- `hermes mcp ls` 显示 agentmemory 为 `✓ enabled`
- `hermes mcp test agentmemory` 成功连接并列出工具
- 新会话中工具以 `mcp_agentmemory_*` 格式出现

## 工具列表
| 工具 | 功能 |
|------|------|
| `memory_recall` | 搜索历史会话观察结果 |
| `memory_save` | 保存重要的洞察、决策、模式到长期记忆 |
| `memory_sessions` | 列出最近的会话及状态 |
| `memory_smart_search` | 混合语义+关键词搜索 |
| `memory_export` | 导出所有记忆数据为 JSON |
| `memory_audit` | 查看记忆操作审计日志 |
| `memory_governance_delete` | 安全删除特定记忆 |

## 注意
- `.env` 文件受 Hermes 保护，写入需要用户批准
- 终端输出中的 `${AGENTMEMORY_API_KEY}` 会被 redact_secrets 机制自动脱敏显示为 `...`
- 远程 MCP 服务器必须使用 Streamable HTTP transport（MCP 协议 2024-11-05）
- SSE 传输不被支持，需要使用 `mcp>=1.0.0` 包的 `mcp.client.streamable_http`

## 常见问题
- **401 Unauthorized**: 检查 `.env` 中 Token 是否正确，或 Token 是否已过期
- **"mcp.client.streamable_http is not available"**: 需要升级 `mcp` 包
- **406 Not Acceptable**: MCP 服务器要求 `Accept: application/json, text/event-stream` 头，确保使用 Streamable HTTP 客户端
