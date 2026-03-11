#!/bin/bash
set -e

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

URL=$(curl -sL https://api.github.com/repos/vladstudio/sans/releases/latest \
  | grep browser_download_url | head -1 | cut -d'"' -f4)
curl -sL "$URL" -o "$TMP/Sans.zip"
unzip -q "$TMP/Sans.zip" -d "$TMP"

pkill -x Sans 2>/dev/null || true
rm -rf /Applications/Sans.app
mv "$TMP/Sans.app" /Applications/
xattr -dr com.apple.quarantine /Applications/Sans.app 2>/dev/null || true
open /Applications/Sans.app
echo "==> Installed Sans"
