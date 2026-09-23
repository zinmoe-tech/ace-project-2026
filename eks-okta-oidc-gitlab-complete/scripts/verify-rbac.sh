#!/usr/bin/env bash
set -euo pipefail
kubectl config current-context
kubectl auth can-i get pods -n developers-team
kubectl auth can-i create pods -n developers-team
kubectl auth can-i get pods -n default
kubectl auth can-i get nodes
