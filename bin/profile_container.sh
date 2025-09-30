#!/usr/bin/env bash
set -euo pipefail

# Usage: ./profile_worker.sh <container_name> [duration_seconds]
CONTAINER_NAME="${1:-temporal-worker}"
DURATION="${2:-120}"

# File name based on container name + timestamp
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_FILE="${CONTAINER_NAME}-${TIMESTAMP}.svg"

echo "📦 Profiling container: $CONTAINER_NAME for $DURATION seconds..."
echo "⏳ Output will be saved as $OUTPUT_FILE"

docker exec -u 0 "$CONTAINER_NAME" sh -lc "
  set -e
  python -m pip install -q --upgrade pip
  python -m pip install -q py-spy procps || true
  ps -ef | grep -i '[p]ython' || true
  py-spy record -o /tmp/worker.svg --pid 1 --duration $DURATION
"

docker cp "$CONTAINER_NAME":/tmp/worker.svg "./$OUTPUT_FILE"

echo "🔥 Profiling complete. Open $OUTPUT_FILE in your browser to inspect the flame graph."
