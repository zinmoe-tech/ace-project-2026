# Boundary + Vault + Datadog + AWS Load Handling

This repository documents a working proof of concept for automatically scaling self-managed HCP Boundary workers on AWS based on active Boundary session count, while using HCP Vault for secrets and Datadog for monitoring and automation.

> **Folder name:** `Boundary-Vault-Datadog-AWS-Load-Handling`

---

# 1. What this project solves

## Why we need it

A fixed number of Boundary workers can become a bottleneck when many users open sessions at the same time. At the same time, keeping many workers running all day wastes compute cost.

This project keeps one permanent Boundary worker running and creates a temporary AWS worker only when session load is high.

## Target behavior

```text
Boundary active sessions >= 10
        ↓
Datadog Scale-Out Monitor
        ↓
Datadog Workflow
        ↓
BoundaryWorkerScaler Lambda
        ↓
ASG Desired Capacity = 1
        ↓
New EC2 Boundary worker
```

```text
Boundary active sessions < 10 for 3 minutes
        ↓
Datadog Scale-In Monitor
        ↓
Datadog Workflow
        ↓
BoundaryWorkerScaler Lambda
        ↓
ASG Desired Capacity = 0
        ↓
Termination Lifecycle Hook
        ↓
EventBridge
        ↓
BoundaryWorkerCleanup Lambda
        ↓
Delete matching worker from HCP Boundary
        ↓
EC2 termination completes
```

---

# 2. Component responsibilities

## Why we separate the components

Each component should have one clear responsibility. This makes troubleshooting easier and reduces IAM permissions.

| Component | Responsibility | Why needed |
|---|---|---|
| HCP Boundary | Session broker and worker control plane | Provides secure access to targets |
| Permanent worker | Always-on egress worker | Guarantees baseline connectivity |
| ASG worker | Temporary worker | Adds capacity only during high load |
| HCP Vault | Secret storage and AWS IAM authentication | Keeps passwords and API keys out of code |
| BoundarySessionCounter | Counts active Boundary sessions | Produces the metric used for scaling |
| Datadog | Stores metric and evaluates thresholds | Decides when to scale out or in |
| BoundaryWorkerScaler | Changes ASG Desired Capacity | Performs the AWS scaling action |
| ASG lifecycle hook | Pauses EC2 termination | Gives cleanup Lambda time to delete worker record |
| EventBridge | Detects ASG termination lifecycle event | Invokes cleanup automatically |
| BoundaryWorkerCleanup | Deletes stale HCP Boundary worker | Keeps Boundary worker inventory clean |

---

# 3. Repository layout

```text
Boundary-Vault-Datadog-AWS-Load-Handling/
│
├── README.md
├── docs/
│   └── architecture.md
├── boundary/
│   └── worker-config-example.hcl
├── vault/
│   └── policies/
├── aws/
│   ├── iam/
│   ├── eventbridge/
│   └── autoscaling/
├── lambda/
│   ├── BoundarySessionCounter/
│   ├── BoundaryWorkerScaler/
│   └── BoundaryWorkerCleanup/
├── datadog/
└── tests/
```

---

# 4. Prerequisites

## Why these are needed

Before autoscaling can work, the underlying Boundary, Vault, AWS and Datadog connectivity must already work.

Prepare:

- HCP Boundary cluster
- HCP Vault cluster
- AWS VPC with private subnet
- NAT or equivalent HTTPS egress
- one permanent self-managed Boundary worker
- one SSH target
- Boundary password auth method
- Vault AWS auth enabled
- Datadog organization
- AWS Lambda and Auto Scaling permissions
- working worker-to-target TCP connectivity

Required outbound paths:

```text
Boundary worker → HCP Boundary        TCP 9202
Boundary worker → HCP Vault           TCP 8200
Boundary worker → target              TCP 22
Lambda → HCP Boundary API             TCP 443
Lambda → HCP Vault private endpoint   TCP 8200
Lambda → Datadog API                  TCP 443
Lambda → AWS APIs                     TCP 443
```

---

# 5. Permanent Boundary worker

## Why we need it

The ASG minimum is allowed to be `0`. Therefore at least one worker should remain outside the ASG so Boundary still has a stable worker when load is low.

## Recommended design

