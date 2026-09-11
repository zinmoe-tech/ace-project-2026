# Boundary + Vault + Datadog + AWS Load Handling
## Complete Step-by-Step Implementation — Single File

> This document is intentionally written as **one continuous implementation procedure**.
> Follow Step 1, then Step 2, then Step 3, in order.

---

# Final Architecture

```text
HCP Boundary
    ↓
BoundarySessionCounter Lambda
    ↓
Datadog metric: boundary.active_sessions
    ↓
Datadog Scale-Out / Scale-In monitors
    ↓
Datadog Workflows
    ↓
DatadogBoundaryScalingRole
    ↓
AWS Auto Scaling Group
    ↓
Desired Capacity = 1 / 0
```

Scale-in cleanup:

```text
ASG Desired 1 → 0
    ↓
Termination Lifecycle Hook
    ↓
EventBridge
    ↓
BoundaryWorkerCleanup Lambda
    ↓
HCP Vault
    ↓
HCP Boundary
    ↓
Delete aws-asg-<instance-id>
    ↓
CompleteLifecycleAction
    ↓
EC2 terminates
```

---

# Step 1 — Create AWS IAM Role for Boundary EC2 Workers

## Why we need this

The Boundary worker EC2 instance needs an AWS identity so it can authenticate to HCP Vault using Vault AWS IAM authentication.

This role does **not** need KMS or Secrets Manager permissions if Vault is your secret store.

## Role name

```text
BoundaryWorkerRole
```

## Trust relationship

Go to:

```text
AWS Console
→ IAM
→ Roles
→ Create role
→ AWS service
→ EC2
```

Or use this trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Result

```text
Boundary EC2 Worker
    ↓ uses
BoundaryWorkerRole
    ↓
Vault AWS Auth
```

---

# Step 2 — Create AWS IAM Role for BoundarySessionCounter Lambda

## Why we need this

`BoundarySessionCounter` needs:

- Lambda execution permissions
- CloudWatch logging
- VPC ENI permissions
- AWS identity for Vault AWS Auth

## Role name

```text
BoundarySessionMonitorLambdaRole
```

## Trust relationship

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Attach AWS managed policies

```text
AWSLambdaBasicExecutionRole
AWSLambdaVPCAccessExecutionRole
```

You do **not** need:

```text
cloudwatch:PutMetricData
```

because the metric is sent directly to Datadog.

---

# Step 3 — Create AWS IAM Role for BoundaryWorkerCleanup Lambda

## Why we need this

The cleanup Lambda must:

- run inside Lambda
- write logs
- use VPC networking
- authenticate to Vault
- call `autoscaling:CompleteLifecycleAction`

## Role name

```text
BoundaryWorkerCleanup-role-ro7ij99a
```

## Trust relationship

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Attach AWS managed policies

```text
AWSLambdaBasicExecutionRole
AWSLambdaVPCAccessExecutionRole
```

## Add inline policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CompleteBoundaryWorkerTermination",
      "Effect": "Allow",
      "Action": [
        "autoscaling:CompleteLifecycleAction"
      ],
      "Resource": "arn:aws:autoscaling:<AWS_REGION>:<AWS_ACCOUNT_ID>:autoScalingGroup:<ASG_UUID>:autoScalingGroupName/boundary-worker-auto-scaling-group"
    }
  ]
}
```

---

# Step 4 — Create Datadog AWS Scaling Role

## Why we need this

Datadog now controls AWS Auto Scaling directly.

The old `BoundaryWorkerScaler` Lambda is no longer required.

## Role name

```text
DatadogBoundaryScalingRole
```

## Trust relationship

Trusted entity:

```text
Datadog AWS account
```

Condition:

```text
Datadog External ID
```

Use:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<DATADOG_AWS_ACCOUNT_ID>:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "<DATADOG_EXTERNAL_ID>"
        }
      }
    }
  ]
}
```

## Add permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescribeBoundaryASG",
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SetBoundaryDesiredCapacity",
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity"
      ],
      "Resource": "arn:aws:autoscaling:<AWS_REGION>:<AWS_ACCOUNT_ID>:autoScalingGroup:<ASG_UUID>:autoScalingGroupName/boundary-worker-auto-scaling-group"
    }
  ]
}
```

---

# Step 5 — Configure Vault Environment

## Why we need this

All secrets and SSH signing are managed through HCP Vault.

Set:

```bash
export VAULT_ADDR="<HCP_VAULT_PRIVATE_ENDPOINT>"
export VAULT_NAMESPACE="admin"
```

Login:

```bash
vault login
```

Verify:

```bash
vault status
```

---

# Step 6 — Enable Vault AWS Auth

Check:

```bash
vault auth list
```

If `aws/` is not enabled:

```bash
vault auth enable aws
```

## Why

AWS workloads will authenticate to Vault using IAM instead of long-lived Vault tokens.

---

# Step 7 — Create Vault Policies

## 7.1 ASG worker policy

Create:

```bash
cat > boundary-asg-worker.hcl <<'EOF'
path "boundary-registration/data/asg-worker" {
  capabilities = ["read"]
}
EOF
```

Apply:

```bash
vault policy write boundary-asg-worker boundary-asg-worker.hcl
```

---

## 7.2 Session monitor policy

```bash
cat > boundary-session-monitor.hcl <<'EOF'
path "boundary-registration/data/session-monitor" {
  capabilities = ["read"]
}

