#!/usr/bin/env bash
set -euo pipefail

# Helper script to build Tejas Linux using Docker
# Usage: ./docker-build.sh [user|pro]

PROFILE=${1:-user}

if [[ ! "$PROFILE" =~ ^(user|pro)$ ]]; then
  echo "Error: Profile must be 'user' or 'pro'" >&2
  echo "Usage: $0 [user|pro]" >&2
  exit 1
fi

# Always rebuild the Docker image to ensure latest code is included
# Docker's layer caching makes this fast if nothing changed
echo "[INFO] Building Docker image (with project code)..."
docker build --platform linux/amd64 -t tejas-builder .

echo "[INFO] Building Tejas Linux ($PROFILE edition)..."

# Ensure output directory exists
mkdir -p iso/out

# Run the build (only mount iso/out to save the final ISO)
docker run --rm --privileged \
  --platform linux/amd64 \
  -v "$(pwd)/iso/out:/workspace/iso/out" \
  -w /workspace \
  -e PROFILE="$PROFILE" \
  tejas-builder \
  sudo /workspace/iso/build.sh

echo "[DONE] Build complete! Check iso/out/ for the ISO file."
