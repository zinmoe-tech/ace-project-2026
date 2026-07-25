#!/usr/bin/env bash
set -euo pipefail

CONFIG=/etc/boundary.d/pki-worker.hcl
TEMPLATE=/etc/boundary.d/pki-worker.hcl.tmpl

# Idempotent: if a real instance already rendered its config, don't clobber it
# (auth_storage_path holds this worker's registered identity).
if [ -f "$CONFIG" ]; then
  exit 0
fi

IMDS_TOKEN=$(curl -fsSL -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
PRIVATE_ADDR=$(curl -fsSL -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

PRIVATE_ADDR="$PRIVATE_ADDR" envsubst < "$TEMPLATE" > "$CONFIG"
chown boundary:boundary "$CONFIG"
