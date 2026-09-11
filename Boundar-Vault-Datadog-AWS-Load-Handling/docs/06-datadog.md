# 06 — Datadog

## Why Datadog is used

Datadog is the decision layer.

The Lambda only publishes:

```text
boundary.active_sessions
```

Datadog decides when to scale and calls AWS Auto Scaling directly.

## Scale-Out Monitor

```text
Metric: boundary.active_sessions
Filter: service:hcp-boundary
Condition: > 9
```

Meaning:

```text
10 or more active sessions
→ Scale Out
```

Workflow action:

```text
AWS Autoscaling
→ Set desired capacity
→ Desired = 1
```

## Scale-In Monitor

```text
Metric: boundary.active_sessions
Filter: service:hcp-boundary
Evaluation: MAX over last 3 minutes
Condition: below 10
```

Why MAX:

```text
8,7,6
MAX=8
→ all three minutes below 10
```

but:

```text
8,10,7
MAX=10
→ do not scale in
```

Workflow action:

```text
AWS Autoscaling
→ Set desired capacity
→ Desired = 0
```

## Important

Do not use `Describe auto scaling group` as the only action. It is read-only.

Use `Set desired capacity`.
