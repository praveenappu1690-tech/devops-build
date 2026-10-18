#!/usr/bin/env bash
set -euo pipefail

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME}"
: "${IMAGE_REPO:?Set IMAGE_REPO to dev or prod}"
: "${IMAGE_TAG:?Set IMAGE_TAG to the commit tag}"

if [[ "$IMAGE_REPO" != "dev" && "$IMAGE_REPO" != "prod" ]]; then
  echo "ERROR: IMAGE_REPO must be dev or prod"
  exit 1
fi

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml"
IMAGE="${DOCKERHUB_USERNAME}/${IMAGE_REPO}:${IMAGE_TAG}"

cd "${PROJECT_DIR}"

echo "Using Compose file: ${COMPOSE_FILE}"
echo "Pulling ${IMAGE}"
sudo docker pull "${IMAGE}"

echo "Starting application with Docker Compose"
sudo env APP_IMAGE="${IMAGE}" docker compose \
  -f "${COMPOSE_FILE}" up -d --remove-orphans

echo "Waiting for application health check"
for attempt in $(seq 1 12); do
  if curl --fail --silent http://localhost/health; then
    echo
    echo "Application is healthy"
    exit 0
  fi
  sleep 5
done

echo "ERROR: Application did not become healthy"
sudo docker compose -f "${COMPOSE_FILE}" logs --tail=100
exit 1
