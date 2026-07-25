#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y jq unzip gettext-base

BOUNDARY_URL=$(curl -fsSL "https://api.releases.hashicorp.com/v1/releases/boundary/latest?license_class=enterprise" \
  | jq -r '.builds[] | select(.arch == "amd64" and .os == "linux") | .url')

# Download/extract outside of /tmp: on Ubuntu cloud images /tmp is often a
# RAM-backed tmpfs (~50% of instance memory), which a t3.micro's 1GB RAM
# makes too small for the ~190MB enterprise zip plus its unpacked contents
# (that's what was producing unzip's exit code 50, "disk full during
# extraction" - bumping the root EBS volume size doesn't touch tmpfs).
# /opt lives on the root filesystem instead.
WORKDIR=/opt/boundary-build
sudo mkdir -p "$WORKDIR"
sudo chown "$(id -u):$(id -g)" "$WORKDIR"

curl -fsSL -o "$WORKDIR/boundary.zip" "$BOUNDARY_URL"
unzip -o "$WORKDIR/boundary.zip" -d "$WORKDIR/boundary"
sudo mv "$WORKDIR/boundary/boundary" /usr/local/bin/boundary
sudo rm -rf "$WORKDIR"

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