path "boundary-registration/data/datadog-metrics" {
  capabilities = ["read"]
}
EOF
```

Apply:

```bash
vault policy write boundary-session-monitor boundary-session-monitor.hcl
```

---

## 7.3 Cleanup policy

```bash
cat > boundary-worker-cleanup.hcl <<'EOF'
path "boundary-registration/data/worker-cleanup" {
  capabilities = ["read"]
}
EOF
```

Apply:

```bash
vault policy write boundary-worker-cleanup boundary-worker-cleanup.hcl
```

---

## 7.4 Boundary controller policy

```bash
cat > boundary-controller.hcl <<'EOF'
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

path "sys/leases/renew" {
  capabilities = ["update"]
}

path "sys/leases/revoke" {
  capabilities = ["update"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}
EOF
```

Apply:

```bash
vault policy write boundary-controller boundary-controller.hcl
```

---

## 7.5 SSH signing policy

```bash
cat > boundary-ssh-policy.hcl <<'EOF'
path "boundary-ssh/sign/boundary-client" {
  capabilities = ["create", "update"]
}
EOF
```

Apply:

```bash
vault policy write boundary-ssh-policy boundary-ssh-policy.hcl
```

---

# Step 8 — Create Vault AWS Auth Roles

## 8.1 ASG worker Vault role

```bash
vault write auth/aws/role/boundary-asg-worker \
  auth_type=iam \
  bound_iam_principal_arn="arn:aws:iam::<AWS_ACCOUNT_ID>:role/BoundaryWorkerRole" \
  policies="boundary-asg-worker" \
  ttl=15m \
  max_ttl=30m \
  resolve_aws_unique_ids=false
```

Verify:

```bash
vault read auth/aws/role/boundary-asg-worker
```

---

## 8.2 Session Counter Vault role

```bash
vault write auth/aws/role/boundary-session-monitor-lambda \
  auth_type=iam \
  bound_iam_principal_arn="arn:aws:iam::<AWS_ACCOUNT_ID>:role/BoundarySessionMonitorLambdaRole" \
  policies="boundary-session-monitor" \
  ttl=15m \
  max_ttl=30m \
  resolve_aws_unique_ids=false
```

Verify:

```bash
vault read auth/aws/role/boundary-session-monitor-lambda
```

---

## 8.3 Cleanup Vault role

```bash
vault write auth/aws/role/boundary-worker-cleanup \
  auth_type=iam \
  bound_iam_principal_arn="arn:aws:iam::<AWS_ACCOUNT_ID>:role/BoundaryWorkerCleanup-role-ro7ij99a" \
  policies="boundary-worker-cleanup" \
  ttl=15m \
  max_ttl=30m \
  resolve_aws_unique_ids=false
```

Verify:

```bash
vault read auth/aws/role/boundary-worker-cleanup
```

---

# Step 9 — Store Automation Secrets in Vault

## ASG worker registration

```bash
vault kv put boundary-registration/asg-worker \
  login_name="<BOUNDARY_WORKER_REGISTRATION_LOGIN>" \
  password="<BOUNDARY_WORKER_REGISTRATION_PASSWORD>"
```

## Session monitor

```bash
vault kv put boundary-registration/session-monitor \
  login_name="boundary-session-monitor" \
  password="<BOUNDARY_SESSION_MONITOR_PASSWORD>"
```

## Datadog API key

```bash
vault kv put boundary-registration/datadog-metrics \
  api_key="<DATADOG_API_KEY>"
```

## Cleanup account

```bash
vault kv put boundary-registration/worker-cleanup \
  login_name="boundary-worker-cleanup" \
  password="<BOUNDARY_WORKER_CLEANUP_PASSWORD>"
```

---

# Step 10 — Configure Vault SSH Secrets Engine

Enable:

```bash
vault secrets enable -path=boundary-ssh ssh
```

Generate CA:

```bash
vault write boundary-ssh/config/ca generate_signing_key=true
```

Read public key:

```bash
vault read -field=public_key boundary-ssh/config/ca
```

Create role:

```bash
vault write boundary-ssh/roles/boundary-client \
  key_type=ca \
  allow_user_certificates=true \
  allowed_users="azureuser" \
  default_user="azureuser" \
  allowed_extensions="permit-pty" \
  default_extensions='{"permit-pty":""}' \
  ttl="10m" \
  max_ttl="10m" \
  not_before_duration="30s"
```

---

# Step 11 — Create Boundary Vault Credential Store Token

```bash
vault token create \
  -no-default-policy=true \
  -policy="boundary-controller" \
  -policy="boundary-ssh-policy" \
  -orphan=true \
  -period=24h \
  -renewable=true
```

Store this token securely.

Verify:

```bash
VAULT_TOKEN="<BOUNDARY_VAULT_TOKEN>" vault token lookup
```

Expected:

```text
orphan     true
renewable  true
period     24h
```

---

# Step 12 — Configure Boundary RBAC Accounts

## 12.1 Session Monitor

Create a Boundary identity:

```text
boundary-session-monitor
```

Grant:

```text
ids=*;type=session;actions=list,read
```

Why:

The Session Counter only needs session visibility.

---

## 12.2 Cleanup Account

Create:

```text
boundary-worker-cleanup
```

Grant:

```text
type=worker;actions=list
ids=*;type=worker;actions=read,delete
```

Why:

The cleanup Lambda must list and delete temporary workers.

---

## 12.3 ASG Worker Registration Account

Create a dedicated Boundary registration identity.

Required grant:

```text
type=worker;actions=create:worker-led
```

Store its username/password in:

```text
boundary-registration/asg-worker
```

---

# Step 13 — Configure SSH Target to Trust Vault CA

Copy Vault CA public key to target.

Example:

```bash
sudo install -m 0644 vault-ssh-ca.pub \
  /etc/ssh/vault-ssh-ca.pub
```

Configure SSH:

```bash
echo 'TrustedUserCAKeys /etc/ssh/vault-ssh-ca.pub' \
  | sudo tee /etc/ssh/sshd_config.d/99-vault-ca.conf
```

Validate:

```bash
sudo sshd -t
```

Restart:

```bash
sudo systemctl restart ssh || sudo systemctl restart sshd
```

---

# Step 14 — Configure Permanent Boundary Worker

Example:

```hcl
disable_mlock = true

hcp_boundary_cluster_id = "<HCP_BOUNDARY_CLUSTER_ID>"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  auth_storage_path = "/var/lib/boundary"
}

