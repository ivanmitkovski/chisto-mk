#!/usr/bin/env python3
"""Fix typography migration fallout: textTheme scope + broken token names."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def fix_content(content: str) -> str:
    content = content.replace(
        "AppTypography.authTextLink(textTheme)Underline",
        "AppTypography.authTextLinkUnderline(textTheme)",
    )
    content = re.sub(
        r"AppTypography\.authScreenTitle\(context\)",
        "AppTypography.authScreenTitle(Theme.of(context).textTheme)",
        content,
    )
    content = re.sub(
        r"AppTypography\.authScreenSubtitle\(context\)",
        "AppTypography.authScreenSubtitle(Theme.of(context).textTheme)",
        content,
    )
    # Static helpers without context: use design-time textTheme
    content = re.sub(
        r"AppTypography\.(\w+)\(textTheme\)",
        lambda m: (
            f"AppTypography.{m.group(1)}(AppTypography.textTheme)"
            if "_titleStyleForVariant" in content
            and m.group(0) in content
            else m.group(0)
        ),
        content,
        count=0,
    )
    return content


def inject_text_theme_in_methods(content: str) -> str:
    if "(textTheme)" not in content and "textTheme)" not in content:
        return content

    lines = content.splitlines(keepends=True)
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        out.append(line)

        # Match method signatures with BuildContext context
        method_match = re.match(
            r"^(\s+)(?:@\w+\s+)*"
            r"(?:Widget|TextStyle|void|Future<[\w<>?,\s]+>|[\w<>?,\s]+)\s+\w+\("
            r"[^)]*BuildContext context[^)]*\)\s*\{\s*$",
            line,
        )
        if method_match and "(textTheme)" in content:
            indent = method_match.group(1)
            # Collect method body until matching brace depth
            body_start = i + 1
            depth = 1
            j = body_start
            body_lines: list[str] = []
            while j < len(lines) and depth > 0:
                body_lines.append(lines[j])
                depth += lines[j].count("{") - lines[j].count("}")
                j += 1
            body_text = "".join(body_lines)
            inject_line = (
                f"{indent}  final TextTheme textTheme = "
                f"Theme.of(context).textTheme;\n"
            )
            has_local = (
                "final TextTheme textTheme" in body_text
                or "TextTheme textTheme =" in body_text
            )
            uses_text_theme = "textTheme)" in body_text or "(textTheme)" in body_text
            if uses_text_theme and not has_local:
                out.append(inject_line)
            i += 1
            continue
        i += 1
    return "".join(out)


def fix_static_helpers(content: str) -> str:
    # Functions without BuildContext using textTheme -> AppTypography.textTheme
    content = re.sub(
        r"TextStyle _reportSheetSubtitleStyle\(\) \{\n"
        r"  final TextStyle\? base = AppTypography\.textTheme\.bodySmall;\n"
        r"  return \(base \?\? AppTypography\.cardSubtitle\(textTheme\)\)",
        "TextStyle _reportSheetSubtitleStyle() {\n"
        "  final TextStyle? base = AppTypography.textTheme.bodySmall;\n"
        "  return (base ?? AppTypography.cardSubtitle(AppTypography.textTheme))",
        content,
    )
    # _titleStyleForVariant needs TextTheme param
    if "_titleStyleForVariant(AppSectionHeaderVariant variant)" in content:
        content = content.replace(
            "titleStyle ?? _titleStyleForVariant(variant);",
            "titleStyle ?? _titleStyleForVariant(context, variant);",
        )
        content = content.replace(
            "TextStyle _titleStyleForVariant(AppSectionHeaderVariant variant) {",
            "TextStyle _titleStyleForVariant(\n"
            "    BuildContext context,\n"
            "    AppSectionHeaderVariant variant,\n"
            "  ) {\n"
            "    final TextTheme textTheme = Theme.of(context).textTheme;",
        )
    return content


def process_file(path: Path) -> bool:
    original = path.read_text(encoding="utf-8")
    updated = fix_content(original)
    updated = fix_static_helpers(updated)
    updated = inject_text_theme_in_methods(updated)
    if updated != original:
        path.write_text(updated, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed = 0
    for path in (ROOT / "packages").rglob("*.dart"):
        if process_file(path):
            changed += 1
            print(path.relative_to(ROOT))
    print(f"Fixed {changed} files")


if __name__ == "__main__":
    main()
