#!/usr/bin/env bash
# Regenerate auth screen goldens on Linux (matches ubuntu-latest CI rendering).
# Auth goldens must not be updated on macOS — subpixel/font differences fail CI.
set -euo pipefail

MOBILE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$MOBILE/../.." && pwd)"
IMAGE="${FLUTTER_GOLDEN_IMAGE:-ghcr.io/cirruslabs/flutter:3.44.0}"

echo "Using Flutter image: $IMAGE"
docker run --rm \
  -v "$ROOT:/work" \
  -w /work/apps/mobile \
  "$IMAGE" \
  bash -lc '
    set -euo pipefail
    flutter --version
    flutter pub get
    flutter test test/features/auth/golden/auth_screens_golden_test.dart --update-goldens
    flutter test test/features/auth/golden/auth_screens_golden_test.dart
  '

echo "Auth goldens updated and verified."
