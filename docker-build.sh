#!/usr/bin/env bash
set -euo pipefail

# Helper script to build Tejas Linux using Docker
# Usage: ./docker-build.sh [user|developer]

PROFILE=${1:-user}

if [[ ! "$PROFILE" =~ ^(user|developer)$ ]]; then
  echo "Error: Profile must be 'user' or 'developer'" >&2
  echo "Usage: $0 [user|developer]" >&2
  exit 1
fi

# Always rebuild the Docker image to ensure latest code is included
# Docker's layer caching makes this fast if nothing changed
echo "[INFO] Building Docker image (with project code)..."
docker build -t tejas-builder .

echo "[INFO] Building Tejas Linux ($PROFILE edition)..."

# Ensure output directory exists
mkdir -p iso/out

# Run the build (only mount iso/out to save the final ISO)
docker run --rm --privileged \
  -v "$(pwd)/iso/out:/workspace/iso/out" \
  -w /workspace \
  -e PROFILE="$PROFILE" \
  tejas-builder \
  sudo /workspace/iso/build.sh

echo "[DONE] Build complete! Check iso/out/ for the ISO file."
