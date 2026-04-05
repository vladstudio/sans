#!/bin/bash
set -e
cd "$(dirname "$0")"
source ../mac-scripts/build-kit.sh
build_app "Sans" --resources "AppIcon.icns"
