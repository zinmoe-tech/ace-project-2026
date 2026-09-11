# 04 — AWS IAM

## Why IAM roles are required

```text
AWS IAM Role
= workload identity

Vault AWS Auth Role
= which AWS identities Vault trusts

Vault Policy
= what the authenticated identity may do
```

## Keep these custom roles

### BoundaryWorkerRole
Used by: Boundary worker EC2 instances

Trust:

```text
ec2.amazonaws.com
```

Purpose: provide AWS identity for Vault AWS authentication.

### BoundarySessionMonitorLambdaRole
Used by: `BoundarySessionCounter`

Trust:

```text
lambda.amazonaws.com
```

Attach:

```text
AWSLambdaBasicExecutionRole
AWSLambdaVPCAccessExecutionRole
```

Purpose:
- Lambda logging
- VPC ENI access
- AWS identity for Vault AWS Auth

### BoundaryWorkerCleanup-role-ro7ij99a
Used by: `BoundaryWorkerCleanup`

Trust:

```text
lambda.amazonaws.com
```

Needs:
- `AWSLambdaBasicExecutionRole`
- `AWSLambdaVPCAccessExecutionRole`
- `autoscaling:CompleteLifecycleAction`

### DatadogBoundaryScalingRole
Used by: Datadog

Trust:

```text
Datadog AWS account
+ sts:ExternalId
```

Permissions:

```text
autoscaling:DescribeAutoScalingGroups
autoscaling:SetDesiredCapacity
```

## Removed component

Do not recreate:

```text
BoundaryWorkerScaler Lambda
BoundaryWorkerScalingPolicy role
```

Datadog now controls Auto Scaling directly.