tags {
  type       = ["egress"]
  cloud      = ["aws"]
  target     = ["on-aws"]
  cred-store = ["vault"]
}
```

Restart:

```bash
sudo systemctl restart boundary-worker
```

Check:

```bash
sudo systemctl status boundary-worker --no-pager -l
```

---

# Step 15 — Create Boundary Vault Credential Store

Example CLI:

```bash
export BOUNDARY_ADDR="<HCP_BOUNDARY_ADDR>"
export BOUNDARY_TOKEN="<ADMIN_TOKEN>"
export BOUNDARY_VAULT_TOKEN="<BOUNDARY_VAULT_TOKEN>"
```

Create:

```bash
boundary credential-stores create vault \
  -name="hcp-vault-ssh" \
  -scope-id="<BOUNDARY_PROJECT_ID>" \
  -vault-address="<HCP_VAULT_PRIVATE_ENDPOINT>" \
  -vault-namespace="admin" \
  -vault-token="env://BOUNDARY_VAULT_TOKEN" \
  -worker-filter='"vault" in "/tags/cred-store"' \
  -token env://BOUNDARY_TOKEN
```

Record:

```text
VAULT_CREDENTIAL_STORE_ID
```

---

# Step 16 — Create Boundary SSH Credential Library

```bash
boundary credential-libraries create vault-ssh-certificate \
  -name="boundary-ssh-cert" \
  -credential-store-id="<VAULT_CREDENTIAL_STORE_ID>" \
  -vault-path="boundary-ssh/sign/boundary-client" \
  -username="azureuser" \
  -key-type="ed25519" \
  -ttl="10m" \
  -extension="permit-pty" \
  -token env://BOUNDARY_TOKEN
```

Record:

```text
CREDENTIAL_LIBRARY_ID
```

---

# Step 17 — Attach Credential Library to Boundary Target

```bash
boundary targets add-credential-sources \
  -id="<TARGET_ID>" \
  -injected-application-credential-source="<CREDENTIAL_LIBRARY_ID>" \
  -token env://BOUNDARY_TOKEN
```

---

# Step 18 — Create ASG Launch Template

## Launch Template name

```text
autoscaling-worker-template
```

Use:

```text
Private subnet
No public IP
BoundaryWorkerRole instance profile
Boundary worker security group
```

Use this User Data:

```bash
#!/usr/bin/env bash
set -euo pipefail

BOUNDARY_ADDR="<HCP_BOUNDARY_ADDR>"
BOUNDARY_AUTH_METHOD_ID="<BOUNDARY_PASSWORD_AUTH_METHOD_ID>"
BOUNDARY_CLUSTER_ID="<HCP_BOUNDARY_CLUSTER_ID>"

VAULT_ADDR="<HCP_VAULT_PRIVATE_ENDPOINT>"
VAULT_NAMESPACE="admin"
VAULT_AWS_ROLE="boundary-asg-worker"

export BOUNDARY_ADDR
export VAULT_ADDR
export VAULT_NAMESPACE

apt-get update
apt-get install -y curl wget gpg lsb-release jq unzip

wget -qO- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  > /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list

apt-get update
apt-get install -y boundary-enterprise vault

