# Model Keywords

Use these keyword sets to build a first candidate pool. Start broad, then narrow with file paths and diff review.

## General Search Rules

- Prefer `git log --all --format='%H%x09%ad%x09%an%x09%s' --date=short`
- Add `--regexp-ignore-case --grep='...'` for commit messages
- Add `-G '...' -- vllm_ascend tests docs` when model names hide in diff text
- Follow with `git show --stat --name-only <commit>`
- Use `rg` on the repo to find model-specific file paths before history digging

## Qwen3.5 / Qwen3.6 / Qwen3-VL

Message and diff keywords:

- `Qwen3.5`
- `Qwen3.6`
- `Qwen3-VL`
- `Qwen3VL`
- `qwen3_5`
- `qwen3_6`
- `qwen3vl`
- `qwen3-next`
- `GDN`
- `Mamba`
- `pcp`
- `flashcomm`

Path hints:

- `vllm_ascend/patch/worker/patch_qwen3_5.py`
- `vllm_ascend/ops/gdn*`
- `vllm_ascend/ops/triton/fla/*`
- `vllm_ascend/_310p/*qwen*`
- `vllm_ascend/distributed/kv_transfer/*`

## GLM5.1 / GLM5.2

Message and diff keywords:

- `GLM5`
- `GLM-5`
- `GLM5.1`
- `GLM-5.1`
- `GLM5.2`
- `GLM-5.2`
- `glm5`
- `glm47`
- `IndexCache`
- `skip_topk`
- `shared indexer`
- `rotary quant`
- `flashcomm1`

Path hints:

- `vllm_ascend/attention/sfa_v1.py`
- `vllm_ascend/patch/worker/patch_deepseek_v2.py`
- `vllm_ascend/patch/worker/patch_deepseek_mtp.py`
- `vllm_ascend/ops/linear_op.py`
- `vllm_ascend/quantization/*`

## DeepSeek V4 / Flash / Pro

Message and diff keywords:

- `DeepSeek V4`
- `DeepSeek-V4`
- `DeepseekV4`
- `DSv4`
- `dsv4`
- `DeepSeek-V4-Flash`
- `DeepSeek-V4-Pro`
- `DSA`
- `compress`
- `prefix cache`
- `IndexCache`
- `hc_pre`
- `piecewise`
- `kv pool`

Path hints:

- `vllm_ascend/models/deepseek_v4*`
- `vllm_ascend/attention/dsa_v1.py`
- `vllm_ascend/ops/dsa.py`
- `vllm_ascend/ops/rope_dsv4.py`
- `vllm_ascend/patch/platform/patch_kv_cache_*`
- `vllm_ascend/patch/worker/patch_deepseek_compressor.py`
- `vllm_ascend/distributed/kv_transfer/kv_pool/*`

## MiniMax M2 / M2.5 / M2.7

Message and diff keywords:

- `MiniMax`
- `MiniMax-M2`
- `MiniMax M2`
- `M2.5`
- `M2.7`
- `minimax_m2`
- `linear_attn`
- `fp8`
- `usage accounting`
- `tool call`
- `Eagle3`

Path hints:

- `vllm_ascend/patch/worker/patch_minimax_m2.py`
- `vllm_ascend/patch/worker/patch_minimax_m2_linear_attn.py`
- `vllm_ascend/patch/platform/patch_minimax_*`

Notes:

- If `M2.7` is not directly named, fall back to the shared `MiniMax M2`
  implementation path and label the result as `family-shared evidence`.

## Kimi K2.5 / K2.6

Message and diff keywords:

- `Kimi`
- `K2.5`
- `K2.6`
- `Kimi-K2.5`
- `Kimi-K2.6`
- `MoonViT`
- `MoonViT3d`
- `rope shape`
- `vision tower`
- `mxfp8`

Path hints:

- `vllm_ascend/patch/worker/patch_kimi_k25.py`
- Kimi-related quantization or MoonViT load fixes in `vllm_ascend/`

Notes:

- If `K2.6` is not directly named, use `K2.5` shared implementation evidence
  and clearly label it as reusable family evidence rather than version-proven.

## Gemma-family / Gemma4

Message and diff keywords:

- `Gemma`
- `Gemma4`
- `Gemma 4`
- `Gemma-4`
- `large-head`
- `ModelSlim`
- `k_eq_v`
- `FIA`
- `paged attention`

Path hints:

- `vllm_ascend/attention/attention_v1.py`
- `vllm_ascend/attention/utils.py`
- `vllm_ascend/ops/triton/rope.py`
- `vllm_ascend/quantization/modelslim_config.py`
- `vllm_ascend/ops/fused_moe/moe_mlp.py`
- `vllm_ascend/*gemma*` when present

Notes:

- `Gemma4` has confirmed implementation evidence in this repo, but much of it
  lives in generic attention and quantization files rather than Gemma-specific
  filenames.
- When scanning Gemma-family support, combine commit-message grep with path
  review in generic attention and quant loader files before concluding that the
  repo has no model-specific optimization history.

## Search Sequence

1. `git log` by commit message
2. `git log -G` by diff keywords
3. `rg` model-specific files, then `git log -- <path>`
4. `git show --stat --name-only` to confirm model relevance
5. Focused diff read for "before / after / gain"
6. If strict version hits are weak, repeat the scan with family-shared paths
   and label the outcome accordingly
