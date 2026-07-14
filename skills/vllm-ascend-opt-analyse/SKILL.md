---
name: vllm-ascend-opt-analyse
description: Scan current vllm-ascend and vllm codepaths for model-specific optimization gaps, reuse commit-backed patterns from Qwen3.5/Qwen3-VL, GLM5.1/5.2, DeepSeek V4 Flash/Pro, MiniMax M2, Kimi K2.x, Gemma-family or new models, and only fall back to git history when proof or prior implementations are needed.
---

# vLLM Ascend Optimization Analyse

Use this skill when the user wants to scan the current `vllm-ascend` plus upstream `vllm` codepaths for missed optimization opportunities, compare adaptation patterns across models, or confirm whether a suspected optimization already has historical proof.

## When To Use

Trigger this skill when the request is about any of these:

- Scanning the current codebase for a model family's missing performance work
- Re-checking an existing model such as `Qwen3.5` through cross-model optimization lenses
- Comparing current implementation paths against known optimization patterns from other models
- Scanning `git log`, `git show`, or diffs for a model family in `vllm-ascend` when evidence is needed
- Summarizing optimization commits for `Qwen3.5`, `Qwen3-VL`, `GLM5.1/5.2`, `DeepSeek V4`, `MiniMax M2.x`, `Kimi K2.x`, `Gemma-family`, or another new model
- Converting commit history into reusable optimization patterns
- Checking whether a new model still misses known Ascend-side optimizations
- Deep-diving one commit to explain "before vs after vs why it helps"

Do not use this skill for general model architecture explanations unless they are needed to interpret a concrete `vllm-ascend` optimization commit.

## Workflow

Default working mode is `current-gap-scan`.

Use `history-evidence` mode only when the user explicitly asks for commit
history, version chronology, or code-before-vs-after analysis.

### 1. Read the current implementation path first

Start from today's code, not from git history.

- Identify the live codepath in both `vllm-ascend` and paired upstream `vllm`
- Prefer `rg`, path search, and focused file reads over broad history scans
- Trace the model's active path through patch files, attention backends,
  quantization loaders, KV transfer, graph execution, and multimodal branches
- Write down where runtime work is still rebuilt, bounced through host, or
  shared too broadly across mixed execution modes

The goal of this step is to build a "current bottleneck map", not a timeline.

### 2. Scan the live code against the pattern library

Use [references/pattern-examples.md](references/pattern-examples.md) and
[references/family-notes.md](references/family-notes.md) as a reusable
optimization checklist.

For each active path, ask:

- Is metadata rebuilt every prefill or decode step when it could be prepared once?
- Are small control tensors or shape descriptors still hopping host <-> device?
- Are graph replay params, KV ownership, TP shards, MoE roles, or multimodal
  branches sharing state that should be split?
- Does the quantized load path preserve the true dtype, scale, prefix, and
  packed-layout contract?
- Are unsupported shapes still forced through a fused path instead of an early
  stable fallback?
- Are parser, wrapper, reasoning usage, or serving edge paths still lagging
  behind the model core path?

Turn the answers into three buckets:

- `confirmed optimization gap`
- `candidate optimization idea`
- `already covered in current code`

### 3. Pull git history only when it helps prove or reuse a fix

History is now a support layer, not the default entry point.

- Prefer `git log --all --format=... --grep=...`
- Also use `git log -G` or path-restricted history when commit messages are too weak
- Search commit message, file path, code comments, and diff text
- Read only enough `git show --stat --name-only` and focused diff hunks to confirm scope

For repeatable keyword sets and candidate generation, read [references/model-keywords.md](references/model-keywords.md) and use `scripts/collect_candidates.py` if that is faster than hand-written commands.

Use history in only two cases:

- to prove that an optimization idea already has a model-specific implementation precedent
- to explain "before vs after vs why it helps" for a named commit or file path

### 4. Keep historical evidence model-specific and commit-backed

Every retained item must be bound to a real git commit and a real model-specific implementation clue.

Keep commits that satisfy at least one of these:

- Commit message explicitly names the target model family
- Changed files belong to the target model's patch/backend/operator path
- Diff or code comments clearly mention the target model or its exclusive runtime path

