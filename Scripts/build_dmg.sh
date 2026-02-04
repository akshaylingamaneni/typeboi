#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="TypeBoi"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/${APP_NAME}.app"
VERSION_FILE="$ROOT_DIR/VERSION"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found at $APP_PATH"
  echo "Run Scripts/build_app_bundle.sh first."
  exit 1
fi

if [[ -f "$VERSION_FILE" ]]; then
  APP_VERSION="$(cat "$VERSION_FILE")"
else
  APP_VERSION="0.1.0"
fi

DMG_NAME="${APP_NAME}-${APP_VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

rm -f "$DMG_PATH"

# Use create-dmg with large window and icons
# Note: macOS Sequoia ignores some AppleScript settings (known bug)
create-dmg \
  --volname "$APP_NAME Installer" \
  --window-pos 200 120 \
  --window-size 660 420 \
  --icon-size 128 \
  --icon "$APP_NAME.app" 115 195 \
  --app-drop-link 270 195 \
  --hide-extension "$APP_NAME.app" \
  --no-internet-enable \
  "$DMG_PATH" \
  "$APP_PATH"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --sign "$CODESIGN_IDENTITY" "$DMG_PATH"
fi

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$DMG_PATH"
fi

echo "Built DMG at: $DMG_PATH"