IMDS_TOKEN="$(curl -fsS -X PUT \
  -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600' \
  http://169.254.169.254/latest/api/token)"

INSTANCE_ID="$(curl -fsS \
  -H "X-aws-ec2-metadata-token: ${IMDS_TOKEN}" \
  http://169.254.169.254/latest/meta-data/instance-id)"

WORKER_NAME="aws-asg-${INSTANCE_ID}"

id boundary >/dev/null 2>&1 || \
  useradd --system --home /var/lib/boundary --shell /usr/sbin/nologin boundary

mkdir -p /etc/boundary.d /var/lib/boundary
chown -R boundary:boundary /var/lib/boundary
chmod 700 /var/lib/boundary

cat >/etc/boundary.d/pki-worker.hcl <<EOF
disable_mlock = true

hcp_boundary_cluster_id = "${BOUNDARY_CLUSTER_ID}"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  auth_storage_path = "/var/lib/boundary"
}

tags {
  type       = ["egress"]
  cloud      = ["aws"]
  pool       = ["aws-autoscaling"]
  target     = ["on-aws"]
  cred-store = ["vault"]
}
EOF

cat >/etc/systemd/system/boundary-worker.service <<'EOF'
[Unit]
Description=HashiCorp Boundary Worker
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=boundary
Group=boundary
ExecStart=/usr/bin/boundary server -config=/etc/boundary.d/pki-worker.hcl
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now boundary-worker

AUTH_REQUEST_FILE="/var/lib/boundary/auth_request_token"

for i in $(seq 1 60); do
  if [ -s "${AUTH_REQUEST_FILE}" ]; then
    break
  fi
  sleep 2
done

WORKER_AUTH_REQUEST_TOKEN="$(cat "${AUTH_REQUEST_FILE}")"

VAULT_TOKEN="$(vault login \
  -method=aws \
  -token-only \
  -no-store \
  role="${VAULT_AWS_ROLE}")"

export VAULT_TOKEN

SECRET_JSON="$(vault kv get \
  -mount=boundary-registration \
  -format=json \
  asg-worker)"

BOUNDARY_LOGIN_NAME="$(echo "${SECRET_JSON}" | jq -r '.data.data.login_name')"
BOUNDARY_PASSWORD="$(echo "${SECRET_JSON}" | jq -r '.data.data.password')"

AUTH_PAYLOAD="$(jq -n \
  --arg login "${BOUNDARY_LOGIN_NAME}" \
  --arg password "${BOUNDARY_PASSWORD}" \
  '{
    attributes: {
      login_name: $login,
      password: $password
    },
    command: "login"
  }')"

BOUNDARY_AUTH_JSON="$(curl -fsS \
  -X POST \
  -H 'Content-Type: application/json' \
  -d "${AUTH_PAYLOAD}" \
  "${BOUNDARY_ADDR}/v1/auth-methods/${BOUNDARY_AUTH_METHOD_ID}:authenticate")"

BOUNDARY_TOKEN="$(echo "${BOUNDARY_AUTH_JSON}" | jq -r '.attributes.token')"

export BOUNDARY_TOKEN

boundary workers create worker-led \
  -name="${WORKER_NAME}" \
  -description="AWS Auto Scaling Boundary worker" \
  -worker-generated-auth-token="${WORKER_AUTH_REQUEST_TOKEN}" \
  -token env://BOUNDARY_TOKEN

unset BOUNDARY_PASSWORD
unset BOUNDARY_LOGIN_NAME
unset BOUNDARY_TOKEN
unset VAULT_TOKEN
unset SECRET_JSON
unset BOUNDARY_AUTH_JSON
unset WORKER_AUTH_REQUEST_TOKEN
```

---

# Step 19 — Create Auto Scaling Group

## Name

```text
boundary-worker-auto-scaling-group
```

## Capacity

```text
Min: 0
Desired: 0
Max: 2 or 3
```

Why:

```text
Scale Out → Desired = 1
Scale In  → Desired = 0
```

---

# Step 20 — Create BoundarySessionCounter Lambda

## Function

```text
BoundarySessionCounter
```

## Runtime

```text
Python 3.12
```

## Execution role

```text
BoundarySessionMonitorLambdaRole
```

## Environment variables

```text
VAULT_ADDR=<HCP_VAULT_PRIVATE_ENDPOINT>
VAULT_NAMESPACE=admin
VAULT_AWS_ROLE=boundary-session-monitor-lambda

BOUNDARY_ADDR=<HCP_BOUNDARY_ADDR>
BOUNDARY_AUTH_METHOD_ID=<BOUNDARY_PASSWORD_AUTH_METHOD_ID>
BOUNDARY_SCOPE_ID=global

DD_SITE=datadoghq.com
```

## Full Lambda code

```python
import os
import json
import base64
import time
import urllib.request
import urllib.error
import urllib.parse

import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest


