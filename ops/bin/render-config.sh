#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
ENV_FILE="${1:-$ROOT/.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Env file not found: $ENV_FILE" >&2
  exit 1
fi

set -a
. "$ENV_FILE" || { echo "Failed to source env file" >&2; exit 1; }
set +a

mkdir -p "$ROOT/ops/generated" || { echo "Failed to create output directory" >&2; exit 1; }

ICECAST_VARS='$ICECAST_ADMIN_USERNAME $ICECAST_ADMIN_PASSWORD $ICECAST_SOURCE_PASSWORD $ICECAST_RELAY_PASSWORD $ICECAST_HOST $ICECAST_PORT $ICECAST_MOUNT $STREAM_BITRATE_KBPS $STATION_NAME $STATION_DESCRIPTION $MUSIC_DIR'
LIQUIDSOAP_VARS='$ICECAST_SOURCE_PASSWORD $ICECAST_HOST $ICECAST_PORT $ICECAST_MOUNT $STREAM_BITRATE_KBPS $STATION_NAME $STATION_DESCRIPTION $MUSIC_DIR'

envsubst "$ICECAST_VARS" < "$ROOT/config/icecast.xml.template" > "$ROOT/ops/generated/icecast.xml" || { echo "Failed to render icecast.xml" >&2; exit 1; }
envsubst "$LIQUIDSOAP_VARS" < "$ROOT/config/radio.liq.template" > "$ROOT/ops/generated/radio.liq" || { echo "Failed to render radio.liq" >&2; exit 1; }

echo "Rendered: ops/generated/icecast.xml"
echo "Rendered: ops/generated/radio.liq"
