#!/usr/bin/env bash
# Local release QA gates for chisto_mobile. Run from repo root or apps/mobile.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== workspace pub get =="
flutter pub get

echo "== dart format =="
dart format --set-exit-if-changed lib test tool packages

echo "== flutter analyze (app shell) =="
flutter analyze lib

echo "== guard scripts =="
for f in tool/check_*.dart; do
  echo "  $f"
  dart run "$f"
done

echo "== package tests =="
flutter test packages/chisto_networking/test/
flutter test packages/chisto_localization/test/
flutter test packages/design_system/test/
flutter test packages/feature_safety/test/
flutter test packages/feature_events/test/

echo "== unit tests =="
flutter test test/

echo "== release env guard =="
dart run tool/check_release_env.dart

echo "All release QA gates passed."