def vault_aws_login(vault_addr, vault_namespace, vault_aws_role):
    boto_session = boto3.Session()
    credentials = boto_session.get_credentials().get_frozen_credentials()

    sts_url = "https://sts.amazonaws.com/"
    sts_body = "Action=GetCallerIdentity&Version=2011-06-15"

    aws_request = AWSRequest(
        method="POST",
        url=sts_url,
        data=sts_body,
        headers={
            "Content-Type":
                "application/x-www-form-urlencoded; charset=utf-8",
            "Host": "sts.amazonaws.com",
        },
    )

    SigV4Auth(
        credentials,
        "sts",
        "us-east-1",
    ).add_auth(aws_request)

    signed_headers = dict(aws_request.headers.items())

    payload = {
        "role": vault_aws_role,
        "iam_http_request_method": "POST",
        "iam_request_url": base64.b64encode(
            sts_url.encode()
        ).decode(),
        "iam_request_body": base64.b64encode(
            sts_body.encode()
        ).decode(),
        "iam_request_headers": base64.b64encode(
            json.dumps(signed_headers).encode()
        ).decode(),
    }

    request = urllib.request.Request(
        f"{vault_addr}/v1/auth/aws/login",
        data=json.dumps(payload).encode(),
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-Vault-Namespace": vault_namespace,
        },
    )

    with urllib.request.urlopen(request, timeout=10) as response:
        result = json.loads(response.read().decode())

    print("Vault AWS authentication successful")
    return result["auth"]["client_token"]


def vault_read_kv2(vault_addr, namespace, token, api_path):
    request = urllib.request.Request(
        f"{vault_addr}/v1/{api_path}",
        method="GET",
        headers={
            "X-Vault-Token": token,
            "X-Vault-Namespace": namespace,
        },
    )

    with urllib.request.urlopen(request, timeout=10) as response:
        result = json.loads(response.read().decode())

    return result["data"]["data"]


def boundary_login(boundary_addr, auth_method_id, login_name, password):
    payload = {
        "attributes": {
            "login_name": login_name,
            "password": password,
        },
        "command": "login",
    }

    request = urllib.request.Request(
        f"{boundary_addr}/v1/auth-methods/"
        f"{auth_method_id}:authenticate",
        data=json.dumps(payload).encode(),
        method="POST",
        headers={
            "Content-Type": "application/json",
        },
    )

    with urllib.request.urlopen(request, timeout=10) as response:
        result = json.loads(response.read().decode())

    print("Boundary authentication successful")
    return result["attributes"]["token"]


def lambda_handler(event, context):
    try:
        vault_addr = os.environ["VAULT_ADDR"].rstrip("/")
        vault_namespace = os.environ["VAULT_NAMESPACE"]
        vault_aws_role = os.environ["VAULT_AWS_ROLE"]

        boundary_addr = os.environ["BOUNDARY_ADDR"].rstrip("/")
        boundary_auth_method_id = os.environ["BOUNDARY_AUTH_METHOD_ID"]
        boundary_scope_id = os.environ.get("BOUNDARY_SCOPE_ID", "global")

        dd_site = os.environ.get("DD_SITE", "datadoghq.com")

        vault_token = vault_aws_login(
            vault_addr,
            vault_namespace,
            vault_aws_role,
        )

        boundary_secret = vault_read_kv2(
            vault_addr,
            vault_namespace,
            vault_token,
            "boundary-registration/data/session-monitor",
        )

        print("Boundary monitoring credentials retrieved from Vault")

        datadog_secret = vault_read_kv2(
            vault_addr,
            vault_namespace,
            vault_token,
            "boundary-registration/data/datadog-metrics",
        )

        print("Datadog API key retrieved from Vault")

        boundary_token = boundary_login(
            boundary_addr,
            boundary_auth_method_id,
            boundary_secret["login_name"],
            boundary_secret["password"],
        )

        query = urllib.parse.urlencode({
            "scope_id": boundary_scope_id,
            "recursive": "true",
        })

        sessions_request = urllib.request.Request(
            f"{boundary_addr}/v1/sessions?{query}",
            method="GET",
            headers={
                "Authorization": f"Bearer {boundary_token}",
            },
        )

        with urllib.request.urlopen(sessions_request, timeout=10) as response:
            sessions_result = json.loads(response.read().decode())

        sessions = sessions_result.get("items", [])

        active_count = sum(
            1
            for session in sessions
            if session.get("status") == "active"
        )

        print(f"Active Boundary sessions: {active_count}")

        datadog_payload = {
            "series": [
                {
                    "metric": "boundary.active_sessions",
                    "type": 3,
                    "points": [
                        {
                            "timestamp": int(time.time()),
                            "value": active_count,
                        }
                    ],
                    "resources": [
                        {
                            "name": "hcp-boundary",
                            "type": "service",
                        }
                    ],
                }
            ]
        }

        datadog_request = urllib.request.Request(
            f"https://api.{dd_site}/api/v2/series",
            data=json.dumps(datadog_payload).encode(),
            method="POST",
            headers={
                "Content-Type": "application/json",
                "DD-API-KEY": datadog_secret["api_key"],
            },
        )

        with urllib.request.urlopen(datadog_request, timeout=10) as response:
            datadog_status = response.status

        print(
            "Published Datadog metric: "
            f"boundary.active_sessions={active_count}"
        )

        return {
            "statusCode": 200,
            "body": {
                "success": True,
                "active_sessions": active_count,
                "datadog_http_status": datadog_status,
            },
        }

    except Exception as exc:
        print(f"ERROR: {str(exc)}")
        raise
