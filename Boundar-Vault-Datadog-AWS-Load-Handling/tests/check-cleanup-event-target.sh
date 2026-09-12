#!/usr/bin/env bash
set -euo pipefail

aws events list-targets-by-rule \
  --rule boundary-worker-termination-cleanup \
  --region us-east-1

cat <<'MSG'
Correct result: BoundaryWorkerCleanup Lambda target with NO RoleArn.
MSG
