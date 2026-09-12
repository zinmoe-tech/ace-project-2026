#!/usr/bin/env bash
set -euo pipefail

aws autoscaling describe-auto-scaling-groups \
  --region us-east-1 \
  --auto-scaling-group-names boundary-worker-auto-scaling-group \
  --query 'AutoScalingGroups[0].{Min:MinSize,Desired:DesiredCapacity,Max:MaxSize,Instances:Instances[*].[InstanceId,LifecycleState,HealthStatus]}' \
  --output json
