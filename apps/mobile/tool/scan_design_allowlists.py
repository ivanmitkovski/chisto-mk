#!/usr/bin/env python3
"""Regenerate design-system allowlists (matches dart check_* scripts)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

RADIUS_ROOTS = ("lib/features", "lib/shared")
RADIUS_SKIP = (
    "app_radii.dart",
    "app_spacing.dart",
    "app_card_chrome.dart",
    "app_input_outline.dart",
)
RADIUS_RE = re.compile(r"BorderRadius\.circular\(\s*\d")

SHADOW_ROOTS = ("lib/features", "lib/shared")
SHADOW_SKIP = ("core/theme/", "app_shadows.dart", "app_card_chrome.dart")


def scan(roots: tuple[str, ...], skip: tuple[str, ...], match_line) -> list[str]:
    hits: list[str] = []
    for root_name in roots:
        root = ROOT / root_name
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.dart")):
            normalized = path.as_posix().replace("\\", "/")
            rel = normalized.removeprefix(f"{ROOT.as_posix()}/")
            if any(fragment in rel for fragment in skip):
                continue
            lines = path.read_text(encoding="utf").splitlines()
            for i, line in enumerate(lines, start=1):
                if match_line(line):
                    hits.append(f"{rel}:{i}")
    hits.sort()
    return hits


def write_allowlist(path: Path, hits: list[str]) -> None:
    path.write_text("\n".join(hits) + ("\n" if hits else ""), encoding="utf")


def main() -> int:
    radius_hits = scan(RADIUS_ROOTS, RADIUS_SKIP, lambda line: bool(RADIUS_RE.search(line)))
    shadow_hits = scan(
        SHADOW_ROOTS,
        SHADOW_SKIP,
        lambda line: "BoxShadow(" in line,
    )

    radius_path = ROOT / "tool/raw_radius_allowlist.txt"
    shadow_path = ROOT / "tool/raw_shadow_allowlist.txt"

    write_allowlist(radius_path, radius_hits)
    write_allowlist(shadow_path, shadow_hits)

    print(f"raw_radius_allowlist.txt: {len(radius_hits)} entries")
    print(f"raw_shadow_allowlist.txt: {len(shadow_hits)} entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())
