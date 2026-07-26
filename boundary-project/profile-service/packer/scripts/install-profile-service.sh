#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y unzip

FAKE_SERVICE_VERSION="v0.26.2"
curl -fsSL -o /tmp/fake-service.zip \
  "https://github.com/nicholasjackson/fake-service/releases/download/${FAKE_SERVICE_VERSION}/fake_service_linux_amd64.zip"

unzip -o /tmp/fake-service.zip -d /tmp/fake-service
sudo mv /tmp/fake-service/fake-service /usr/local/bin/profile-service
sudo chmod +x /usr/local/bin/profile-service
rm -rf /tmp/fake-service /tmp/fake-service.zip

sudo mv /tmp/profile.service /etc/systemd/system/profile.service

sudo systemctl daemon-reload
sudo systemctl enable profile.service
