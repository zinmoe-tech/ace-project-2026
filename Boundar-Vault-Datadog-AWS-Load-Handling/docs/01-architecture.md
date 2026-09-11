# 01 — Architecture

## Why we use these components

| Component | Role | Why needed |
|---|---|---|
| HCP Boundary | Session control plane | Authorizes sessions and manages workers |
| Permanent Boundary worker | Baseline egress worker | Keeps target connectivity available even when ASG is at 0 |
| ASG Boundary worker | Temporary egress worker | Adds capacity when active sessions are high |
| HCP Vault | Secret store + SSH CA | Protects credentials and signs short-lived SSH certificates |
| BoundarySessionCounter | Session metric collector | Counts active Boundary sessions |
| Datadog | Monitor + decision layer | Decides when to scale out/in |
| DatadogBoundaryScalingRole | AWS authorization for Datadog | Lets Datadog call Auto Scaling APIs |
| AWS Auto Scaling Group | Compute lifecycle | Creates and terminates temporary Boundary workers |
| BoundaryWorkerCleanup | Cleanup automation | Removes stale HCP Boundary worker resources during scale-in |

## Scale-out

```text
Boundary active sessions >= 10
        ↓
BoundarySessionCounter
        ↓
boundary.active_sessions
        ↓
Datadog Scale-Out monitor
        ↓
Datadog workflow
        ↓
autoscaling:SetDesiredCapacity
        ↓
ASG Desired = 1
```

## Scale-in

```text
Boundary active sessions < 10 for 3 minutes
        ↓
Datadog Scale-In monitor
        ↓
Datadog workflow
        ↓
ASG Desired = 0
        ↓
Lifecycle Hook
        ↓
EventBridge
        ↓
BoundaryWorkerCleanup
        ↓
Delete matching Boundary worker
        ↓
CompleteLifecycleAction
```
