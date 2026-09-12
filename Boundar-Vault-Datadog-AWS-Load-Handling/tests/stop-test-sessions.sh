#!/usr/bin/env bash
set -euo pipefail

pkill -f 'boundary connect ssh' || true

echo "Stopped Boundary test session processes."