```

---

# Step 21 — Schedule BoundarySessionCounter Every Minute

Create EventBridge schedule:

```bash
aws events put-rule \
  --name boundary-session-counter-every-minute \
  --schedule-expression 'rate(1 minute)' \
  --state ENABLED
```

Allow EventBridge:

```bash
aws lambda add-permission \
  --function-name BoundarySessionCounter \
  --statement-id EventBridgeBoundarySessionCounter \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn "arn:aws:events:<AWS_REGION>:<AWS_ACCOUNT_ID>:rule/boundary-session-counter-every-minute"
```

Target:

```bash
aws events put-targets \
  --rule boundary-session-counter-every-minute \
  --targets "Id"="1","Arn"="arn:aws:lambda:<AWS_REGION>:<AWS_ACCOUNT_ID>:function:BoundarySessionCounter"
```

---

# Step 22 — Configure Datadog AWS Connection

Go to:

```text
Datadog
→ Integrations
→ Amazon Web Services
→ Add New AWS Account
→ Manually
```

Use:

```text
Role Delegation
```

Copy:

```text
AWS External ID
```

In AWS create/use:

```text
DatadogBoundaryScalingRole
```

Then in Datadog:

```text
AWS Account ID:
<YOUR_AWS_ACCOUNT_ID>

AWS Role Name:
DatadogBoundaryScalingRole
```

Save.

---

# Step 23 — Configure Datadog Scale-Out Monitor

Metric:

```text
boundary.active_sessions
```

Filter:

```text
service:hcp-boundary
```

Threshold:

```text
> 9
```

Attach workflow:

```text
Boundary-Worker-Scale-Out
```

---

# Step 24 — Configure Datadog Scale-Out Workflow

Use:

```text
AWS
→ AWS Autoscaling
→ Set desired capacity
```

Configuration:

```text
Connection:
Boundary-AWS-Scaling

Region:
us-east-1

Auto Scaling Group:
boundary-worker-auto-scaling-group

Desired Capacity:
1
```

Do not use only:

```text
Describe auto scaling group
```

because it is read-only.

---

# Step 25 — Configure Datadog Scale-In Monitor

Metric:

```text
boundary.active_sessions
```

Filter:

```text
service:hcp-boundary
```

Use:

```text
MAX over last 3 minutes
below 10
```

Why:

```text
8,7,6
MAX=8
→ below 10 for the full window
```

---

# Step 26 — Configure Datadog Scale-In Workflow

Use:

```text
AWS Autoscaling
→ Set desired capacity
```

Configuration:

```text
Connection:
Boundary-AWS-Scaling

Region:
us-east-1

ASG:
boundary-worker-auto-scaling-group

Desired Capacity:
0
```

---

# Step 27 — Create ASG Termination Lifecycle Hook

```bash
aws autoscaling put-lifecycle-hook \
  --lifecycle-hook-name boundary-worker-terminate-cleanup \
  --auto-scaling-group-name boundary-worker-auto-scaling-group \
  --lifecycle-transition autoscaling:EC2_INSTANCE_TERMINATING \
  --heartbeat-timeout 120 \
  --default-result CONTINUE
```

Why:

This pauses EC2 termination while HCP Boundary worker cleanup runs.

---

# Step 28 — Create BoundaryWorkerCleanup Lambda

## Function

```text
BoundaryWorkerCleanup
```

## Runtime

```text
Python 3.12
```

## Role

```text
BoundaryWorkerCleanup-role-ro7ij99a
```

## Environment variables

```text
VAULT_ADDR=<HCP_VAULT_PRIVATE_ENDPOINT>
VAULT_NAMESPACE=admin
VAULT_AWS_ROLE=boundary-worker-cleanup

BOUNDARY_ADDR=<HCP_BOUNDARY_ADDR>
BOUNDARY_AUTH_METHOD_ID=<BOUNDARY_PASSWORD_AUTH_METHOD_ID>
```

## Full Lambda code

```python
import os
import json
import base64
import urllib.request
import urllib.error
import urllib.parse

import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest


AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")

autoscaling = boto3.client(
    "autoscaling",
    region_name=AWS_REGION,
)


