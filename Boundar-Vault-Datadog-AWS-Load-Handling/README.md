# Boundary + Vault + Datadog + AWS Load Handling

This repository documents the final working implementation for automatically scaling self-managed HCP Boundary workers on AWS based on active Boundary sessions.

## Final architecture

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
Desired Capacity = 1 / 0
```

Scale-in cleanup:

```text
ASG scale-in
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
Delete matching aws-asg-<instance-id> worker
    ↓
CompleteLifecycleAction
    ↓
EC2 terminates
```

## Why this design

- `BoundarySessionCounter` is kept because Datadog needs a Boundary-specific active-session metric.
- Datadog controls AWS Auto Scaling directly, so the old scaler Lambda is unnecessary.
- `BoundaryWorkerCleanup` is kept because AWS cannot automatically delete the matching HCP Boundary worker object.
- HCP Vault stores Boundary/Datadog credentials and uses AWS IAM authentication for AWS workloads.
- One permanent Boundary worker remains outside the ASG so baseline connectivity remains available when ASG desired capacity is `0`.

## Sections

1. `docs/01-architecture.md`
2. `docs/02-boundary.md`
3. `docs/03-vault.md`
4. `docs/04-aws-iam.md`
5. `docs/05-session-counter.md`
6. `docs/06-datadog.md`
7. `docs/07-autoscaling.md`
8. `docs/08-cleanup.md`
9. `docs/09-testing.md`

## Security

Never commit Boundary tokens, Vault tokens, passwords, Datadog API/App keys, Datadog External IDs, AWS access keys, or worker registration tokens.
