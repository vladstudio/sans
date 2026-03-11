#!/bin/bash
set -e
cd "$(dirname "$0")"

swift build -c release

APP=/tmp/Sans.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/"
cp .build/release/Sans "$APP/Contents/MacOS/"
cp AppIcon.icns "$APP/Contents/Resources/"

rm -rf /Applications/Sans.app
mv "$APP" /Applications/
touch /Applications/Sans.app
open /Applications/Sans.app
echo "==> Installed Sans.app"