def vault_aws_login(vault_addr, namespace, vault_role):
    print("Authenticating to Vault using AWS IAM...")

    credentials = (
        boto3.Session()
        .get_credentials()
        .get_frozen_credentials()
    )

    sts_url = "https://sts.amazonaws.com/"
    sts_body = "Action=GetCallerIdentity&Version=2011-06-15"

    aws_request = AWSRequest(
        method="POST",
        url=sts_url,
        data=sts_body,
        headers={
            "Content-Type":
                "application/x-www-form-urlencoded; charset=utf-8",
            "Host": "sts.amazonaws.com",
        },
    )

    SigV4Auth(
        credentials,
        "sts",
        "us-east-1",
    ).add_auth(aws_request)

    signed_headers = dict(aws_request.headers.items())

    payload = {
        "role": vault_role,
        "iam_http_request_method": "POST",
        "iam_request_url": base64.b64encode(
            sts_url.encode()
        ).decode(),
        "iam_request_body": base64.b64encode(
            sts_body.encode()
        ).decode(),
        "iam_request_headers": base64.b64encode(
            json.dumps(signed_headers).encode()
        ).decode(),
    }

    request = urllib.request.Request(
        f"{vault_addr}/v1/auth/aws/login",
        data=json.dumps(payload).encode(),
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-Vault-Namespace": namespace,
        },
    )

    with urllib.request.urlopen(request, timeout=15) as response:
        result = json.loads(response.read().decode())

    print("Vault AWS authentication successful")
    return result["auth"]["client_token"]


def get_cleanup_secret(vault_addr, namespace, vault_token):
    request = urllib.request.Request(
        f"{vault_addr}/v1/"
        "boundary-registration/data/worker-cleanup",
        method="GET",
        headers={
            "X-Vault-Token": vault_token,
            "X-Vault-Namespace": namespace,
        },
    )

    with urllib.request.urlopen(request, timeout=15) as response:
        result = json.loads(response.read().decode())

    print("Boundary cleanup credentials retrieved")
    return result["data"]["data"]


def boundary_login(
    boundary_addr,
    auth_method_id,
    login_name,
    password,
):
    payload = {
        "attributes": {
            "login_name": login_name,
            "password": password,
        },
        "command": "login",
    }

    request = urllib.request.Request(
        f"{boundary_addr}/v1/auth-methods/"
        f"{auth_method_id}:authenticate",
        data=json.dumps(payload).encode(),
        method="POST",
        headers={
            "Content-Type": "application/json",
        },
    )

    with urllib.request.urlopen(request, timeout=15) as response:
        result = json.loads(response.read().decode())

    print("Boundary authentication successful")
    return result["attributes"]["token"]


def find_boundary_worker(
    boundary_addr,
    boundary_token,
    instance_id,
):
    expected_name = f"aws-asg-{instance_id}"

    query = urllib.parse.urlencode({
        "scope_id": "global",
    })

    request = urllib.request.Request(
        f"{boundary_addr}/v1/workers?{query}",
        method="GET",
        headers={
            "Authorization": f"Bearer {boundary_token}",
        },
    )

    with urllib.request.urlopen(request, timeout=15) as response:
        result = json.loads(response.read().decode())

    for worker in result.get("items", []):
        if worker.get("name") == expected_name:
            print(
                "Matching Boundary worker found: "
                f"{worker.get('id')}"
            )
            return worker.get("id")

    return None


def delete_boundary_worker(
    boundary_addr,
    boundary_token,
    worker_id,
):
    print(f"Deleting Boundary worker: {worker_id}")

    request = urllib.request.Request(
        f"{boundary_addr}/v1/workers/{worker_id}",
        method="DELETE",
        headers={
            "Authorization": f"Bearer {boundary_token}",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=15):
            pass

        print("Boundary worker deleted")

    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            print("Boundary worker already absent")
            return
        raise


def complete_lifecycle_action(
    asg_name,
    lifecycle_hook_name,
    lifecycle_action_token,
):
    autoscaling.complete_lifecycle_action(
        LifecycleHookName=lifecycle_hook_name,
        AutoScalingGroupName=asg_name,
        LifecycleActionResult="CONTINUE",
        LifecycleActionToken=lifecycle_action_token,
    )

    print("Lifecycle action completed with CONTINUE")


def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    detail = event.get("detail", {})

    instance_id = detail.get("EC2InstanceId")
    asg_name = detail.get("AutoScalingGroupName")
    hook_name = detail.get("LifecycleHookName")
    action_token = detail.get("LifecycleActionToken")

    expected_worker_name = f"aws-asg-{instance_id}"

    print(f"EC2 Instance ID: {instance_id}")
    print(f"Expected Boundary worker: {expected_worker_name}")

    try:
        vault_addr = os.environ["VAULT_ADDR"].rstrip("/")
        namespace = os.environ["VAULT_NAMESPACE"]
        vault_role = os.environ["VAULT_AWS_ROLE"]

        boundary_addr = os.environ["BOUNDARY_ADDR"].rstrip("/")
        auth_method_id = os.environ["BOUNDARY_AUTH_METHOD_ID"]

        vault_token = vault_aws_login(
            vault_addr,
            namespace,
            vault_role,
        )

        secret = get_cleanup_secret(
            vault_addr,
            namespace,
            vault_token,
        )

        boundary_token = boundary_login(
            boundary_addr,
            auth_method_id,
            secret["login_name"],
            secret["password"],
        )

        worker_id = find_boundary_worker(
            boundary_addr,
            boundary_token,
            instance_id,
        )

        if worker_id:
            delete_boundary_worker(
                boundary_addr,
                boundary_token,
                worker_id,
            )

        complete_lifecycle_action(
            asg_name,
            hook_name,
            action_token,
        )

        return {
            "statusCode": 200,
            "body": {
                "success": True,
                "instance_id": instance_id,
                "worker_id": worker_id,
            },
        }

    except Exception as exc:
        print(f"Cleanup ERROR: {str(exc)}")

        try:
            complete_lifecycle_action(
                asg_name,
                hook_name,
                action_token,
            )
        except Exception:
            pass

        raise
```

---

# Step 29 — Create EventBridge Cleanup Rule

Event pattern:

```json
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance-terminate Lifecycle Action"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "boundary-worker-auto-scaling-group"
    ]
  }
}
```

Create rule:

```bash
aws events put-rule \
  --name boundary-worker-termination-cleanup \
  --event-pattern file://event-pattern.json \
  --state ENABLED
