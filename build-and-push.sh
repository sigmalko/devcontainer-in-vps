#!/usr/bin/env bash
# Manual build and push to GitHub Container Registry (the CI workflow does this automatically).
#
# Usage:   ./build-and-push.sh <TAG> [OWNER [IMAGE_NAME]]
# Example: ./build-and-push.sh 01.001
#          -> builds and pushes ghcr.io/sigmalko/devcontainer-in-vps:01.001
#
# Prerequisite: echo "$GITHUB_TOKEN" | docker login ghcr.io -u <user> --password-stdin
#               (token needs the write:packages scope)
set -euo pipefail

TAG="${1:?Usage: $0 <TAG> [OWNER [IMAGE_NAME]]}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OWNER="${2:-sigmalko}"
IMAGE="ghcr.io/${OWNER}/${3:-devcontainer-in-vps}:${TAG}"

echo "=== Building ${IMAGE} ==="
docker build -t "${IMAGE}" "${SCRIPT_DIR}"

echo "=== Pushing ${IMAGE} ==="
docker push "${IMAGE}"

echo "Image published: ${IMAGE}"
