#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y jq unzip gettext-base

BOUNDARY_URL=$(curl -fsSL "https://api.releases.hashicorp.com/v1/releases/boundary/latest?license_class=enterprise" \
  | jq -r '.builds[] | select(.arch == "amd64" and .os == "linux") | .url')

curl -fsSL -o /tmp/boundary.zip "$BOUNDARY_URL"
unzip -o /tmp/boundary.zip -d /tmp/boundary
sudo mv /tmp/boundary/boundary /usr/local/bin/boundary

sudo adduser --system --group boundary || true
sudo chown boundary:boundary /usr/local/bin/boundary

sudo mkdir -p /etc/boundary.d/worker
sudo chown -R boundary:boundary /etc/boundary.d

sudo mv /tmp/pki-worker.hcl.tmpl /etc/boundary.d/pki-worker.hcl.tmpl
sudo chown boundary:boundary /etc/boundary.d/pki-worker.hcl.tmpl

sudo mv /tmp/render-boundary-config.sh /usr/local/bin/render-boundary-config.sh
sudo chmod +x /usr/local/bin/render-boundary-config.sh

sudo mv /tmp/boundary-worker.service /etc/systemd/system/boundary-worker.service

sudo systemctl daemon-reload
sudo systemctl enable boundary-worker.service
