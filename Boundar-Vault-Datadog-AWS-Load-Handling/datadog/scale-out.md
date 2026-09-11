# Scale-Out Workflow

Monitor:

```text
boundary.active_sessions{service:hcp-boundary} > 9
```

Action:

```text
AWS Autoscaling
Region: <AWS_REGION>
ASG: boundary-worker-auto-scaling-group
Desired Capacity: 1
```
