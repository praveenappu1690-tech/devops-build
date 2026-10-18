#!/usr/bin/env bash
set -euo pipefail

echo "Checking React build output..."

if [[ ! -f build/index.html ]]; then
    echo "ERROR: build/index.html is missing."
    echo "The React application must be built before Docker image creation."
    exit 1
fi

echo "React build output exists."
echo "Docker image will be built by the Jenkinsfile."
