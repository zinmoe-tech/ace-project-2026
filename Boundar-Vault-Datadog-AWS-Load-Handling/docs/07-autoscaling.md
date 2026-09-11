# 07 — AWS Auto Scaling

## Why ASG is used

The ASG manages temporary Boundary worker compute.

Recommended PoC:

```text
Min: 0
Desired: 0
Max: 2 or 3
```

Scaling:

```text
>=10 sessions → Desired = 1
<10 sessions for 3 minutes → Desired = 0
```

## Why desired-state scaling

It is idempotent:

```text
0 → 1
1 → 1
1 → 1
```

and:

```text
1 → 0
0 → 0
```

## Launch Template

Include:
- private subnet
- no public IP
- `BoundaryWorkerRole`
- worker security group
- Boundary installed
- worker HCL
- registration bootstrap
- unique worker name `aws-asg-<instance-id>`

## Network

```text
Worker → HCP Boundary  TCP 9202
Worker → HCP Vault     TCP 8200
Worker → SSH Target    TCP 22
```
