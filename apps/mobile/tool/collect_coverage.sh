#!/usr/bin/env bash
# Collect merged line coverage for the mobile workspace.
# Run from apps/mobile: bash tool/collect_coverage.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MERGE_DIR="$ROOT/coverage/parts"
rm -rf "$ROOT/coverage"
mkdir -p "$MERGE_DIR"

collect_flutter_package() {
  local dir="$1"
  local name="$2"
  if [[ ! -d "$dir/test" ]]; then
    return 0
  fi
  echo "Collecting coverage: $name"
  (
    cd "$dir"
    flutter test --coverage test/ >/dev/null
  )
  if [[ -f "$dir/coverage/lcov.info" ]]; then
    cp "$dir/coverage/lcov.info" "$MERGE_DIR/${name}.info"
  fi
}

collect_dart_package() {
  local dir="$1"
  local name="$2"
  if [[ ! -d "$dir/test" ]]; then
    return 0
  fi
  echo "Collecting coverage: $name"
  (
    cd "$dir"
    rm -rf coverage
    dart test --coverage=coverage test/ >/dev/null
    if [[ -f coverage/test/test.dart.vm.json ]]; then
      dart pub global activate coverage >/dev/null 2>&1 || true
      if command -v format_coverage >/dev/null 2>&1; then
        format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib
      fi
    fi
  )
  if [[ -f "$dir/coverage/lcov.info" ]]; then
    cp "$dir/coverage/lcov.info" "$MERGE_DIR/${name}.info"
  fi
}

echo "Collecting coverage: app"
flutter test --coverage test/ >/dev/null
cp "$ROOT/coverage/lcov.info" "$MERGE_DIR/app.info"

for pkg_dir in "$ROOT"/packages/*/; do
  pkg_name="$(basename "$pkg_dir")"
  if [[ ! -f "$pkg_dir/pubspec.yaml" ]]; then
    continue
  fi
  if grep -q '^  flutter:' "$pkg_dir/pubspec.yaml"; then
    collect_flutter_package "$pkg_dir" "$pkg_name"
  else
    collect_dart_package "$pkg_dir" "$pkg_name"
  fi
done

mapfile -t PARTS < <(find "$MERGE_DIR" -name '*.info' | sort)
if [[ "${#PARTS[@]}" -eq 0 ]]; then
  echo "No coverage fragments collected" >&2
  exit 1
fi

dart run tool/merge_lcov.dart "${PARTS[@]}" "$ROOT/coverage/lcov.info"
dart run tool/check_coverage.dart --print-summary
