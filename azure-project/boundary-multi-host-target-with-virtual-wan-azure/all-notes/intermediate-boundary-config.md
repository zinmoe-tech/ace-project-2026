### intermediate-worker-01 (Southeast Asia)


disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr        = "10.1.100.5" # worker's private ip
  auth_storage_path  = "/etc/boundary.d/worker"
  initial_upstreams  = [
    "10.1.100.4:9202", # self-managed-worker-01 (Southeast Asia, same region)
    "10.2.100.4:9202", # self-managed-worker-02 (Korea Central)
    "10.3.100.4:9202", # self-managed-worker-03 (Japan East)
  ]

  tags {
    type = ["worker1", "private", "egress"]
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

-----

### intermediate-worker-02 (Korea Central)


disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr        = "10.2.100.5" # worker's private ip
  auth_storage_path  = "/etc/boundary.d/worker"
  initial_upstreams  = [
    "10.1.100.4:9202", # self-managed-worker-01 (Southeast Asia)
    "10.2.100.4:9202", # self-managed-worker-02 (Korea Central, same region)
    "10.3.100.4:9202", # self-managed-worker-03 (Japan East)
  ]

  tags {
    type = ["worker2", "private", "egress"]
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

-----

### intermediate-worker-03 (Japan East)


disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr        = "10.3.100.5" # worker's private ip
  auth_storage_path  = "/etc/boundary.d/worker"
  initial_upstreams  = [
    "10.1.100.4:9202", # self-managed-worker-01 (Southeast Asia)
    "10.2.100.4:9202", # self-managed-worker-02 (Korea Central)
    "10.3.100.4:9202", # self-managed-worker-03 (Japan East, same region)
  ]

  tags {
    type = ["worker3", "private", "egress", "zone-c", "downstream"]
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

-----

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