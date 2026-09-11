# ASG Settings

```text
Name: boundary-worker-auto-scaling-group
Min: 0
Desired: 0
Max: 2 or 3
```

Lifecycle hook:

```text
Name: boundary-worker-terminate-cleanup
Transition: autoscaling:EC2_INSTANCE_TERMINATING
Heartbeat timeout: 120
Default result: CONTINUE
```
