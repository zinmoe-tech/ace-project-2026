#!/usr/bin/env bash
set -euo pipefail

export VAULT_ADDR="https://vault-cluster-aws-private-vault-3c87b32f.7274f87b.z1.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"

vault policy write boundary-asg-worker boundary-asg-worker.hcl
vault policy write boundary-session-monitor boundary-session-monitor.hcl
vault policy write boundary-worker-cleanup boundary-worker-cleanup.hcl

vault write auth/aws/role/boundary-asg-worker \
  auth_type=iam \
  bound_iam_principal_arn="arn:aws:iam::691914216603:role/BoundaryWorkerRole" \
  policies="boundary-asg-worker" \
  ttl=15m \
  max_ttl=30m \
  resolve_aws_unique_ids=false

vault write auth/aws/role/boundary-session-monitor-lambda \
  auth_type=iam \
  bound_iam_principal_arn="arn:aws:iam::691914216603:role/BoundarySessionMonitorLambdaRole" \
  policies="boundary-session-monitor" \
  ttl=15m \
  max_ttl=30m \
  resolve_aws_unique_ids=false

vault write auth/aws/role/boundary-worker-cleanup \
  auth_type=iam \
  bound_iam_principal_arn="arn:aws:iam::691914216603:role/BoundaryWorkerCleanup-role-ro7ij99a" \
  policies="boundary-worker-cleanup" \
  ttl=15m \
  max_ttl=30m \
  resolve_aws_unique_ids=false

cat <<'MSG'
Vault AWS Auth roles configured.
Secrets are intentionally not written by this script.
Store them interactively at:
  boundary-registration/asg-worker
  boundary-registration/session-monitor
  boundary-registration/datadog-metrics
  boundary-registration/worker-cleanup
MSG
