#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f Dockerfile || ! -f build/index.html ]]; then
  echo "ERROR: Dockerfile or build/index.html is missing"
  exit 1
fi

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME first}"
: "${IMAGE_REPO:?Set IMAGE_REPO to dev or prod}"

if [[ "$IMAGE_REPO" != "dev" && "$IMAGE_REPO" != "prod" ]]; then
  echo "ERROR: IMAGE_REPO must be dev or prod"
  exit 1
fi

GIT_TAG="$(git rev-parse --short HEAD)"
IMAGE="${DOCKERHUB_USERNAME}/${IMAGE_REPO}"

sudo docker build \
  --pull \
  -t "${IMAGE}:${GIT_TAG}" \
  -t "${IMAGE}:latest" \
  .

echo "Built images:"
sudo docker image ls "${IMAGE}"
EOF
