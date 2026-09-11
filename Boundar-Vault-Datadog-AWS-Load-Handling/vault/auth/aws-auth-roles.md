# Vault AWS Auth Roles

## ASG worker

```bash
vault write auth/aws/role/boundary-asg-worker   auth_type=iam   bound_iam_principal_arn="arn:aws:iam::<AWS_ACCOUNT_ID>:role/BoundaryWorkerRole"   policies="boundary-asg-worker"   ttl=15m   max_ttl=30m   resolve_aws_unique_ids=false
```

## Session monitor

```bash
vault write auth/aws/role/boundary-session-monitor-lambda   auth_type=iam   bound_iam_principal_arn="arn:aws:iam::<AWS_ACCOUNT_ID>:role/BoundarySessionMonitorLambdaRole"   policies="boundary-session-monitor"   ttl=15m   max_ttl=30m   resolve_aws_unique_ids=false
```

## Worker cleanup

```bash
vault write auth/aws/role/boundary-worker-cleanup   auth_type=iam   bound_iam_principal_arn="arn:aws:iam::<AWS_ACCOUNT_ID>:role/BoundaryWorkerCleanup-role-ro7ij99a"   policies="boundary-worker-cleanup"   ttl=15m   max_ttl=30m   resolve_aws_unique_ids=false
```
