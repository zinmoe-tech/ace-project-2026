#!/usr/bin/env bash
set -euo pipefail

: "${BOUNDARY_TOKEN:?Set BOUNDARY_TOKEN first}"

boundary workers list \
  -scope-id=global \
  -format=json \
  -token env://BOUNDARY_TOKEN \
| jq -r '.items[] | [.id,.name,.create_time,.update_time,.last_status_time] | @tsv'
