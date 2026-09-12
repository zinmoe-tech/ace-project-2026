#!/usr/bin/env bash
set -euo pipefail

: "${BOUNDARY_TOKEN:?Set BOUNDARY_TOKEN first}"

boundary sessions list \
  -scope-id=global \
  -recursive \
  -format=json \
  -token env://BOUNDARY_TOKEN \
| jq '[.items // [] | .[] | select(.status == "active")] | length'
