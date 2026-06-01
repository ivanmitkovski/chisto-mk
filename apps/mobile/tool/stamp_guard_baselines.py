#!/usr/bin/env python3
"""Refresh ratcheting allowlist files to match current guard scan logic."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def feature_lib_roots() -> list[Path]:
    roots: list[Path] = []
    packages = ROOT / "packages"
    if packages.is_dir():
        for pkg in sorted(packages.iterdir()):
            if pkg.is_dir() and pkg.name.startswith("feature_"):
                lib = pkg / "lib"
                if lib.is_dir():
                    roots.append(lib)
    return roots


def write_allowlist(name: str, hits: list[str]) -> None:
    path = ROOT / "tool" / name
    hits = sorted(set(hits))
    path.write_text("\n".join(hits) + ("\n" if hits else ""), encoding="utf")
    print(f"{name}: {len(hits)} entries")


def scan_lines(root: Path, match, skip: tuple[str, ...] = ()) -> list[str]:
    hits: list[str] = []
    if not root.is_dir():
        return hits
    for path in sorted(root.rglob("*.dart")):
        rel = path.as_posix().replace("\\", "/")
        short = rel.removeprefix(f"{ROOT.as_posix()}/")
        if any(fragment in short for fragment in skip):
            continue
        lines = path.read_text(encoding="utf").splitlines()
        for i, line in enumerate(lines, start=1):
            if match(line):
                hits.append(f"{short}:{i}")
    return hits


def scan_feature_roots(match, skip: tuple[str, ...] = ()) -> list[str]:
    hits: list[str] = []
    for root in feature_lib_roots():
        hits.extend(scan_lines(root, match, skip))
    return hits


def app_bootstrap_hits() -> list[str]:
    return scan_lines(ROOT / "lib", lambda line: "AppBootstrap.instance" in line)


def empty_catch_hits() -> list[str]:
    pat = re.compile(r"catch\s*\([^)]*\)\s*\{\s*\}")
    hits: list[str] = []
    for root in feature_lib_roots():
        for path in sorted(root.rglob("*.dart")):
            short = path.as_posix().removeprefix(f"{ROOT.as_posix()}/")
            content = path.read_text(encoding="utf")
            for m in pat.finditer(content):
                line = content[: m.start()].count("\n") + 1
                hits.append(f"{short}:{line}")
    return hits


def buildcontext_after_await(root: Path) -> list[str]:
    await_re = re.compile(r"\bawait\b")
    mounted = re.compile(r"\b(mounted|context\.mounted)\b")
    ctx = re.compile(
        r"\b(context\.|Navigator\.of\s*\(\s*context|ScaffoldMessenger\.of\s*\(\s*context|"
        r"Theme\.of\s*\(\s*context|MediaQuery\.of\s*\(\s*context|Localizations\.of\s*\(\s*context)"
    )
    hits: list[str] = []
    for path in sorted(root.rglob("*.dart")):
        short = path.as_posix().removeprefix(f"{ROOT.as_posix()}/")
        lines = path.read_text(encoding="utf").splitlines()
        for i, line in enumerate(lines):
            if not await_re.search(line):
                continue
            saw_guard = False
            for j in range(i + 1, min(i + 13, len(lines))):
                ln = lines[j]
                t = ln.strip()
                if not t or t.startswith("//"):
                    continue
                if mounted.search(ln):
                    saw_guard = True
                    continue
                if ctx.search(ln):
                    if not saw_guard:
                        hits.append(f"{short}:{j + 1}")
                    break
                if t == "}" or t.startswith("}"):
                    break
    return hits


def loading_empty_error_hits() -> list[str]:
    hits: list[str] = []
    for root in feature_lib_roots():
        for path in sorted(root.rglob("*_screen.dart")):
            short = path.as_posix().removeprefix(f"{ROOT.as_posix()}/")
            if "/presentation/screens/" not in short and "/src/presentation/screens/" not in short:
                continue
            content = path.read_text(encoding="utf")
            has_loading = (
                "Loading" in content or "Skeleton" in content or "AppLoadingIndicator" in content
            )
            has_empty = "Empty" in content or "empty" in content
            has_error = "Error" in content or "error" in content
            if not (has_loading and has_empty and has_error):
                hits.append(short)
    return hits


def readasbytes_hits() -> list[str]:
    pat = re.compile(r"readAsBytes(Sync)?\s*\(")
    hits: list[str] = []
    for root_name in (
        "packages/feature_reports/lib/src/data",
        "packages/feature_events/lib/src/presentation/event_chat",
        "packages/feature_profile/lib/src/presentation/avatar",
    ):
        root = ROOT / root_name
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.dart")):
            short = path.as_posix().removeprefix(f"{ROOT.as_posix()}/")
            for i, line in enumerate(path.read_text(encoding="utf").splitlines(), start=1):
                if pat.search(line):
                    hits.append(f"{short}:{i}")
    return hits


def magic_insets_hits() -> list[str]:
    pat = re.compile(r"EdgeInsets\.(all|symmetric|only|fromLTRB)\s*\([^)]*\d")

    def match(line: str) -> bool:
        if "EdgeInsets" not in line:
            return False
        if "AppSpacing" in line:
            return False
        return bool(pat.search(line))

    return scan_feature_roots(match)


def raw_textfield_hits() -> list[str]:
    skip = (
        "shared/widgets/atoms/app_text_field.dart",
        "shared/widgets/atoms/auth_text_field.dart",
        "shared/widgets/atoms/profile_password_field.dart",
        "design_system/lib/src/widgets/molecules/app_text_field.dart",
    )

    def match(line: str) -> bool:
        return bool(re.search(r"\bTextField\(", line)) or bool(
            re.search(r"\bTextFormField\(", line)
        )

    return scan_feature_roots(match, skip)


def raw_button_hits() -> list[str]:
    skip = (
        "shared/widgets/atoms/app_button.dart",
        "shared/widgets/atoms/primary_button.dart",
        "shared/widgets/organisms/auth_shell.dart",
        "design_system/lib/src/widgets/atoms/app_button.dart",
    )

    def match(line: str) -> bool:
        return any(
            x in line
            for x in (
                "FilledButton(",
                "ElevatedButton(",
                "OutlinedButton(",
                "TextButton(",
            )
        )

    return scan_feature_roots(match, skip)


def raw_progress_hits() -> list[str]:
    skip = (
        "shared/widgets/atoms/app_progress_indicator.dart",
        "design_system/lib/src/widgets/atoms/app_loading_indicator.dart",
    )

    def match(line: str) -> bool:
        return "CircularProgressIndicator(" in line or "LinearProgressIndicator(" in line

    return scan_feature_roots(match, skip)


def raw_json_hits() -> list[str]:
    def match(line: str) -> bool:
        if line.strip().startswith("//"):
            return False
        return " as Map<String, dynamic>" in line or " as List<dynamic>" in line

    hits: list[str] = []
    for root in feature_lib_roots():
        hits.extend(scan_lines(root, match))
    return hits


def cross_feature_hits() -> list[str]:
    import_re = re.compile(r"import\s+'package:chisto_mobile/features/(\w+)/")
    slug_to_package = {
        "auth": "feature_auth",
        "home": "feature_home",
        "events": "feature_events",
        "reports": "feature_reports",
        "profile": "feature_profile",
        "notifications": "feature_notifications",
        "onboarding": "feature_onboarding",
        "safety": "feature_safety",
    }
    hits: list[str] = []
    for root in feature_lib_roots():
        for path in sorted(root.rglob("*.dart")):
            short = path.as_posix().removeprefix(f"{ROOT.as_posix()}/")
            if not any(
                x in short
                for x in ("/presentation/", "/data/", "/application/", "/domain/", "/src/")
            ):
                continue
            parts = short.split("/")
            app_owner = None
            package_owner = None
            if "features" in parts:
                idx = parts.index("features")
                if idx + 1 < len(parts):
                    app_owner = parts[idx + 1]
            if "packages" in parts:
                idx = parts.index("packages")
                if idx + 1 < len(parts):
                    package_owner = parts[idx + 1]
            lines = path.read_text(encoding="utf").splitlines()
            for i, line in enumerate(lines, start=1):
                m = import_re.search(line)
                if not m:
                    continue
                target = m.group(1)
                if app_owner and target != app_owner:
                    hits.append(f"{short}:{i}")
                elif package_owner:
                    target_pkg = slug_to_package.get(target)
                    if target_pkg and target_pkg != package_owner:
                        hits.append(f"{short}:{i}")
    return hits


def read_root_presentation_hits() -> list[str]:
    hits: list[str] = []
    for root in feature_lib_roots():
        for path in sorted(root.rglob("*.dart")):
            short = path.as_posix().removeprefix(f"{ROOT.as_posix()}/")
            if "/presentation/" not in short and "/src/presentation/" not in short:
                continue
            for i, line in enumerate(path.read_text(encoding="utf").splitlines(), start=1):
                if "readRoot(" in line:
                    hits.append(f"{short}:{i}")
    return hits


def package_boundary_hits() -> list[str]:
    import_re = re.compile(r"import\s+'package:(feature_\w+)/([^']+)';")
    hits: list[str] = []
    packages = ROOT / "packages"
    if not packages.is_dir():
        return hits
    for pkg in sorted(packages.iterdir()):
        if not pkg.name.startswith("feature_"):
            continue
        lib = pkg / "lib"
        if not lib.is_dir():
            continue
        owner = pkg.name
        for path in sorted(lib.rglob("*.dart")):
            short = path.as_posix().removeprefix(f"{ROOT.as_posix()}/")
            lines = path.read_text(encoding="utf").splitlines()
            for i, line in enumerate(lines, start=1):
                m = import_re.search(line)
                if not m:
                    continue
                target_pkg = m.group(1)
                suffix = m.group(2)
                if target_pkg == owner:
                    continue
                if suffix == f"{target_pkg}.dart":
                    continue
                hits.append(f"{short}:{i}")
    return hits


def api_client_presentation_hits() -> list[str]:
    import_re = re.compile(
        r"import\s+'package:chisto_mobile/core/network/api_client\.dart'"
    )
    type_re = re.compile(r"\bApiClient\b")
    hits: list[str] = []
    for root in feature_lib_roots():
        for path in sorted(root.rglob("*.dart")):
            short = path.as_posix().removeprefix(f"{ROOT.as_posix()}/")
            if "/presentation/" not in short and "/src/presentation/" not in short:
                continue
            for i, line in enumerate(path.read_text(encoding="utf").splitlines(), start=1):
                if line.strip().startswith("//"):
                    continue
                if import_re.search(line) or type_re.search(line):
                    hits.append(f"{short}:{i}")
    return hits


def flutter_domain_hits() -> list[str]:
    import_re = re.compile(r"import\s+'package:flutter/")
    hits: list[str] = []
    for root in feature_lib_roots():
        for path in sorted(root.rglob("*.dart")):
            short = path.as_posix().removeprefix(f"{ROOT.as_posix()}/")
            if "/domain/" not in short and "/src/domain/" not in short:
                continue
            for i, line in enumerate(path.read_text(encoding="utf").splitlines(), start=1):
                if import_re.search(line):
                    hits.append(f"{short}:{i}")
    return hits


def main() -> int:
    subprocess.run(
        [sys.executable, str(ROOT / "tool/scan_design_allowlists.py")],
        check=True,
        cwd=ROOT,
    )

    write_allowlist("app_bootstrap_allowlist.txt", app_bootstrap_hits())
    write_allowlist("empty_catch_allowlist.txt", empty_catch_hits())
    bc_hits: list[str] = []
    for root in feature_lib_roots():
        bc_hits.extend(buildcontext_after_await(root))
    write_allowlist("buildcontext_after_await_allowlist.txt", bc_hits)
    reports_root = ROOT / "packages/feature_reports/lib"
    if reports_root.is_dir():
        write_allowlist(
            "reports_buildcontext_after_await_allowlist.txt",
            buildcontext_after_await(reports_root),
        )
    write_allowlist("loading_empty_error_allowlist.txt", loading_empty_error_hits())
    write_allowlist("readasbytes_upload_allowlist.txt", readasbytes_hits())
    write_allowlist("magic_edge_insets_allowlist.txt", magic_insets_hits())
    write_allowlist("raw_textfield_allowlist.txt", raw_textfield_hits())
    write_allowlist("raw_button_allowlist.txt", raw_button_hits())
    write_allowlist("raw_progress_allowlist.txt", raw_progress_hits())
    write_allowlist("raw_json_cast_allowlist.txt", raw_json_hits())
    write_allowlist("cross_feature_import_allowlist.txt", cross_feature_hits())
    write_allowlist("read_root_presentation_allowlist.txt", read_root_presentation_hits())
    write_allowlist("package_boundary_import_allowlist.txt", package_boundary_hits())
    write_allowlist("api_client_in_presentation_allowlist.txt", api_client_presentation_hits())
    write_allowlist("flutter_in_domain_allowlist.txt", flutter_domain_hits())

    subprocess.run(
        ["dart", "run", "tool/check_reports_hardcoded_strings.dart", "--stamp-baseline"],
        check=True,
        cwd=ROOT,
    )
    subprocess.run(
        ["dart", "run", "tool/check_no_inline_textstyle_overrides.dart", "--stamp-baseline"],
        check=True,
        cwd=ROOT,
    )

    print("All guard baselines stamped.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