```text
Permanent worker
- always running
- outside ASG
- used for normal traffic
- can reach Vault
- can reach targets
```

Example tags:

```hcl
tags {
  type       = ["egress"]
  cloud      = ["aws"]
  target     = ["on-aws"]
  cred-store = ["vault"]
}
```

Example direct HCP worker configuration:

```hcl
disable_mlock = true

hcp_boundary_cluster_id = "<HCP_BOUNDARY_CLUSTER_ID>"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  auth_storage_path = "/var/lib/boundary"
}

tags {
  type       = ["egress"]
  cloud      = ["aws"]
  target     = ["on-aws"]
  cred-store = ["vault"]
}
```

Verify:

```bash
sudo systemctl status boundary-worker --no-pager -l
```

Watch traffic:

```bash
sudo journalctl -u boundary-worker -f -o cat
```

---

# 6. HCP Vault secret design

## Why we need Vault

Lambda and EC2 must not contain hard-coded Boundary passwords or Datadog API keys.

Use Vault KV v2 paths such as:

```text
boundary-registration/asg-worker
boundary-registration/session-monitor
boundary-registration/datadog-metrics
boundary-registration/worker-cleanup
```

Suggested fields:

```text
asg-worker:
  login_name
  password

session-monitor:
  login_name
  password

datadog-metrics:
  api_key

worker-cleanup:
  login_name
  password
```

Never commit actual values to GitHub.

---

# 7. Vault policies

## Why separate policies

Each workload should be able to read only the secret it needs.

### ASG worker

```hcl
path "boundary-registration/data/asg-worker" {
  capabilities = ["read"]
}
```

### Session counter Lambda

```hcl
path "boundary-registration/data/session-monitor" {
  capabilities = ["read"]
}

path "boundary-registration/data/datadog-metrics" {
  capabilities = ["read"]
}
```

### Worker cleanup Lambda

```hcl
path "boundary-registration/data/worker-cleanup" {
  capabilities = ["read"]
}
```

Apply with:

```bash
vault policy write <POLICY_NAME> <POLICY_FILE>.hcl
```

---

# 8. Vault AWS IAM authentication

## Why we need it

EC2 and Lambda can authenticate to Vault using their AWS IAM identities instead of storing a long-lived Vault token.

Example:

```bash
vault write auth/aws/role/boundary-worker-cleanup \
  auth_type=iam \
  bound_iam_principal_arn="arn:aws:iam::<AWS_ACCOUNT_ID>:role/<ROLE_NAME>" \
  policies="boundary-worker-cleanup" \
  ttl=15m \
  max_ttl=30m \
  resolve_aws_unique_ids=false
```

Verify:

```bash
vault read auth/aws/role/boundary-worker-cleanup
```

---

# 9. Boundary identities and RBAC

## 9.1 ASG worker registration identity

### Why needed

A new ASG instance needs permission to register itself as a worker.

Required worker-led creation grant:

```text
type=worker;actions=create:worker-led
```

Store that account in:

```text
boundary-registration/asg-worker
```

## 9.2 Session monitor identity

### Why needed

`BoundarySessionCounter` needs read-only session access but should not have admin permissions.

Grant:

```text
ids=*;type=session;actions=list,read
```

Store the credentials in:

```text
boundary-registration/session-monitor
```

## 9.3 Worker cleanup identity

### Why needed

`BoundaryWorkerCleanup` must list and delete temporary workers.

Grant:

```text
type=worker;actions=list
ids=*;type=worker;actions=read,delete
```

Store the credentials in:

```text
boundary-registration/worker-cleanup
```

---

# 10. AWS Launch Template

## Why we need it

The ASG must be able to create an identical Boundary worker automatically.

Configure:

```text
Launch template name: autoscaling-worker-template
Network: private subnet
Public IP: disabled
IAM instance profile: BoundaryWorkerRole
Security group: Boundary worker security group
User Data: worker bootstrap and registration
```

The User Data should:

```text
1. install Boundary
2. write worker HCL
3. start boundary-worker.service
4. obtain auth_request_token
5. authenticate to Vault using IAM
6. read Boundary registration account
7. authenticate to Boundary
8. register worker-led
9. name it aws-asg-<INSTANCE_ID>
10. remove/unset temporary secret variables
```

