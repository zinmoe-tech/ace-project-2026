# Scale-In Workflow

Monitor:

```text
MAX(boundary.active_sessions{service:hcp-boundary}) over 3 minutes < 10
```

Action:

```text
AWS Autoscaling
Region: <AWS_REGION>
ASG: boundary-worker-auto-scaling-group
Desired Capacity: 0
```
