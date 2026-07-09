# Qwen3.6 / Qwen3.x benchmark lookup notes

Session-derived notes for researching Qwen-family inference performance in InferenceX and public sources.

## What worked

- InferenceX benchmark endpoint accepts a small set of display names, e.g.:
  `https://inferencex.semianalysis.com/api/v1/benchmarks?model=Qwen-3.5-397B-A17B`
- Some responses are gzip-compressed; handle both compressed and plain JSON.
- For H100/H800-style summaries, filter records by `hardware` and compute total output throughput as:
  `metrics.output_tput_per_gpu * num_decode_gpu`.
- InferenceX records may expose both:
  - `metrics.tput_per_gpu`: total token throughput per GPU, often includes input+output workload effects.
  - `metrics.output_tput_per_gpu`: output/decode throughput per GPU; use this for user questions asking "output token/s".
- The concurrency/batch field in InferenceX is `conc`; report it as `batch/conc` unless the benchmark source explicitly says offline batch size.
- Useful fields for deployment shape: `num_prefill_gpu`, `num_decode_gpu`, `prefill_tp`, `decode_tp`, `isl`, `osl`, `framework`, `precision`, `date`, `run_url`.

## Qwen3.6-35B-A3B finding

As of the checked session, `Qwen/Qwen3.6-35B-A3B` exists on ModelScope and the ModelScope model API reports architecture `Qwen3_5MoeForConditionalGeneration`, but InferenceX did not accept `Qwen3.6-35B-A3B` or `Qwen3-35B-A3B` as `model=` values. Public Bing/RSS searches for exact `"Qwen3.6-35B-A3B"` plus `H100`, `H800`, `tokens/s`, or `vllm` did not surface a usable H100/H800 throughput table.

Do not substitute `Qwen-3.5-397B-A17B` numbers as if they were Qwen3.6-35B-A3B. If using Qwen-3.5 data as a nearby public reference, clearly label it as a different model.

## Recommended output table for this class of question

| Model | GPU | Framework | Precision | GPUs | ISL | OSL | Batch/Conc | Output tok/s | Output tok/s/GPU | TTFT | TPOT | Source |

When data is missing, state precisely which model/hardware combination lacks public data and suggest a reproducible `vllm bench serve` or SGLang benchmark recipe rather than guessing a fixed H100→H800 scaling factor.
