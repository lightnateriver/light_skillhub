# Output Formats

Keep outputs concise by default. Expand only when the user asks for code comparison or bottom-layer detail.

## Mode 1: gap-scan

Use this as the default mode.

Use for one current model path in today's codebase.

Recommended structure:

1. short overview
2. Markdown table
3. short priority synthesis

Suggested columns:

| Category | Current Code Signal | Optimization Idea | Status | Suggested Validation |

Rules:

- `Current Code Signal` should cite a real live path or behavior, not an old commit
- `Status` should be one of:
  - `confirmed optimization gap`
  - `candidate optimization idea`
  - `already covered`
- `Optimization Idea` should be written in reusable design language, not as a
  patch diff dump
- If history exists, add a short `reference precedent` note inline, such as
  `similar to Gemma4 layer-aware graph replay` or `similar to Qwen3.5 metadata prebuild`

## Mode 2: commit-summary

Use for one model family.

Recommended structure:

1. short overview
2. Markdown table
3. short synthesis

Suggested columns:

| Optimization Category | Commit Summary | Core Change | Benefit | Related NPU or Model Trait |

Rules:

- One row may merge several tiny fixes if they target the same lane
- Mention commit ids in the summary cell
- Keep "Core Change" at design level, not raw code dump
- When a user asks for a specific version but the repo mostly contains
  family-shared implementation evidence, split the summary into:
  - `strict version hits`
  - `family-shared evidence`
  - `candidate observations`

## Mode 3: pattern-library

Use for cross-model common methods.

Recommended structure:

1. short overview
2. flat bullet list of patterns
3. each pattern includes:
   - idea
   - why it helps
   - representative commits
   - what to check in a new model

Suggested wording:

- "提前算好，运行时复用"
- "能留在 device 就别回 host"
- "把 patch 收敛成正式 backend"

This mode is especially useful as the bridge between history and current-code
gap scans: it turns past fixes into a reusable review lens.

## Mode 4: scan-checklist

Use when the user wants to inspect a new model or revisit an old one for missed gains.

Recommended structure:

1. model context assumptions
2. grouped checklist by the six categories
3. candidate observations
4. likely highest-yield next checks

Checklist prompt examples:

- Does the model rebuild metadata every decode step?
- Are sparse routing or top-k results reusable across layers or steps?
- Are compressed KV groups explicitly modeled in cache, scheduler, and transfer code?
- Do quantized paths preserve the real bias, rotary, clamp, and split contracts?

When strict version evidence is weak, the checklist should explicitly say
which checks are based on:

- direct version history
- family-shared implementation history
- generic candidate observations

When the user is focused on forward optimization instead of historical review,
this mode should be driven by the current code first and only use history as a
supporting rationale.

## Deep Dive Add-On

If the user names a commit and asks "how it worked before and after", add:

- original path
- new path
- short code snippet comparison
- where the saved work comes from

Keep snippets short and only show the lines that prove the design shift.
