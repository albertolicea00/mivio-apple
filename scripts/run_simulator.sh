#!/bin/bash
set -e

# Configuration
SCHEME="Mivio-iOS"
DEVICE_NAME="iPhone 16 Pro"
BUNDLE_ID="com.albertolicea.Mivio"

echo "=== 1. Starting iPhone Simulator ==="
# Find device UUID
DEVICE_UUID=$(xcrun simctl list devices | grep -E "$DEVICE_NAME" | head -n 1 | sed -E 's/.*\(([-0-9A-Fa-f]+)\).*/\1/')

if [ -z "$DEVICE_UUID" ]; then
    echo "Error: Device '$DEVICE_NAME' not found."
    exit 1
fi

echo "Found device: $DEVICE_NAME ($DEVICE_UUID)"

# Boot simulator if not booted
echo "Booting simulator..."
xcrun simctl boot "$DEVICE_UUID" || true
open -a Simulator

echo "=== 2. Building Application ==="
# Build the application using xcodebuild
xcodebuild -project Mivio.xcodeproj -scheme "$SCHEME" -destination "platform=iOS Simulator,id=$DEVICE_UUID" -configuration Debug -quiet build

echo "=== 3. Installing Application in Simulator ==="
# Locate build directory
# We can find the built .app path by asking xcodebuild for the settings
APP_PATH=$(xcodebuild -project Mivio.xcodeproj -scheme "$SCHEME" -destination "platform=iOS Simulator,id=$DEVICE_UUID" -configuration Debug -showBuildSettings | grep -m 1 "CODESIGNING_FOLDER_PATH" | awk '{print $3}')

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    # Fallback to standard derived data search
    echo "Warning: Could not find build folder via showBuildSettings, searching default DerivedData..."
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Mivio.app" -type d -path "*/Debug-iphonesimulator/*" | head -n 1)
fi

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not locate built .app file."
    exit 1
fi

echo "Found built app: $APP_PATH"
echo "Installing to Simulator..."
xcrun simctl install "$DEVICE_UUID" "$APP_PATH"

echo "=== 4. Launching Application ==="
echo "Launching $BUNDLE_ID..."
xcrun simctl launch "$DEVICE_UUID" "$BUNDLE_ID"

echo "Success! The Mivio App is now running on the simulator!"
