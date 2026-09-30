#!/bin/bash
# Builds the Desktop Shell's four background services into build/:
#   build/XP Taskbar.app       Windows XP taskbar + Start menu, Downloads, window tiler
#   build/Desktop Folders.app  iOS-style desktop folders
#   build/Desktop Widgets.app  floating widget panel
#   build/Desktop Hotkeys.app  ⌘⌃T → Ghostty, tap ⌥ Option → Start
# Run ./install.sh to install them (it calls this first).
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN=.build/release

# Sign with a stable local identity (tools/make_signing_identity.sh) so macOS keeps the
# permissions you granted across rebuilds; fall back to ad-hoc signing if it's missing.
IDENTITY="Hanabi Local Code Signing"
security find-certificate -c "$IDENTITY" >/dev/null 2>&1 || IDENTITY="-"

# make_app <bundle path> <executable> <display name> <bundle id>
make_app() {
    local app="$1" exe="$2" name="$3" id="$4"
    rm -rf "$app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$BIN/$exe" "$app/Contents/MacOS/$exe"
    cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleName</key><string>$name</string>
    <key>CFBundleDisplayName</key><string>$name</string>
    <key>CFBundleIdentifier</key><string>$id</string>
    <key>CFBundleExecutable</key><string>$exe</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.4</string>
    <key>LSUIElement</key><true/>
    <key>NSAppleEventsUsageDescription</key><string>$name opens Ghostty windows for you (⌘⌃T) and shows / controls what Music is playing.</string>
</dict></plist>
PLIST
    codesign --force --sign "$IDENTITY" "$app" 2>/dev/null
}

mkdir -p build
make_app "build/XP Taskbar.app"      XPTaskbar      "XP Taskbar"      local.dhairyabhatia.desktop.taskbar
make_app "build/Desktop Folders.app" DesktopFolders "Desktop Folders" local.dhairyabhatia.desktop.folders
make_app "build/Desktop Widgets.app" DesktopWidgets "Desktop Widgets" local.dhairyabhatia.desktop.widgets
make_app "build/Desktop Hotkeys.app" DesktopHotkeys "Desktop Hotkeys" local.dhairyabhatia.desktop.hotkeys
echo "Built build/ (4 services). Install with ./install.sh"
