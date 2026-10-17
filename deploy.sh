#!/usr/bin/env bash
set -euo pipefail

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME}"
: "${IMAGE_REPO:?Set IMAGE_REPO to dev or prod}"
: "${IMAGE_TAG:?Set IMAGE_TAG to the commit tag}"

if [[ "$IMAGE_REPO" != "dev" && "$IMAGE_REPO" != "prod" ]]; then
  echo "ERROR: IMAGE_REPO must be dev or prod"
  exit 1
fi

IMAGE="${DOCKERHUB_USERNAME}/${IMAGE_REPO}:${IMAGE_TAG}"

echo "Pulling ${IMAGE}"
sudo docker pull "${IMAGE}"

cd "$(dirname "$0")"

echo "Starting application with Docker Compose"
APP_IMAGE="${IMAGE}" sudo -E docker compose up -d --remove-orphans

echo "Waiting for application health check"
for attempt in $(seq 1 12); do
  if curl --fail --silent http://localhost/health; then
    echo "Application is healthy"
    exit 0
  fi
  sleep 5
done

echo "ERROR: Application did not become healthy"
sudo docker compose logs --tail=100
exit 1
