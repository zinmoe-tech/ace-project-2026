#!/usr/bin/env bash
set -euo pipefail

# packer build's -var/-var-file mechanism can't reach HCP Packer's registry
# auth: that auth is done by the HCP SDK reading HCP_CLIENT_ID /
# HCP_CLIENT_SECRET / HCP_PROJECT_ID from the process environment, before
# the template's own variables are evaluated. This script bridges that gap
# by reading the same values out of hcp.auto.pkrvars.hcl and exporting them,
# so the file stays the single source of truth and nothing needs sourcing
# by hand.

cd "$(dirname "$0")"

VARS_FILE="hcp.auto.pkrvars.hcl"

get_var() {
  grep -E "^${1}[[:space:]]*=" "$VARS_FILE" | sed -E 's/^[a-z_]+[[:space:]]*=[[:space:]]*"(.*)"[[:space:]]*$/\1/'
}

export HCP_PROJECT_ID
export HCP_CLIENT_ID
export HCP_CLIENT_SECRET
HCP_PROJECT_ID="$(get_var hcp_project_id)"
HCP_CLIENT_ID="$(get_var hcp_client_id)"
HCP_CLIENT_SECRET="$(get_var hcp_client_secret)"

packer build .