```

Allow EventBridge:

```bash
aws lambda add-permission \
  --function-name BoundaryWorkerCleanup \
  --statement-id EventBridgeBoundaryWorkerCleanup \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn "arn:aws:events:<AWS_REGION>:<AWS_ACCOUNT_ID>:rule/boundary-worker-termination-cleanup"
```

Add target:

```bash
aws events put-targets \
  --rule boundary-worker-termination-cleanup \
  --targets "Id"="1","Arn"="arn:aws:lambda:<AWS_REGION>:<AWS_ACCOUNT_ID>:function:BoundaryWorkerCleanup"
```

---

# Step 30 — Test 10 Active Sessions

Set:

```bash
export BOUNDARY_ADDR="<HCP_BOUNDARY_ADDR>"
export BOUNDARY_TOKEN="<FRESH_BOUNDARY_TOKEN>"
```

Start 10:

```bash
for i in $(seq 1 10); do
  boundary connect ssh \
    -target-id="<TARGET_ID>" \
    -token env://BOUNDARY_TOKEN \
    -- -N >"/tmp/boundary-session-$i.log" 2>&1 &
  sleep 0.5
done
```

Check:

```bash
boundary sessions list \
  -scope-id=global \
  -recursive \
  -format=json \
  -token env://BOUNDARY_TOKEN \
| jq '[.items // [] | .[] | select(.status == "active")] | length'
```

Expected:

```text
10
```

---

# Step 31 — Verify Scale-Out

Expected:

```text
BoundarySessionCounter
→ Active Boundary sessions: 10

Datadog
→ boundary.active_sessions = 10

Scale-Out Monitor
→ ALERT

Scale-Out Workflow
→ Success

ASG
→ Desired 0 → 1

EC2
→ InService

HCP Boundary
→ aws-asg-i-xxxxxxxx
```

---

# Step 32 — Stop Sessions

```bash
pkill -f 'boundary connect ssh'
```

Verify:

```bash
boundary sessions list \
  -scope-id=global \
  -recursive \
  -format=json \
  -token env://BOUNDARY_TOKEN \
| jq '[.items // [] | .[] | select(.status == "active")] | length'
```

Expected:

```text
0
```

---

# Step 33 — Verify Scale-In

After the 3-minute threshold:

```text
Datadog Scale-In
→ ALERT

Workflow
→ Desired = 0

ASG
→ instance Terminating:Wait

EventBridge
→ BoundaryWorkerCleanup

BoundaryWorkerCleanup
→ delete aws-asg-<instance-id>

CompleteLifecycleAction
→ CONTINUE

EC2
→ Terminated
```

---

# Step 34 — Final Resource List

## Keep

```text
BoundaryWorkerRole
BoundarySessionMonitorLambdaRole
BoundaryWorkerCleanup-role-ro7ij99a
DatadogBoundaryScalingRole

BoundarySessionCounter Lambda
BoundaryWorkerCleanup Lambda

boundary-session-counter-every-minute
boundary-worker-termination-cleanup

boundary-worker-auto-scaling-group
boundary-worker-terminate-cleanup

Vault AWS roles:
boundary-asg-worker
boundary-session-monitor-lambda
boundary-worker-cleanup
```

## Remove / Do Not Recreate

```text
BoundaryWorkerScaler Lambda
BoundaryWorkerScalingPolicy old execution role
old Datadog lambda:InvokeFunction permission
unused duplicate cleanup roles
unused EventBridge Lambda invocation roles
```

---

# Final Working Flow

```text
Boundary Sessions
      ↓
BoundarySessionCounter
      ↓
Datadog
      ↓
DatadogBoundaryScalingRole
      ↓
AWS Auto Scaling
      ↓
Temporary Boundary Worker
```

Scale-in:

```text
Datadog
   ↓
ASG Desired = 0
   ↓
Lifecycle Hook
   ↓
EventBridge
   ↓
BoundaryWorkerCleanup
   ↓
Vault
   ↓
Boundary
   ↓
Delete temporary worker
   ↓
EC2 terminates
```
