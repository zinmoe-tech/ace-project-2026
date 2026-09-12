#!/usr/bin/env bash
set -euo pipefail

aws lambda add-permission \
  --function-name BoundarySessionCounter \
  --statement-id AllowEventBridgeSessionCounter \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:us-east-1:691914216603:rule/boundary-session-counter-every-minute \
  --region us-east-1
