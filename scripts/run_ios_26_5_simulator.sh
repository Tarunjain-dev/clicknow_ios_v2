#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="${1:-16304C8A-2A5D-4212-92DE-BE95AACD9A01}"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/kishoresahu/Development/flutter/bin/flutter}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$(mktemp -d /private/tmp/clicknow_ios_simulator_run.XXXXXX)"

echo "Preparing clean iOS simulator workspace at ${RUN_DIR}"
(
  cd "${SOURCE_DIR}"
  COPYFILE_DISABLE=1 tar --no-xattrs \
    --exclude "./.git" \
    --exclude "./.dart_tool" \
    --exclude "./build" \
    --exclude "./functions/node_modules" \
    --exclude "./node_modules" \
    --exclude "./ios/Pods" \
    --exclude "./ios/.symlinks" \
    --exclude "./ios/Flutter/ephemeral" \
    -cf - .
) | (
  cd "${RUN_DIR}"
  COPYFILE_DISABLE=1 tar --no-xattrs -xf -
)

cd "${RUN_DIR}"

echo "Cleaning copied Flutter build artifacts"
"${FLUTTER_BIN}" clean

echo "Resolving Flutter packages"
"${FLUTTER_BIN}" pub get

echo "Installing iOS pods"
(
  cd ios
  pod install
)

echo "Booting iOS simulator ${DEVICE_ID}"
xcrun simctl boot "${DEVICE_ID}" 2>/dev/null || true
xcrun simctl bootstatus "${DEVICE_ID}" -b

echo "Running ClickNow on iOS simulator ${DEVICE_ID}"
"${FLUTTER_BIN}" run -d "${DEVICE_ID}"
