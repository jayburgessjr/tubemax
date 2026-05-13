#!/bin/bash
# Run from repo root: bash roku/build.sh
# Creates TubeMax-Roku.zip ready to sideload

cd "$(dirname "$0")"
zip -r ../TubeMax-Roku.zip . \
  --exclude "*.DS_Store" \
  --exclude "build.sh" \
  --exclude "*.md"

echo "✅ TubeMax-Roku.zip created — ready to sideload"
echo "   Upload at http://<your-roku-ip> in developer mode"
