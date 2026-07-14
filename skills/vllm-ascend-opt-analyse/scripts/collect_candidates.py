#!/usr/bin/env python3
"""Collect candidate vllm-ascend commits for a model family.

This script only helps gather candidates. It does not decide whether a commit
is truly model-specific; that still needs manual review.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


KEYWORDS = {
    "qwen": [
        r"Qwen3\.5",
        r"Qwen3\.6",
        r"Qwen3-VL",
        r"Qwen3VL",
        r"qwen3_5",
        r"qwen3_6",
        r"qwen3vl",
        r"GDN",
        r"Mamba",
        r"flashcomm",
        r"pcp",
    ],
    "glm": [
        r"GLM5",
        r"GLM-5",
        r"GLM5\.1",
        r"GLM-5\.1",
        r"GLM5\.2",
        r"GLM-5\.2",
        r"IndexCache",
        r"skip_topk",
        r"shared indexer",
        r"rotary quant",
        r"flashcomm1",
    ],
    "dsv4": [
        r"DeepSeek.?V4",
        r"DeepseekV4",
        r"DSv4",
        r"dsv4",
        r"DeepSeek-V4-Flash",
        r"DeepSeek-V4-Pro",
        r"DSA",
        r"prefix cache",
        r"compress",
        r"kv pool",
        r"hc_pre",
    ],
    "minimax": [
        r"MiniMax",
        r"MiniMax-M2",
        r"MiniMax M2",
        r"M2\.5",
        r"M2\.7",
        r"minimax_m2",
        r"linear_attn",
        r"fp8",
        r"usage accounting",
        r"tool call",
        r"Eagle3",
    ],
    "kimi": [
        r"Kimi",
        r"K2\.5",
        r"K2\.6",
        r"Kimi-K2\.5",
        r"Kimi-K2\.6",
        r"MoonViT",
        r"MoonViT3d",
        r"rope shape",
        r"vision tower",
        r"mxfp8",
    ],
    "gemma": [
        r"Gemma",
        r"Gemma4",
        r"Gemma 4",
        r"Gemma-4",
    ],
}


def run_git(args: list[str], repo: Path) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout


def search(repo: Path, patterns: list[str], paths: list[str]) -> list[str]:
    grep_expr = r"\|".join(patterns)
    args = [
        "log",
        "--all",
        "--date=short",
        "--format=%H\t%ad\t%an\t%s",
        "--regexp-ignore-case",
        f"--grep={grep_expr}",
    ]
    if paths:
        args.append("--")
        args.extend(paths)
    output = run_git(args, repo)
    rows = [line for line in output.splitlines() if line.strip()]
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "family",
        choices=sorted(KEYWORDS),
        help="Seed keyword family: qwen, glm, dsv4, minimax, kimi, or gemma",
    )
    parser.add_argument(
        "--repo",
        default=".",
        help="Path to the vllm-ascend repository root",
    )
    parser.add_argument(
        "--path",
        action="append",
        default=["vllm_ascend", "tests", "docs"],
        help="Optional path filters passed to git log; can be repeated",
    )
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    if not (repo / ".git").exists():
        print(f"error: {repo} does not look like a git repo root", file=sys.stderr)
        return 2

    rows = search(repo, KEYWORDS[args.family], args.path)
    seen = set()
    for row in rows:
        commit = row.split("\t", 1)[0]
        if commit in seen:
            continue
        seen.add(commit)
        print(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
