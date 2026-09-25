#!/bin/bash
set -e

echo "=========================================================="
echo "      VPS Management - iOS Build & Packaging Tool"
echo "=========================================================="

# Check for xcodebuild
if ! command -v xcodebuild &> /dev/null || ! xcodebuild -version &> /dev/null; then
    echo ""
    echo "[!] Xcode is not currently active on this system."
    echo "    To activate full Xcode after downloading from the App Store:"
    echo "      sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    echo "      sudo xcodebuild -runFirstLaunch"
    echo ""
    exit 1
fi

echo "--> [1/4] Resolving Flutter dependencies..."
flutter pub get

echo "--> [2/4] Building iOS Release binaries (--no-codesign)..."
flutter build ios --release --no-codesign

echo "--> [3/4] Packaging into iOS IPA (Payload)..."
OUTPUT_DIR="build/ios/ipa"
PAYLOAD_DIR="build/ios/iphoneos/Payload"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
rm -rf "$PAYLOAD_DIR"
mkdir -p "$PAYLOAD_DIR"

cp -R "build/ios/iphoneos/Runner.app" "$PAYLOAD_DIR/"

cd build/ios/iphoneos
zip -qry "../../ios/ipa/VPS_Management.ipa" "Payload"
cd - > /dev/null

echo "--> [4/4] Build complete!"
echo "    IPA Package location: build/ios/ipa/VPS_Management.ipa"
echo "    App Bundle location:  build/ios/iphoneos/Runner.app"
echo "=========================================================="
