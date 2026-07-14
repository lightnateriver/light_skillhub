# light_skillhub

个人 AI Agent skills 仓库，跨 Hermes / Codex / Claude Code 多端同步。
基于 `SKILL.md` 格式（YAML frontmatter + markdown 指令），统一管理、一键部署。

---

## 在新服务器上安装

```bash
# 1. 克隆到约定位置
git clone https://github.com/lightnateriver/light_skillhub /root/clawcos/skills

# 2. 安装到当前机器的 AI 工具
cd /root/clawcos/skills
bash sync.sh --all        # 检测并安装到 Hermes + Codex + Claude Code
```

AI agent（你）在接管新服务器后，看到 `AGENTS.md` 或用户提及 skills，就应该执行以上两步。

---

## Skill 目录（共 55 个）

### 🤖 Hermes 运维 & Agent 协作

- **hermes-ops**: Hermes 运维操作（TUI、Dashboard 调试）
- **skill-lifecycle**: Skill 生命周期管理
- **external-agent-coordination**: 多 Agent 协作编排（Codex CLI、AgentMemory MCP）
- **agentmemory-mcp**: AgentMemory MCP 服务接入

### 🌐 消息平台网关

- **chinese-messaging-platforms**: 飞书/钉钉/企微/微信/QQ Bot 等网关配置
- **china-network-mirrors**: 中国区网络镜像加速配置

### 📄 文档 & 演示

- **paper-deep-read**: 学术论文三层精读（概览→方法→创新）+ PDF 解析
- **ppt-forge**: 华为风格高密度 PPT 全链路制作
- **html-ppt**: HTML 幻灯片制作（16:9 scroll-snap 翻页）

### 📐 编码规范

- **karpathy-guidelines**: Karpathy 风格编码规范

### 🖥️ Ascend NPU 基础

- **ascend-dmi**: Ascend DMI 诊断工具
- **npu-smi**: NPU-SMI 管理与监控
- **npu-docker-launcher**: NPU Docker 容器启动
- **ascend-docker**: Ascend Docker 环境配置
- **ascend-avi-vnpu**: Ascend AVI / vNPU 虚拟化
- **torch_npu**: torch_npu 框架与 MCP 工具
- **remote-npu-test**: 远程 NPU 测试
- **remote-server-guide**: 远程服务器接入指南（SSH/Fabric/Paramiko）

### ⚙️ Ascend 推理 & 模型转换

- **atc-model-converter**: ATC 模型转换（ONNX→OM）
- **ascend-migration-analysis**: PyTorch → Ascend 迁移分析
- **vllm-ascend**: vLLM Ascend 推理框架
- **vllm-ascend-server**: vLLM Ascend 服务部署
- **vllm-ascend-opt-analyse**: vLLM Ascend 模型优化扫描，按当前代码链路反查 Qwen3.5 / Qwen3-VL / GLM5 / DeepSeek V4 / MiniMax / Kimi / Gemma4 的缺口与可迁移优化模式
- **vllm-bench-serve**: vLLM 压测与调优
- **npu-torchair-infer**: TorchAir 推理 benchmark
- **wan-ascend-adaptation**: WAN 视频生成模型 Ascend 适配
- **diffusers-ascend-env-setup**: Diffusers Ascend 环境搭建
- **diffusers-ascend-pipeline**: Diffusers Ascend 推理流水线
- **diffusers-ascend-weight-prep**: Diffusers Ascend 权重准备
- **msmodelslim-quant**: MSModelSlim 量化工具
- **inferencex-report**: InferenceX 性能报告生成
- **inference-precision-tensor-dump-compare**: 推理精度 Tensor Dump 比对
- **ais-bench**: AI 基准测试（精度/性能）
- **migration-ascend-torchnpu-skills**: torch_npu 整体迁移技能
- **migration-ascend-torchnpu-skills-environment-setup**: torch_npu 迁移环境搭建
- **migration-ascend-torchnpu-skills-migration-execution**: torch_npu 迁移执行
- **migration-ascend-torchnpu-skills-torch-npu-reference**: torch_npu 迁移参考

### 🧮 Ascend 算子开发

- **ascendc**: AscendC 算子开发（完整模板+调试+精度评估）
- **ascend-opplugin**: Ascend OP Plugin 算子插件开发
- **npu-op-benchmark**: NPU 算子性能基准测试
- **triton-ascend-migration**: Triton → Ascend 算子迁移

### 📊 Ascend 性能分析

- **profiling-analysis**: Profiling 性能分析主流程
- **profiling-analysis-communication**: 通信算子性能分析
- **profiling-analysis-computing**: 计算算子性能分析
- **profiling-analysis-hostbound**: Host 瓶颈分析
- **pytorch-profiling-collection**: PyTorch Profiling 数据采集
- **mindspeed-llm-train-profiler**: MindSpeed LLM 训练 Profiler
- **mindspeed-mm-train-profiler**: MindSpeed 多模态 Profiler
- **training-mfu-calculator**: 训练 MFU 计算器

### 🔧 Git / 项目管理

- **gitcode-merge-flow**: GitCode 合并流程（Issue/PR 创建与审核）
- **github-issue-rca**: GitHub Issue 根因分析
- **github-issue-summary**: GitHub Issue 汇总与分类
- **vllm-daily-pr-issue-tracker**: vLLM 每日 PR/Issue 追踪
- **hiascend-forum-analyzer**: HiAscend 论坛 Issue 分析
- **hiascend-forum-fetcher**: HiAscend 论坛 Issue 采集

---

## sync.sh 用法

| 参数 | 作用 |
|------|------|
| `--all` | 安装到所有已检测到的工具 |
| `--hermes` | 仅 Hermes (`~/.hermes/skills/`) |
| `--codex` | 仅 Codex (`~/.codex/skills/`) |
| `--claude` | 仅 Claude Code (`~/.claude/skills/`) |
| `--link` | 软链接模式（默认，更新仓库即时生效） |
| `--copy` | 复制模式（更新后需重新运行） |
| `--dry-run` | 预览不执行 |

无参数时进入交互选择模式。

---

## 支持的 AI 工具

| 工具 | skill 路径 | 同步方式 |
|------|-----------|--------|
| Hermes Agent | `~/.hermes/skills/<name>/SKILL.md` | 软链接 |
| Codex CLI | `~/.codex/skills/<name>/SKILL.md` | 软链接 |
| Claude Code | `~/.claude/skills/<name>.md` | 复制（单文件） |

---

## 新增推荐 Skill

### `vllm-ascend-opt-analyse`

适用场景：

- 扫描 `vllm-ascend` 与上游 `vllm` 当前代码链路，找模型性能优化缺口
- 用跨模型经验反扫 `Qwen3.5 / Qwen3-VL / GLM5.1/5.2 / DeepSeek V4 Flash/Pro / MiniMax M2.x / Kimi K2.x / Gemma4`
- 必要时回查 git 历史，把已有优化收敛成可迁移模式库

安装后在 Codex / Hermes 中可直接通过 skill 名触发，例如：

```text
$vllm-ascend-opt-analyse 分析 /path/to/vllm-ascend 和 /path/to/vllm 的 qwen3.5 当前链路，还有什么性能优化点
```