Drop commits that are only:

- documentation
- translation
- CI baseline changes
- test case churn
- generic infra changes that cannot be tied back to the target model

If a commit is promising but not provable, label it as a `candidate observation` instead of a confirmed optimization.

When the user asks about a specific version but the repo mainly contains shared
family implementations, use a two-layer judgment:

- `confirmed-version-specific`: commit or diff clearly names the requested version
- `confirmed-family-shared`: commit is strongly tied to the same family path, but not explicitly to the requested version

Do not collapse these two layers together. For example, if the repo has
`MiniMax M2` or `Kimi-K2.5` evidence but not `M2.7` or `K2.6` directly, say so
clearly and treat the shared-family evidence as reusable but not version-proven.

### 5. Extract the minimal evidence packet when history is used

For every confirmed commit, capture:

- commit id
- date
- author
- commit summary
- main changed files
- original implementation path
- new implementation path
- expected or stated gain
- fixed category from [references/classification-rules.md](references/classification-rules.md)
- one-line reusable optimization idea

Do not paste large diffs by default. Only include a small snippet when the user explicitly asks for code comparison or when a short snippet is the clearest proof.

### 6. Rewrite evidence into reusable optimization language

After classifying commits, rewrite them into "optimization thought patterns" that can transfer to another model.

Use the pattern style from [references/pattern-examples.md](references/pattern-examples.md). Typical wording:

- precompute once, reuse at runtime
- keep metadata on device instead of bouncing through host
- turn temporary patches into formal backend or builder paths
- split mixed execution paths so they stop sharing wrong state
- cut work that does not affect the active request
- make KV, cache, and communication flows role-aware or group-aware

Every pattern must cite at least one real commit example.

### 7. Choose the right output mode

Use one of these four output modes. Templates live in [references/output-formats.md](references/output-formats.md).

- `gap-scan`: default mode for current-code optimization review
- `commit-summary`: for a model family's confirmed optimization history
- `pattern-library`: for cross-model reusable optimization methods
- `scan-checklist`: for analyzing what a new model may still be missing

Default to concise summaries. Only go deep on bottom-layer implementation when the user explicitly drills into one category or one commit.

If the user does not specify a mode, assume:

- first choice: `gap-scan`
- second choice: `pattern-library`
- only then: `commit-summary`

## Model Coverage

This skill already has seed knowledge for:

- `Qwen3.5 / Qwen3.6 / Qwen3-VL`
- `GLM5.1 / GLM5.2`
- `DeepSeek V4 shared core / Flash / Pro`
- `MiniMax M2 / M2.5 / M2.7`
- `Kimi K2.5 / K2.6`
- `Gemma-family / Gemma4`

Read [references/family-notes.md](references/family-notes.md) before scanning those families so you can target the right hot paths quickly.

## Output Rules

- Do not mix unrelated models into the same conclusion block
- Do not claim a historical optimization without a commit anchor
- Current-code gap findings may be reported without a commit id, but they must
  be tied to a real live codepath and clearly labeled as:
  - `confirmed optimization gap`
  - `candidate optimization idea`
  - `already covered`
- Merge many tiny same-type fixes when the user wants a high-level summary
- Separate major architecture changes from small bug fixes
- When strict version hits are weak, split output into:
  - `strict version hits`
  - `family-shared evidence`
  - `candidate observations`
- For a gap scan, always distinguish:
  - what is visible in current code now
  - what is inferred from cross-model precedent
  - what is historically proven in git
- Keep initial output lightweight; expand only on follow-up questions

## Resources

- [references/model-keywords.md](references/model-keywords.md): keyword sets and search tips
- [references/classification-rules.md](references/classification-rules.md): six fixed categories and merge rules
- [references/pattern-examples.md](references/pattern-examples.md): reusable optimization idea phrasing with commit examples
- [references/family-notes.md](references/family-notes.md): model-family-specific hot paths already observed
- [references/output-formats.md](references/output-formats.md): response templates
- `scripts/collect_candidates.py`: helper to gather candidate commits before manual review
