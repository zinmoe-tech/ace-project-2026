#!/bin/bash
set -euo pipefail

exec > >(tee -a /var/log/boundary-user-data.log) 2>&1

# ============================================================
# Boundary / Vault / AWS settings
# ============================================================

BOUNDARY_VERSION="1.0.1+ent-1"

export BOUNDARY_ADDR="https://458bfef0-c859-478d-957e-ebbc993caa7f.boundary.hashicorp.cloud"
BOUNDARY_CLUSTER_ID="458bfef0-c859-478d-957e-ebbc993caa7f"
BOUNDARY_AUTH_METHOD_ID="ampw_fAa3Lwqkqy"

export VAULT_ADDR="https://vault-cluster-aws-private-vault-3c87b32f.7274f87b.z1.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"
VAULT_AWS_ROLE="boundary-asg-worker"
VAULT_KV_PATH="boundary-registration/asg-worker"

# ============================================================
# Install required packages
# ============================================================

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y curl gpg ca-certificates awscli jq

curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

. /etc/os-release

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" \
  > /etc/apt/sources.list.d/hashicorp.list

apt-get update
apt-get install -y "boundary-enterprise=${BOUNDARY_VERSION}" vault

# ============================================================
# Read EC2 metadata using IMDSv2
# ============================================================

IMDS_TOKEN="$(curl -fsS -X PUT \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
  http://169.254.169.254/latest/api/token)"

INSTANCE_ID="$(curl -fsS \
  -H "X-aws-ec2-metadata-token: ${IMDS_TOKEN}" \
  http://169.254.169.254/latest/meta-data/instance-id)"

PRIVATE_IP="$(curl -fsS \
  -H "X-aws-ec2-metadata-token: ${IMDS_TOKEN}" \
  http://169.254.169.254/latest/meta-data/local-ipv4)"

WORKER_NAME="aws-asg-${INSTANCE_ID}"

# ============================================================
# Verify EC2 IAM identity
# ============================================================

aws sts get-caller-identity >/dev/null

# ============================================================
# Create Boundary directories
# ============================================================

install -d -o boundary -g boundary -m 700 /var/lib/boundary
install -d -o boundary -g boundary -m 750 /var/log/boundary
install -d -o root -g boundary -m 750 /etc/boundary.d

# ============================================================
# Boundary worker configuration
# ============================================================

cat > /etc/boundary.d/worker.hcl <<EOF
disable_mlock = true

hcp_boundary_cluster_id = "${BOUNDARY_CLUSTER_ID}"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

listener "tcp" {
  address     = "127.0.0.1:9203"
  purpose     = "ops"
  tls_disable = true
}

worker {
  auth_storage_path = "/var/lib/boundary"
  public_addr       = "${PRIVATE_IP}:9202"

  tags {
    type       = ["egress"]
    cloud      = ["aws"]
    pool       = ["aws-autoscaling"]
    target     = ["on-aws"]
    cred-store = ["vault"]
  }
}

events {
  observations_enabled = true
  sysevents_enabled     = true

  sink "stderr" {
    name        = "journald"
    event_types = ["*"]
    format      = "cloudevents-json"
  }
}
EOF

chown root:boundary /etc/boundary.d/worker.hcl
chmod 640 /etc/boundary.d/worker.hcl

# ============================================================
# systemd service
# ============================================================

cat > /etc/systemd/system/boundary-worker.service <<'EOF'
[Unit]
Description=HashiCorp Boundary ASG Worker
After=network-online.target
Wants=network-online.target

[Service]
User=boundary
Group=boundary
ExecStart=/usr/bin/boundary server -config=/etc/boundary.d/worker.hcl
Restart=on-failure
RestartSec=5
KillSignal=SIGTERM
TimeoutStopSec=600
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now boundary-worker.service

# ============================================================
# Wait for worker-led auth request token
# ============================================================

AUTH_REQUEST_FILE="/var/lib/boundary/auth_request_token"

for _ in $(seq 1 60); do
  [ -s "${AUTH_REQUEST_FILE}" ] && break
  sleep 2
done

if [ ! -s "${AUTH_REQUEST_FILE}" ]; then
  echo "ERROR: auth_request_token was not generated."
  journalctl -u boundary-worker.service -n 100 --no-pager
  exit 1
fi

WORKER_AUTH_TOKEN="$(cat "${AUTH_REQUEST_FILE}")"

# ============================================================
# Authenticate EC2 to Vault using AWS Auth
# ============================================================

VAULT_TOKEN="$(
  vault login \
    -method=aws \
    -path=aws \
    -token-only \
    role="${VAULT_AWS_ROLE}"
)"

export VAULT_TOKEN

# ============================================================
# Read dedicated Boundary registration account from Vault KV
# ============================================================

BOUNDARY_LOGIN_NAME="$(vault kv get \
  -field=login_name \
  "${VAULT_KV_PATH}")"

BOUNDARY_PASSWORD="$(vault kv get \
  -field=password \
  "${VAULT_KV_PATH}")"

export BOUNDARY_PASSWORD

# ============================================================
# Authenticate to HCP Boundary
# ============================================================

BOUNDARY_TOKEN="$(
  boundary authenticate password \
    -auth-method-id="${BOUNDARY_AUTH_METHOD_ID}" \
    -login-name="${BOUNDARY_LOGIN_NAME}" \
    -password="env://BOUNDARY_PASSWORD" \
    -keyring-type=none \
    -format=json \
  | jq -r '.item.attributes.token'
)"

if [ -z "${BOUNDARY_TOKEN}" ] || [ "${BOUNDARY_TOKEN}" = "null" ]; then
  echo "ERROR: Boundary authentication failed."
  exit 1
fi

export BOUNDARY_TOKEN

# ============================================================
# Register this worker
# ============================================================

boundary workers create worker-led \
  -worker-generated-auth-token="${WORKER_AUTH_TOKEN}" \
  -name="${WORKER_NAME}" \
  -token="env://BOUNDARY_TOKEN"

# ============================================================
# Cleanup bootstrap secrets from environment
# ============================================================

unset VAULT_TOKEN
unset BOUNDARY_PASSWORD
unset BOUNDARY_TOKEN
unset WORKER_AUTH_TOKEN

echo "Boundary worker ${WORKER_NAME} registered successfully."
