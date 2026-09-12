#!/usr/bin/env bash
set -euo pipefail

aws lambda add-permission \
  --function-name BoundaryWorkerCleanup \
  --statement-id AllowEventBridgeBoundaryWorkerCleanup \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:us-east-1:691914216603:rule/boundary-worker-termination-cleanup \
  --region us-east-1
