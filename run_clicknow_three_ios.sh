#!/bin/bash

set -euo pipefail

PROJECT_PATH="/Users/kishoresahu/Documents/clicknow_version2"
FLUTTER_BIN="/Users/kishoresahu/Development/flutter/bin/flutter"

CUSTOMER_ID="0B6775E4-2996-4C43-A212-B5E279AB1406"
PROFESSIONAL_ID="2EB8BC4B-5B2B-432B-ADDC-70B120988E6B"
ADMIN_ID="6593948A-B5D7-4666-9325-0584656BED6C"

BUNDLE_ID="com.clicknow.application"
DERIVED_DATA="/tmp/clicknow_three_simulators_derived_data"
BUILD_LOG="/tmp/clicknow_three_simulators_build.log"

DEVICE_IDS=(
  "$CUSTOMER_ID"
  "$PROFESSIONAL_ID"
  "$ADMIN_ID"
)

ROLE_NAMES=(
  "CUSTOMER"
  "PROFESSIONAL"
  "ADMIN"
)

cd "$PROJECT_PATH"

echo
echo "=========================================="
echo "1. Checking required tools"
echo "=========================================="

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter SDK not found at:"
  echo "$FLUTTER_BIN"
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods command was not found."
  echo "Install or repair CocoaPods before continuing."
  exit 1
fi

if [[ ! -d "ios/Runner.xcworkspace" ]]; then
  echo "ios/Runner.xcworkspace was not found."
  echo "Run pod install first."
  exit 1
fi

echo "Flutter:"
"$FLUTTER_BIN" --version | head -3

echo
echo "=========================================="
echo "2. Booting three iOS simulators"
echo "=========================================="

for index in 0 1 2; do
  DEVICE_ID="${DEVICE_IDS[$index]}"
  ROLE_NAME="${ROLE_NAMES[$index]}"

  if ! xcrun simctl list devices available | grep -q "$DEVICE_ID"; then
    echo "$ROLE_NAME simulator was not found:"
    echo "$DEVICE_ID"
    exit 1
  fi

  echo "Booting $ROLE_NAME simulator..."
  xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
done

echo
echo "Waiting for all simulators to finish booting..."

for index in 0 1 2; do
  DEVICE_ID="${DEVICE_IDS[$index]}"
  ROLE_NAME="${ROLE_NAMES[$index]}"

  echo "Waiting for $ROLE_NAME..."
  xcrun simctl bootstatus "$DEVICE_ID" -b
done

open -a Simulator

echo
echo "Currently booted simulators:"
xcrun simctl list devices | grep Booted || true

echo
echo "=========================================="
echo "3. Preparing Flutter and CocoaPods"
echo "=========================================="

"$FLUTTER_BIN" pub get

(
  cd ios
  pod install
)

if [[ ! -f "ios/Pods/Manifest.lock" ]]; then
  echo "ios/Pods/Manifest.lock is missing after pod install."
  exit 1
fi

if ! diff -q ios/Podfile.lock ios/Pods/Manifest.lock >/dev/null; then
  echo "Podfile.lock and Pods/Manifest.lock are not synchronized."
  exit 1
fi

echo "CocoaPods is synchronized."

echo
echo "=========================================="
echo "4. Building ClickNow with Xcode"
echo "=========================================="

set -o pipefail

xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED_DATA" \
  build 2>&1 | tee "$BUILD_LOG"

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Runner.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo
  echo "Runner.app was not generated."
  echo "Expected path:"
  echo "$APP_PATH"
  echo
  echo "Build log:"
  echo "$BUILD_LOG"
  exit 1
fi

echo
echo "Build succeeded."
echo "App path:"
echo "$APP_PATH"

echo
echo "=========================================="
echo "5. Installing and launching ClickNow"
echo "=========================================="

for index in 0 1 2; do
  DEVICE_ID="${DEVICE_IDS[$index]}"
  ROLE_NAME="${ROLE_NAMES[$index]}"

  echo
  echo "Installing app for $ROLE_NAME..."

  xcrun simctl terminate \
    "$DEVICE_ID" \
    "$BUNDLE_ID" \
    2>/dev/null || true

  xcrun simctl install \
    "$DEVICE_ID" \
    "$APP_PATH"

  echo "Launching app for $ROLE_NAME..."

  xcrun simctl launch \
    "$DEVICE_ID" \
    "$BUNDLE_ID"
done

echo
echo "=========================================="
echo "6. Opening three Flutter attach terminals"
echo "=========================================="

sleep 4

osascript <<APPLESCRIPT
tell application "Terminal"
  activate

  do script "cd \"$PROJECT_PATH\" && clear && echo 'CLICKNOW CUSTOMER - Flutter Attach' && \"$FLUTTER_BIN\" attach -d \"$CUSTOMER_ID\""

  do script "cd \"$PROJECT_PATH\" && clear && echo 'CLICKNOW PROFESSIONAL - Flutter Attach' && \"$FLUTTER_BIN\" attach -d \"$PROFESSIONAL_ID\""

  do script "cd \"$PROJECT_PATH\" && clear && echo 'CLICKNOW ADMIN - Flutter Attach' && \"$FLUTTER_BIN\" attach -d \"$ADMIN_ID\""
end tell
APPLESCRIPT

echo
echo "=========================================="
echo "ClickNow is running on all three simulators"
echo "=========================================="
echo
echo "Customer:"
echo "$CUSTOMER_ID"
echo
echo "Professional:"
echo "$PROFESSIONAL_ID"
echo
echo "Admin:"
echo "$ADMIN_ID"
echo
echo "Hot reload: press lowercase r in each attach Terminal"
echo "Hot restart: press uppercase R in each attach Terminal"
echo
echo "Build log:"
echo "$BUILD_LOG"
