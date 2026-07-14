# Classification Rules

Use exactly these six categories when the user asks for a categorized summary.

## 1. Inference Performance Optimization

Use this when the change mainly improves runtime speed, throughput, or hot-path overhead.

Typical signals:

- HBM or memory traffic reduction
- AICore operator path replacement
- prefill or decode throughput improvement
- token latency reduction
- batch concurrency improvement
- KV cache hot-path pruning
- host-device sync reduction

Examples:

- Qwen3.5 GDN metadata prebuild and reuse
- DeepSeek V4 DSA compressor metadata built on device
- GLM index reuse that skips repeated top-k work

## 2. Ascend NPU Hardware Adaptation Optimization

Use this when the main point is fitting Ascend hardware behavior or hardware-specific operator paths.

Typical signals:

- 910B / 910C / Ascend950 dedicated op path
- SDMA or transfer path changes
- HCCS or HCCL communication behavior
- custom torch binding or aclnn path
- memory reuse tied to hardware execution mode

Examples:

- DeepSeek V4 `hc_pre` switching to fused NPU op
- Qwen3.5 Ascend950 GDN gating fix

## 3. Multimodal Vision Branch Optimization

Use this when the optimization is clearly about image or vision flow.

Typical signals:

- ViT encoder
- image token path
- image feature cache
- multimodal tensor parallel
- Qwen3-VL image-side bug or optimization

If the commit only mentions generic Qwen3.5 text runtime, do not put it here.

## 4. Quantization / Precision Optimization

Use this when the change fixes quantized execution, mixed precision behavior, or accuracy drift.

Typical signals:

- INT4 / INT8 / W4A8 / W8A8 / FP16 / BF16
- quant bias or dequant path repair
- rotary quant accuracy
- mixed precision custom op alignment
- clamp or scale correctness

Examples:

- GLM5 flashcomm1 quant bias fix
- GLM5 rotary quant MTP precision fix
- DeepSeek V4 quant path precision fixes

## 5. Framework Compatibility And Bug Fix

Use this for correctness, crash, timeout, scheduler, load-weight, parser, or state consistency fixes that are not mainly performance work.

Typical signals:

- weight loading mismatch
- scheduler hang
- KV binding bug
- timeout or deadlock fix
- tool-call parser fix
- graph mode crash
- prefix cache lookup mismatch

Examples:

- GLM5.1 IndexCache weight loading fix
- DeepSeek V4 compressed prefix lookup fix

## 6. Engineering Deployment Optimization

Use this when the main gain is that the model becomes deployable or easier to configure at scale.

Typical signals:

- weight sharding
- tensor parallel slicing
- startup argument adaptation
- environment variable adaptation
- multi-node deployment path
- connector integration
- LoRA serving enablement

Examples:

- Qwen3.5 Mooncake connector integration
- DeepSeek V4 kv pool adaptation

## Merge Rules

- Merge multiple tiny bug fixes into one summary row when they fix the same feature lane.
- Keep major architecture changes as separate rows even if later fixes refine them.
- If a commit spans two categories, classify by the primary intended benefit and mention the second effect in the notes.
- Do not classify documentation, CI threshold updates, or test-only changes as optimization rows.
