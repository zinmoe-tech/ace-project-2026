# 09 — Testing and Validation

## Test 1 — Create 10 sessions

```bash
for i in $(seq 1 10); do
  boundary connect ssh     -target-id="<TARGET_ID>"     -token env://BOUNDARY_TOKEN     -- -N >"/tmp/boundary-session-$i.log" 2>&1 &
  sleep 0.5
done
```

Check:

```bash
boundary sessions list   -scope-id=global   -recursive   -format=json   -token env://BOUNDARY_TOKEN | jq '[.items // [] | .[] | select(.status == "active")] | length'
```

Expected:

```text
10
```

## Test 2 — Session Counter

Expected logs:

```text
Vault AWS authentication successful
Boundary monitoring credentials retrieved from Vault
Datadog API key retrieved from Vault
Boundary authentication successful
Active Boundary sessions: 10
Published Datadog metric: boundary.active_sessions=10
```

## Test 3 — Scale-Out

Expected:

```text
Datadog monitor = ALERT
Workflow = Success
ASG Desired 0 → 1
EC2 = InService
Boundary worker appears
```

## Test 4 — Scale-In

Stop sessions:

```bash
pkill -f 'boundary connect ssh'
```

Wait 3+ minutes.

Expected:

```text
Datadog Scale-In = ALERT
ASG Desired 1 → 0
EC2 = Terminating:Wait
Cleanup Lambda executes
Boundary worker deleted
EC2 terminated
```

## Final checklist

```text
[ ] BoundarySessionCounter runs every minute
[ ] boundary.active_sessions is fresh in Datadog
[ ] Scale-Out monitor triggers at >=10
[ ] Scale-Out workflow uses Set desired capacity = 1
[ ] ASG worker registers successfully
[ ] Scale-In monitor requires <10 for 3 minutes
[ ] Scale-In workflow uses Set desired capacity = 0
[ ] lifecycle hook activates
[ ] EventBridge invokes cleanup Lambda
[ ] cleanup Lambda deletes matching Boundary worker
[ ] lifecycle action completes
[ ] permanent worker remains running
```
