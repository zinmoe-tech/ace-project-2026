#!/usr/bin/env bash
set -euo pipefail

RULE="boundary-worker-termination-cleanup"
REGION="us-east-1"
TARGET_ID="1"
LAMBDA_ARN="arn:aws:lambda:us-east-1:691914216603:function:BoundaryWorkerCleanup"

aws events remove-targets \
  --rule "$RULE" \
  --ids "$TARGET_ID" \
  --region "$REGION"

aws events put-targets \
  --rule "$RULE" \
  --region "$REGION" \
  --targets "Id=$TARGET_ID,Arn=$LAMBDA_ARN"

aws events list-targets-by-rule \
  --rule "$RULE" \
  --region "$REGION"

cat <<'MSG'
Verify the output has NO RoleArn.
EventBridge invokes BoundaryWorkerCleanup via the Lambda resource-based policy.
MSG
