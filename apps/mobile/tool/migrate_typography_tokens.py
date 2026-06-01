#!/usr/bin/env python3
"""Migrate AppTypography const token usages to TextTheme-taking helpers."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

TOKENS = (
    "authHeadline",
    "microLabel",
    "microIndex",
    "overlayBodyMedium",
    "authTextLink",
    "authTextLinkUnderline",
    "galleryMoreCount",
    "authSubtitle",
    "pillLabel",
    "sectionHeader",
    "cardTitle",
    "cardSubtitle",
    "chipLabel",
    "sheetTitle",
    "badgeLabel",
    "emptyStateTitle",
    "emptyStateSubtitle",
    "buttonLabel",
)

TOKEN_PATTERN = "|".join(re.escape(t) for t in TOKENS)


def needs_text_theme(content: str) -> bool:
    for token in TOKENS:
        if re.search(rf"AppTypography\.{token}(?!\()", content):
            return True
    return False


def inject_text_theme(content: str) -> str:
    if "final TextTheme textTheme = Theme.of(context).textTheme;" in content:
        return content
    if "TextTheme textTheme = Theme.of(context).textTheme" in content:
        return content

    # Insert after first `Widget build(BuildContext context)` opening brace
    match = re.search(
        r"(Widget build\(BuildContext context\)\s*\{)\n",
        content,
    )
    if match:
        insert_at = match.end()
        return (
            content[:insert_at]
            + "    final TextTheme textTheme = Theme.of(context).textTheme;\n"
            + content[insert_at:]
        )

    # State class methods: after `BuildContext context)` in other methods
    for pattern in (
        r"((?:Widget|TextStyle)\s+\w+\([^)]*BuildContext context[^)]*\)\s*\{)\n",
    ):
        match = re.search(pattern, content)
        if match and needs_text_theme(content):
            insert_at = match.end()
            snippet = content[match.start() : insert_at + 200]
            if "textTheme = Theme.of(context)" not in snippet:
                return (
                    content[:insert_at]
                    + "    final TextTheme textTheme = Theme.of(context).textTheme;\n"
                    + content[insert_at:]
                )
    return content


def migrate_content(content: str) -> str:
    # authScreenTitle(context) -> authScreenTitle(textTheme) after inject
    content = re.sub(
        r"AppTypography\.authScreenTitle\(context\)",
        "AppTypography.authScreenTitle(textTheme)",
        content,
    )
    content = re.sub(
        r"AppTypography\.authScreenSubtitle\(context\)",
        "AppTypography.authScreenSubtitle(textTheme)",
        content,
    )

    # Already migrated: AppTypography.TOKEN(textTheme) - skip
    for token in TOKENS:
        # .copyWith on bare token
        content = re.sub(
            rf"AppTypography\.{token}\.copyWith",
            rf"AppTypography.{token}(textTheme).copyWith",
            content,
        )
        # Bare token not followed by (
        content = re.sub(
            rf"AppTypography\.{token}(?!\()",
            rf"AppTypography.{token}(textTheme)",
            content,
        )

    # Fix double (textTheme)(textTheme)
    content = re.sub(
        rf"AppTypography\.({TOKEN_PATTERN})\(textTheme\)\(textTheme\)",
        r"AppTypography.\1(textTheme)",
        content,
    )

    return content


def process_file(path: Path) -> bool:
    original = path.read_text(encoding="utf-8")
    if not needs_text_theme(original):
        return False
    updated = migrate_content(original)
    if "Theme.of(context)" in updated and needs_text_theme(updated):
        updated = inject_text_theme(updated)
    if updated != original:
        path.write_text(updated, encoding="utf-8")
        return True
    return False


def main() -> int:
    roots = [
        ROOT / "packages",
        ROOT / "lib",
        ROOT / "test",
    ]
    changed = 0
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("*.dart"):
            if "app_typography" in path.name:
                continue
            if process_file(path):
                changed += 1
                print(path.relative_to(ROOT))
    print(f"Updated {changed} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
