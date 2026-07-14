# Family Notes

Use this file to quickly target the most likely optimization surfaces for each seeded model family.

## Qwen3.5 / Qwen3.6 / Qwen3-VL

Known hot paths:

- Hybrid attention plus GDN / Mamba prefill
- chunk metadata and conv1d metadata handling
- host-device sync in fallback and builder paths
- PCP + MTP interactions
- FlashComm / MoE shared expert paths
- ACLGraph plus DP / PP / KV interleave stability
- Mooncake KV transfer and hybrid cache paths

Commit anchors already known:

- `9bf9b4b2`, `2231a3c3`, `47d3614f`, `432743d8`
- `c6343b13`, `9d1c855e`, `5270d846`
- `f84b46be`, `8116bcdc`, `2f8934ae`

Interpretation shortcut:

- Qwen's strongest recurring pattern is "runtime metadata and small control tensors were originally rebuilt or bounced through host, then gradually moved into reusable builder or device-side flows."

## GLM5.1 / GLM5.2

Known hot paths:

- shared-indexer and per-layer IndexCache behavior
- `skip_topk` semantics versus checkpoint structure
- RoPE and rotary quant precision
- MTP hidden-state or draft transfer correctness
- flashcomm1 quantized output projection precision
- SFA / DSA-CP path compatibility

Commit anchors already known:

- `c5ae281d` GLM-5.2 adaptation with shared indexer
- `463a6a1d` GLM5.2 top-k index reuse
- `929e461d` GLM-5.1 IndexCache weight loading fix
- `9872bb99` skipped-indexer KV cache allocation fix
- `0954fd09` flashcomm1 quant bias fix
- `b1cc6ef6` DSA-CP precision fix
- `0c659e91` rotary quant MTP precision fix

Interpretation shortcut:

- GLM's recurring theme is "sparse/indexer reuse is valuable, but runtime reuse, checkpoint structure, and KV allocation policy must be modeled separately or weight loading and precision both break."

## DeepSeek V4 Shared Core / Flash / Pro

Known hot paths:

- DSA attention backend and compressor flow
- prefix cache under compressed or grouped layouts
- `hc_pre` op path
- multi-stream overlap between compute and communication
- KV pool and grouped cache metadata
- MTP cache sharding and acceptance
- graph or piecewise execution modes
- custom op enablement across A2 / A3 / Ascend950

Commit anchors already known:

- `7bce23cc` base model support
- `d31c223a` fused `hc_pre`
- `20e338bd`, `2331144f`, `7726528e` overlap and CV parallel
- `711a09f7` IndexCache top-k reuse
- `eb2bdc2e` kv pool adaptation
- `e6960fa4` hybrid cache-hit coordination
- `cbfe0e14` compressor metadata on device
- `4ad76e0e` sliding-window block-size alignment

Interpretation shortcut:

- DeepSeek V4 optimization is dominated by "compressed sparse attention is only efficient when metadata, cache grouping, byte-stride transfer, and overlap scheduling are all explicit and hardware-aware."

## MiniMax M2 / M2.5 / M2.7

Known hot paths:

- MoE all-reduce and tensor-parallel reduction behavior
- `k_norm` weight sharding
- NPU q/k RMSNorm fast path
- fp8 block-weight dequantization during weight loading
- Eagle3 auxiliary hidden-state support
- tool-call streaming parser behavior
- reasoning usage accounting and wrapper compatibility

Commit anchors already known:

- `54668e73` MiniMax-M2.5 NPU support
- `61dd93cf` Eagle3 applied to MiniMax-M2.5
- `307f2b11` MiniMax reasoning usage accounting backport
- `e7840445` MiniMax M2 tool-call streaming backport
- `5b77946f` MiniMax wrapper accepts `**extra_kwargs`
- `0f91a197` scope MiniMax usage accounting patch

Interpretation shortcut:

- MiniMax family optimization is split between core model adaptation
  (`fp8 -> bf16 dequant`, TP/MoE contracts, NPU q/k norm) and platform-side
  compatibility patches (usage accounting, parser streaming, wrapper forward
  compatibility).

Version note:

- `M2.7` currently should be treated as a family-shared scan target unless the
  repo yields direct version-specific evidence.

## Kimi K2.5 / K2.6

Known hot paths:

- rope-shape construction avoiding device-to-host hops
- MoonViT position embedding / interpolation path
- quantized ViT dtype preservation on Ascend950 / A5
- Kimi family base support under bf16 / w4a8
- dense-draft versus MoE path discrimination in Kimi-MLA family code

Commit anchors already known:

- `ed051737` support Kimi-K2.5 models
- `b2e71b79` fix `get_rope_shape` for Kimi-K2.5
- `0e4d7731` preserve quantized MoonViT dtype on A5
- `fcf5a1d5` Kimi-MLA dense draft model no longer misidentified as MoE

Interpretation shortcut:

- Kimi family optimization is mostly about multimodal and vision-side runtime
  correctness: stop unnecessary device-host transitions, preserve quantized
  weight dtypes, keep the MoonViT path aligned with Ascend quantization, and
  avoid routing dense draft paths into MoE-only logic.

Version note:

- `K2.6` currently should default to `family-shared evidence` based on `K2.5`
  unless direct `K2.6` commits appear.

## Gemma-family / Gemma4

Known hot paths:

- large-head attention routing on A2/A3
- mixed PA/FIA graph execution replay state
- layer-aware graph replay metadata and workspace reuse on A5
- ModelSlim quantization mapping for Gemma4 MoE and `k_eq_v` layouts
- activation and routing differences in Gemma4 MoE execution

Commit anchors already known:

- `25412165` Gemma4 ModelSlim quantization
- `8cecff75` Gemma4 graph execution on A2/A3
- `ae7203aa` Gemma4 large-head attention on A2
- `8cc7bcd4` A5 support for Gemma4

Interpretation shortcut:

- Gemma4 optimization is centered on "原来把不同 head 形态、图执行模式、
  量化映射都当成通用路径处理，后来按硬件能力、layer 角色、量化布局拆开
  建模"，这样既避免错误复用图状态，也避免在不支持的大 head 形态上硬走
  融合路径。
