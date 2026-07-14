# Pattern Examples

This file turns concrete commits into reusable optimization language. Reuse these phrases when the user wants a transferable idea set rather than raw commit history.

## Pattern 1: Precompute Once, Reuse At Runtime

Meaning:

- Move runtime metadata or helper tensor construction into builder or preprocessing stages
- Reuse the same prepared object across steps instead of rebuilding every iteration

Representative commits:

- `9bf9b4b2` Qwen3.5 GDN prebuild chunk metadata
- `2231a3c3` Qwen3.5 GDN fallback metadata completion
- `47d3614f` Qwen3.5 formal builder/backend reuse of host metadata
- `cbfe0e14` DeepSeek V4 DSA compressor metadata on device

Good summary wording:

- "把每步都要临时算的 metadata 提前构造好，运行时直接复用。"

## Pattern 2: Keep Metadata On Device

Meaning:

- Avoid repeated host-to-device or device-to-host conversions for small hot-path control data
- Store runtime metadata as device tensors when the operator consumes it on device anyway

Representative commits:

- `432743d8` Qwen GDN conv1d metadata moved to device tensors
- `cbfe0e14` DeepSeek V4 compressor metadata on device

Good summary wording:

- "能留在 device 的控制信息就别回 host，尤其是热路径元数据。"

## Pattern 3: Reuse Top-k / Index Results Instead Of Recomputing

Meaning:

- If neighboring layers or next decode steps can reuse sparse-routing or index outputs, keep and reuse them
- Separate "need module weights" from "need to recompute top-k"

Representative commits:

- `c5ae281d` GLM-5.2 shared indexer adaptation
- `463a6a1d` GLM5.2 top-k index reuse
- `929e461d` GLM-5.1 IndexCache weight loading fix
- `711a09f7` DeepSeek V4 IndexCache reuse across decode steps

Good summary wording:

- "把索引结果当缓存资产，而不是默认每层每步都重算。"

## Pattern 4: Turn Temporary Patch Logic Into Formal Backend Paths

Meaning:

- Replace monkey patch or ad hoc overrides with stable backend, builder, or torch binding paths
- Reduce runtime branch clutter and hidden coupling

Representative commits:

- `47d3614f` Qwen GDN patch path folded into formal backend/builder
- `249465be` Qwen recurrent op routed through torch binding
- `cebff41e` DeepSeek V4 cache hooks moved into model

Good summary wording:

- "先靠 patch 跑通，再把高频路径收敛成正式 backend。"

## Pattern 5: Split Mixed Execution Paths So State Stops Leaking

Meaning:

- Dense, MoE, MTP, draft, compress, graph, and PCP paths often have different state needs
- Bugs appear when one path assumes another path's shapes, cache ownership, or placeholders

Representative commits:

- `2f8934ae` Qwen3.x multi-layer KV cache binding fix
- `19278374` DeepSeek V4 separate MTP layer KV cache sharding
- `9872bb99` avoid allocating KV cache for skipped indexers
- `929e461d` GLM shared-indexer vs per-layer indexer split

Good summary wording:

- "把混合路径拆清楚，别让共享状态假装通用。"

## Pattern 6: Cut Work That Does Not Change The Active Request

Meaning:

- Skip useless slot mapping, dummy graph prep, redundant renormalization, or repeated profiling
- Prune by group, role, or request type

Representative commits:

- `46356897` skip compute_slot_mapping for mamba group
- `49a1fed1` skip DSV4 pre-KV graph memory profiling
- `2a77209a` remove redundant MoE renormalization

Good summary wording:

- "无效工作先剪掉，再谈更重的算子优化。"

## Pattern 7: Make KV / Cache / Communication Flows Role-Aware

Meaning:

- Different KV groups, transfer roles, compress ratios, or partial-group consumers need different handling
- Layout, sharding, and transfer logic should track role and group explicitly

Representative commits:

- `eb2bdc2e` DeepSeek V4 kv pool adaptation
- `e6960fa4` AscendStoreCoordinator hybrid cache-hit coordination
- `f84b46be` Qwen3.5 hybrid PCP/DCP Mooncake connector
- `fad64647` KV consumer partial-group caching for hybrid Mamba models

Good summary wording:

- "把 KV 和通信对象做成按组、按角色、按压缩比流转。"