Use a unique name:

```text
aws-asg-i-0123456789abcdef0
```

This name is critical for automatic cleanup later.

---

# 11. AWS Auto Scaling Group

## Why we need it

The ASG creates and terminates temporary Boundary worker EC2 instances.

Recommended PoC settings:

```text
ASG name: boundary-worker-auto-scaling-group

Min:     0
Desired: 0
Max:     3
```

Current scaling model:

```text
10+ sessions → Desired = 1
<10 sessions for 3 minutes → Desired = 0
```

The permanent worker remains outside the ASG.

---

# 12. BoundarySessionCounter Lambda

## Why we need it

Datadog does not know the current Boundary active-session count by itself. This Lambda queries Boundary once per minute and sends the value directly to Datadog.

It should **not** change ASG capacity.

Flow:

```text
EventBridge every minute
        ↓
BoundarySessionCounter
        ↓
Vault AWS IAM login
        ↓
read Boundary monitor credentials
        ↓
Boundary API
        ↓
count status == active
        ↓
read Datadog API key from Vault
        ↓
Datadog Metrics API
```

Metric:

```text
boundary.active_sessions
```

Metric type:

```text
Gauge
```

Tag/resource:

```text
service:hcp-boundary
```

Recommended EventBridge schedule:

```text
rate(1 minute)
```

---

# 13. Datadog metric validation

## Why validate before monitors

A monitor cannot scale anything if the metric is missing or stale.

Go to:

```text
Datadog → Metrics → Explorer
```

Select:

```text
boundary.active_sessions
```

Verify that recent values appear.

Also check:

```text
Datadog → Metrics → Summary
```

Expected:

```text
Metric Type: Gauge
```

---

# 14. Scale-Out Datadog monitor

## Why we need it

This monitor converts the metric threshold into a scaling decision.

Name:

```text
Boundary Active Sessions - Scale Out
```

Configure:

```text
Metric: boundary.active_sessions
Filter: service:hcp-boundary
Group by: none
Threshold: above 9
```

Meaning:

```text
10 or more sessions → ALERT
```

Attach workflow:

```text
Boundary-Worker-Scale-Out
```

---

# 15. Scale-Out Datadog workflow

## Why we need it

The monitor detects the condition, but the workflow performs the AWS action.

Action:

```text
Invoke AWS Lambda
```

Function:

```text
BoundaryWorkerScaler
```

Payload:

```json
{
  "action": "scale_out"
}
```

Publish the workflow.

---

# 16. Scale-In Datadog monitor

## Why we need it

Scaling in immediately at `9` sessions can cause frequent create/delete cycles. We therefore require load to stay below the threshold for a period.

Name:

```text
Boundary Active Sessions - Scale In
```

Configure:

```text
Metric: boundary.active_sessions
Filter: service:hcp-boundary
Group by: none
Evaluation: MAXIMUM over last 3 minutes
Condition: below 10
```

Why `MAXIMUM`:

```text
8, 7, 6
MAX = 8
8 < 10
→ scale in
```

but:

```text
8, 10, 7
MAX = 10
10 < 10 = false
→ do not scale in
```

Attach:

```text
Boundary-Worker-Scale-In
```

---

# 17. Scale-In Datadog workflow

## Why we need it

This sends a separate explicit action to the scaler Lambda.

Payload:

```json
{
  "action": "scale_in"
}
```

Function:

```text
BoundaryWorkerScaler
```

Publish the workflow.

---

# 18. Datadog AWS connection

## Why we need it

Datadog needs permission to invoke the scaler Lambda.

Use a dedicated Datadog AWS connection and a dedicated IAM role.

Allow only:

```text
lambda:InvokeFunction
```

against:

```text
BoundaryWorkerScaler
```

Use the trust policy and External ID generated by Datadog.

---

# 19. BoundaryWorkerScaler Lambda

## Why we need it

Datadog should not directly manage ASG configuration. This Lambda is the controlled AWS-side scaling action.

Use idempotent behavior:

```text
scale_out → Desired = 1
scale_in  → Desired = 0
```

Why not `+1/-1`?

Repeated notifications could accidentally create multiple workers.

Desired-state logic is safer:

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

Required IAM actions:

```text
autoscaling:DescribeAutoScalingGroups
autoscaling:SetDesiredCapacity
```

The Lambda should retry when AWS returns:

```text
ScalingActivityInProgress
ResourceContention
```

Recommended timeout:

```text
2 minutes 30 seconds
```

---

# 20. Why Boundary worker cleanup is required

## Problem

When the ASG terminates an EC2 instance, HCP Boundary can retain the worker record.

That creates stale entries such as:

```text
aws-asg-i-oldinstance
Last Seen: old timestamp
```

Therefore EC2 termination and Boundary worker deletion must be coordinated.

---

# 21. ASG termination lifecycle hook

## Why we need it

Without a lifecycle hook, EC2 can terminate before cleanup finishes.

Create:

```text
Lifecycle hook name:
boundary-worker-terminate-cleanup

Transition:
Instance terminate

Heartbeat timeout:
120 seconds

Default result:
CONTINUE
```

During scale-in:

```text
EC2 → Terminating:Wait
```

This gives cleanup time.

---

# 22. EventBridge termination rule

## Why we need it

The lifecycle hook emits an Auto Scaling lifecycle event. EventBridge routes that event to the cleanup Lambda.

Rule name:

```text
boundary-worker-termination-cleanup
```

Event pattern:

```json
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance-terminate Lifecycle Action"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "boundary-worker-auto-scaling-group"
    ]
  }
}
```

Target:

```text
BoundaryWorkerCleanup
```

---

# 23. BoundaryWorkerCleanup Lambda

## Why we need it

This Lambda removes the exact Boundary worker that belongs to the EC2 instance AWS selected for termination.

Event example contains:

```text
EC2InstanceId
AutoScalingGroupName
LifecycleHookName
LifecycleActionToken
```

Worker lookup logic:

```text
EC2 instance:
i-0123456789abcdef0

Expected Boundary worker:
aws-asg-i-0123456789abcdef0
```

Cleanup flow:

```text
EventBridge
    ↓
BoundaryWorkerCleanup
    ↓
Vault AWS IAM login
    ↓
read worker-cleanup credentials
    ↓
Boundary login
    ↓
GET workers
    ↓
find exact aws-asg-<instance-id>
    ↓
DELETE worker
    ↓
CompleteLifecycleAction(CONTINUE)
```

Required IAM action:

```text
autoscaling:CompleteLifecycleAction
```

If Lambda runs in a VPC, also keep normal Lambda VPC ENI permissions and logging permissions.

---

# 24. Cleanup Lambda networking

## Why it needs VPC access

The cleanup Lambda reads credentials from the HCP Vault private endpoint.

Use the same working network pattern as `BoundarySessionCounter`.

Required paths:

```text
Lambda → Vault private endpoint   TCP 8200
Lambda → Boundary API             TCP 443
Lambda → AWS APIs                 TCP 443
```

---

# 25. End-to-end scale-out test

## Why we test manually

This confirms each component in order.

Start with:

```text
ASG Desired = 0
Boundary sessions < 10
Scale-Out monitor = OK
```

Create 10 sessions.

Windows CMD example:

```cmd
for /L %i in (1,1,10) do start "" /B cmd /c "boundary connect ssh -target-id=<TARGET_ID> -token env://BOUNDARY_TOKEN -- -N > %TEMP%\boundary-session-%i.log 2>&1"
```

Verify count:

```bash
boundary sessions list \
  -scope-id=global \
  -recursive \
  -format=json \
  -token env://BOUNDARY_TOKEN \
| jq '[.items // [] | .[] | select(.status == "active")] | length'
```

Expected:

```text
10+
```

Then verify:

```text
Datadog metric = 10+
Scale-Out monitor = ALERT
Workflow = Success
BoundaryWorkerScaler = invoked
ASG Desired 0 → 1
EC2 = InService
Boundary worker aws-asg-* appears
```

---

# 26. End-to-end scale-in test

Stop the Windows test sessions:

```cmd
taskkill /IM boundary.exe /F
```

Verify Boundary sessions drop below 10.

Wait at least 3 minutes.

Expected:

```text
Scale-In monitor = ALERT
Boundary-Worker-Scale-In = Success
BoundaryWorkerScaler = invoked
ASG Desired 1 → 0
EC2 enters Terminating:Wait
EventBridge invokes BoundaryWorkerCleanup
Boundary worker is deleted
Lifecycle action CONTINUE
EC2 terminates
```

---

# 27. Validation checklist

```text
[ ] permanent Boundary worker is running
[ ] ASG Min=0 Desired=0 Max=3
[ ] ASG worker registers with unique aws-asg-<instance-id> name
[ ] BoundarySessionCounter runs every minute
[ ] Datadog receives boundary.active_sessions
[ ] metric type is Gauge
[ ] scale-out monitor triggers at 10+
[ ] scale-out workflow invokes BoundaryWorkerScaler
[ ] ASG Desired changes 0 → 1
[ ] new EC2 becomes InService
[ ] new worker appears in Boundary
[ ] scale-in monitor requires <10 for 3 minutes
[ ] scale-in workflow invokes BoundaryWorkerScaler
[ ] ASG Desired changes 1 → 0
[ ] lifecycle hook enters Terminating:Wait
[ ] EventBridge invokes BoundaryWorkerCleanup
[ ] cleanup Lambda authenticates to Vault
[ ] cleanup Lambda authenticates to Boundary
[ ] matching aws-asg-* worker is deleted
[ ] CompleteLifecycleAction succeeds
[ ] EC2 termination completes
[ ] permanent worker remains running
```

---

# 28. Troubleshooting

## Datadog metric exists but monitor shows NO DATA

Check:

```text
Metrics → Explorer → boundary.active_sessions
```

Confirm recent points exist.

Check that `BoundarySessionCounter` runs every minute.

Avoid accidental tag filters or unnecessary rollups.

---

## Workflow works manually but not automatically

Check:

```text
Workflow = Published
Monitor = attached to workflow
Monitor actually transitions to ALERT
```

---

## Scaler Lambda returns `Missing action`

Correct test payload:

```json
{
  "action": "scale_out"
}
```

or:

```json
{
  "action": "scale_in"
}
```

---

## `ScalingActivityInProgress`

The ASG is still processing a previous action.

Use retry logic in `BoundaryWorkerScaler`.

---

## EC2 terminates but Boundary worker remains

Check:

```text
/aws/lambda/BoundaryWorkerCleanup
```

Confirm:

```text
EventBridge trigger fired
Vault auth succeeded
Boundary auth succeeded
worker name matched
DELETE succeeded
CompleteLifecycleAction succeeded
```

---

## Vault AWS IAM login returns HTTP 400

Verify:

```bash
vault read auth/aws/role/boundary-worker-cleanup
```

Check the IAM role ARN binding and the `resolve_aws_unique_ids` setting.

---

# 29. Security recommendations

Do not commit:

```text
Boundary tokens
Vault tokens
Datadog API keys
Boundary passwords
AWS keys
worker registration tokens
```

Use:

```text
Vault for secrets
AWS IAM roles for AWS authentication
least-privilege Boundary RBAC
least-privilege IAM policies
private subnets for workers
```

Rotate any secret that was ever exposed in plaintext.

---

# 30. Production improvements

The current project is a successful PoC. Before production:

```text
1. add graceful worker draining before termination
2. protect active sessions during scale-in
3. run workers across multiple Availability Zones
4. use larger EC2 types after load testing
5. add Lambda failure alarms
6. add dead-letter/retry handling
7. create a Datadog dashboard
8. migrate infrastructure to Terraform
9. define worker capacity per session load
10. document operational runbooks
```

A future multi-worker capacity policy could be:

```text
0–9 sessions    → 0 temporary workers
10–19 sessions  → 1 temporary worker
20–29 sessions  → 2 temporary workers
30+ sessions    → 3 temporary workers
```

---

# 31. Final architecture summary

```text
OBSERVE
BoundarySessionCounter
        ↓
boundary.active_sessions

DECIDE
Datadog
        ↓
Scale-Out / Scale-In monitor

ACT
BoundaryWorkerScaler
        ↓
AWS ASG

CLEAN
Lifecycle Hook
        ↓
EventBridge
        ↓
BoundaryWorkerCleanup

SECURE
HCP Vault
        ↓
runtime credentials and AWS IAM authentication
```

This separation is the key design principle of the project.
