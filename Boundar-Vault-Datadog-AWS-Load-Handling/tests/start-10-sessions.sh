#!/usr/bin/env bash
set -euo pipefail

: "${BOUNDARY_TOKEN:?Set BOUNDARY_TOKEN first}"

TARGET_ID="tssh_TKkCKYZerT"

for i in $(seq 1 10); do
  boundary connect ssh \
    -target-id="$TARGET_ID" \
    -token env://BOUNDARY_TOKEN \
    -- -N >"/tmp/boundary-session-$i.log" 2>&1 &
  sleep 0.5
done

echo "Started 10 test sessions."