## Pattern 8: Fix Precision By Repairing The True Quantized Contract

Meaning:

- Accuracy bugs often come from wrong bias, rotary, clamp, or split assumptions in quantized paths
- Prefer fixing the exact contract instead of hiding the problem behind a coarser workaround

Representative commits:

- `0954fd09` GLM-5 flashcomm1 quant bias fix
- `0c659e91` GLM5 rotary quant MTP precision fix
- `79d1c6b2` DeepSeek V4 dequant_swiglu_quant precision fix

Good summary wording:

- "别只换回保守路径，要把量化契约修对。"

## Pattern 9: Fix TP / Shard Contracts Instead Of Hiding The Symptom

Meaning:

- When tensor-parallel or MoE paths are wrong, prefer fixing shard ownership,
  reduction behavior, and norm-weight partitioning instead of falling back to a
  less structured workaround

Representative commits:

- `54668e73` MiniMax-M2.5 NPU support with fp8 dequant and TP path adaptation
- `61dd93cf` Eagle3 support for MiniMax-M2.5

Good summary wording:

- "先把 TP、MoE、norm 的切分契约修对，再谈兜底绕行。"

## Pattern 10: Preserve Quantized Dtype / Scale Contracts Through Loader Paths

Meaning:

- Quantized models often fail not in the main compute kernel but during model
  initialization or `.to()` transitions that silently coerce dtype
- Fix the dtype/scale contract in the load path instead of post-hoc patching
  the symptom later

Representative commits:

- `54668e73` MiniMax fp8 block-weight dequant during load
- `0e4d7731` Kimi MoonViT `.to()` patch preserves quantized ViT dtype

Good summary wording:

- "量化模型先保住加载链路里的 dtype 和 scale 契约。"

## Pattern 11: Platform Patches Must Track Parser / Usage / Wrapper Drift Too

Meaning:

- Model-family support is not only forward kernels; platform wrappers, usage
  accounting, streaming parsers, and API signatures also drift with upstream
- If these edges are not patched, the model looks supported but behaves
  incorrectly at serving time

Representative commits:

- `307f2b11` MiniMax reasoning usage accounting backport
- `e7840445` MiniMax tool-call streaming parser backport
- `5b77946f` MiniMax wrapper `**extra_kwargs` compatibility fix

Good summary wording:

- "模型能跑不算完，parser、usage、wrapper 这些平台边角也要跟上。"

## Pattern 12: Route Unsupported Shapes To A Stable Fallback

Meaning:

- If a model variant hits a hardware-specific unsupported shape, do not force it
  through the fused fast path
- Detect the unsupported case early and switch to the stable attention or
  execution path that preserves correctness

Representative commits:

- `ae7203aa` Gemma4 large-head attention on A2 falls back to paged attention
- `8cecff75` Gemma4 graph execution on A2/A3 separates replay params by mode

Good summary wording:

- "原来所有 shape 都硬走同一条快路径，后来把不支持的大 head 形态提前分流到稳定兜底路径。"

## Pattern 13: Make Graph Replay Metadata Layer-Aware

Meaning:

- Mixed PA/FIA or mixed-layer execution cannot safely share one coarse replay
  state blob
- Bind replay metadata, workspaces, or preparation state to the actual layer or
  execution role that consumes it

Representative commits:

- `8cecff75` Gemma4 mixed PA/FIA graph execution on A2/A3
- `8cc7bcd4` A5 Gemma4 replay metadata and workspace reuse by layer name

Good summary wording:

- "原来不同层共用一份图执行状态，后来改成按 layer 和执行模式分别记录、分别复用。"

## Pattern 14: Repair Family-Specific Quant Mapping Instead Of Global Guessing

Meaning:

- Quantized families often need loader-time mapping that respects their true
  packed layout, MoE prefix naming, or `k_eq_v` contract
- Scope the repair to the target family so a Gemma4 fix does not accidentally
  perturb other models

Representative commits:

- `25412165` Gemma4 ModelSlim quantization mapping and `k_eq_v` handling
- `54668e73` MiniMax fp8 block-weight dequant during load

Good summary wording:

- "原来加载器按通用规则猜量化映射，后来补成模型家族定制映射，把 packed layout 和前缀契约修对。"
