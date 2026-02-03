# TypeBoi

A local-only macOS menu bar app for keyboard activity stats.

## Features
- Total keystrokes, printable keystrokes, backspace/delete, and shortcut counts
- Active WPM based on typing bursts (excludes idle/thinking time)
- Hourly activity bars for today
- Per-app daily totals (bundle ID + name only)
- JSON export for year-end "wrapped"
- Exclude apps from tracking

## Privacy
All data is stored locally under:
`~/Library/Application Support/TypeBoi/`

No text or words are stored. Only aggregated counts.

## Build
For local dev you can run the SwiftPM executable, but macOS Accessibility
requires a real `.app` bundle for permissions.

Build an app bundle:
```bash
chmod +x Scripts/build_app_bundle.sh
Scripts/build_app_bundle.sh
```

The bundle is created at `dist/TypeBoi.app`.

### Direct Download Release
Set the version in `VERSION`, then build and package:
```bash
Scripts/build_app_bundle.sh
Scripts/build_dmg.sh
```

The DMG is created at `dist/TypeBoi-<version>.dmg`.

To sign the app/DMG:
```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" Scripts/build_app_bundle.sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" Scripts/build_dmg.sh
```

To notarize the DMG (optional but recommended):
```bash
APPLE_ID="you@example.com" \
APPLE_TEAM_ID="TEAMID" \
APPLE_APP_SPECIFIC_PASSWORD="app-specific-password" \
Scripts/build_dmg.sh
```

## Permissions
The app needs Accessibility permissions to read key events. macOS will prompt on first run.
