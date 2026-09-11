# download `boundary` binary
sudo apt-get update && sudo apt-get install jq net-tools unzip -y ;\
wget -q "$(curl -fsSL "https://api.releases.hashicorp.com/v1/releases/boundary/latest?license_class=enterprise" | jq -r '.builds[] | select(.arch == "amd64" and .os == "linux") | .url')" ;\
unzip *.zip

### self-managed worker systemd setup ###

# adduser
sudo adduser --system --group boundary || true

# `boundary-enterprise binary`
sudo mv boundary /usr/local/bin/
cd /usr/local/bin
sudo chown boundary:boundary boundary

cd /etc/
sudo mkdir boundary.d
sudo chown boundary:boundary boundary.d
cd boundary.d

sudo touch pki-worker.hcl
sudo mkdir worker
sudo chown boundary:boundary *


sudo vi /etc/boundary.d/pki-worker.hcl

########################

disable_mlock = true
hcp_boundary_cluster_id = "95390bdc-e040-47df-8638-7c996c0f98f7"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}
        
worker {
  public_addr = "20.64.176.75" # worker's private ip
  auth_storage_path = "/etc/boundary.d/worker"
  tags {
    type = ["worker1", "private", "ingress", "zone-a", "downstream"]
  }
}

events {
  audit_enabled        = true
  observations_enabled = true
  sysevents_enabled    = true
  telemetry_enabled    = false

  sink "stderr" {
    name        = "all-events"
    event_types = ["*"]
    format      = "cloudevents-json"
  }
}

########################

# boundary-worker.service
########################
sudo vi /etc/systemd/system/boundary-worker.service

[Unit]
Description=boundary worker

[Service]
ExecStart=/usr/local/bin/boundary server -config /etc/boundary.d/pki-worker.hcl
User=boundary
Group=boundary
LimitMEMLOCK=infinity
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK

[Install]
WantedBy=multi-user.target

########################

sudo systemctl daemon-reload
sudo systemctl enable boundary-worker.service
sudo systemctl start boundary-worker.service
sudo systemctl status boundary-worker.service

# copy auth_request_token
sudo cat worker/auth_request_token

# go to HCPb UI and Register Worker
* Worker public address - 10.0.111.49
* Config file path - /etc/boundary.d/pki-worker.hcl
* Worker TagsB
  * key - type
  * value - worker1, private, ingress, zone-a, downstream
* Worker Auth Registration Request 

# verify and troubleshooting
journalctl -flu boundary-worker.service

