#!/usr/bin/env bash
# Regenerate auth screen goldens on Linux amd64 (matches GitHub Actions ubuntu-latest).
# Auth goldens must not be updated on macOS — subpixel/font differences fail CI.
set -euo pipefail

MOBILE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$MOBILE/../.." && pwd)"
IMAGE="${FLUTTER_GOLDEN_IMAGE:-ghcr.io/cirruslabs/flutter:3.44.0}"

echo "Using Flutter image: $IMAGE (linux/amd64 — matches GitHub Actions runners)"
docker run --rm --platform linux/amd64 \
  -v "$ROOT:/work" \
  -w /work/apps/mobile \
  "$IMAGE" \
  bash -lc '
    set -euo pipefail
    git config --global --add safe.directory /opt/flutter 2>/dev/null || true
    git config --global --add safe.directory /sdks/flutter 2>/dev/null || true
    flutter --version
    flutter pub get
    flutter test test/features/auth/golden/auth_screens_golden_test.dart --update-goldens
    flutter test test/features/auth/golden/auth_screens_golden_test.dart
  '

echo "Auth goldens updated and verified."
