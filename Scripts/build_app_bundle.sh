#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="TypeBoi"
CONFIG="${CONFIG:-release}"
BUILD_DIR="$ROOT_DIR/dist"
APP_DIR="$BUILD_DIR/${APP_NAME}.app"
VERSION_FILE="$ROOT_DIR/VERSION"
BUNDLE_ID="${BUNDLE_ID:-com.typeboi.app}"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

swift build -c "$CONFIG" --product "$APP_NAME"

BIN_PATH="$ROOT_DIR/.build/$CONFIG/$APP_NAME"
INFO_PLIST="$ROOT_DIR/Resources/AppBundle/Info.plist"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
cp "$INFO_PLIST" "$CONTENTS_DIR/Info.plist"

if [[ -f "$VERSION_FILE" ]]; then
  APP_VERSION="$(cat "$VERSION_FILE")"
else
  APP_VERSION="0.1.0"
fi

if /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$CONTENTS_DIR/Info.plist" >/dev/null 2>&1; then
  true
else
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$CONTENTS_DIR/Info.plist"
fi

if /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$CONTENTS_DIR/Info.plist" >/dev/null 2>&1; then
  true
else
  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $APP_VERSION" "$CONTENTS_DIR/Info.plist"
fi

if /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_VERSION" "$CONTENTS_DIR/Info.plist" >/dev/null 2>&1; then
  true
else
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $APP_VERSION" "$CONTENTS_DIR/Info.plist"
fi

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp \
    --sign "$CODESIGN_IDENTITY" "$APP_DIR"
fi

echo "Built app bundle at: $APP_DIR"
