#!/usr/bin/env bash
set -euo pipefail

# Auto-registers a dedicated Boundary target for every VM the fleet host
# catalog has discovered but that doesn't have one yet.
#
# Why this script exists: Boundary's dynamic host catalogs only sync HOSTS
# into a host-set automatically (see boundary_linux_target_fleet.tf) — they
# never create TARGETS on their own. Targets encode session policy (worker
# filters, injected credentials, connection limits), and nothing in
# Boundary's plugin model turns "a host showed up" into "create a target"
# for it. This script is that missing piece, run by hand or on a schedule.
#
# Safe to re-run: it skips any VM that already has a "<vm-name>-fleet-ssh"
# target, and never touches linux-target-01..04's dedicated targets or the
# shared linux-target-fleet-ssh-tf target — purely additive.
#
# Requires: az (logged in with write access to linux-target-rsg — NOT the
# Reader-only discovery service principal), boundary (BOUNDARY_ADDR +
# BOUNDARY_TOKEN exported), jq, and running from this repo root so
# `terraform state show` can resolve the shared SSH credential id.

FLEET_CATALOG_ID="hcplg_RDXubbEZY3"
SCOPE_ID="p_U2TGvduNzc"
RESOURCE_GROUP="linux-target-rsg"
INGRESS_FILTER='"ingress-worker" in "/tags/type"'
EGRESS_FILTER='"egress-worker" in "/tags/type"'

# Same SSH credential every linux-target VM uses (boundary_credentials.tf) —
# read from Terraform state so it's never hardcoded/stale here.
CRED_ID=$(terraform state show boundary_credential_ssh_private_key.linux_target_key 2>/dev/null \
  | awk -F'"' '/^    id / {print $2; exit}')

if [[ -z "${CRED_ID:-}" ]]; then
  echo "Could not resolve the SSH credential id from Terraform state." >&2
  echo "Run this from the repo root, with state present." >&2
  exit 1
fi

echo "Fleet catalog : $FLEET_CATALOG_ID"
echo "SSH credential: $CRED_ID"
echo

mapfile -t HOSTS < <(
  boundary hosts list -host-catalog-id "$FLEET_CATALOG_ID" -format json \
    | jq -r '.items[] | "\(.id)|\(.name)"'
)

mapfile -t EXISTING_TARGETS < <(
  boundary targets list -recursive -scope-id "$SCOPE_ID" -format json \
    | jq -r '.items[].name'
)

target_exists() {
  local name="$1"
  for t in "${EXISTING_TARGETS[@]}"; do
    [[ "$t" == "$name" ]] && return 0
  done
  return 1
}

if [[ ${#HOSTS[@]} -eq 0 ]]; then
  echo "No hosts discovered under the fleet catalog yet — nothing to do."
  echo "(Dynamic catalogs sync on an interval; if a VM was just created, this can be empty for a bit.)"
  exit 0
fi

for entry in "${HOSTS[@]}"; do
  vm_name="${entry##*|}"
  target_name="${vm_name}-fleet-ssh"

  if target_exists "$target_name"; then
    echo "skip  $vm_name — $target_name already exists"
    continue
  fi

  echo "new   $vm_name — creating $target_name"

  # Per-VM tag so this host can be isolated into its own host-set filter,
  # distinct from the broad boundary_fleet=linux-target tag used for
  # general fleet discovery. --set on a single tags.KEY path merges in,
  # it doesn't wipe existing tags.
  az vm update \
    --resource-group "$RESOURCE_GROUP" \
    --name "$vm_name" \
    --set tags.boundary_host_name="$vm_name" \
    --output none

  hostset_id=$(boundary host-sets create plugin \
    -host-catalog-id "$FLEET_CATALOG_ID" \
    -name "${vm_name}-fleet-hostset" \
    -attr filter="tagName eq 'boundary_host_name' and tagValue eq '${vm_name}'" \
    -format json | jq -r '.item.id')

  target_id=$(boundary targets create ssh \
    -scope-id "$SCOPE_ID" \
    -name "$target_name" \
    -description "Auto-registered for $vm_name by fleet-auto-register.sh" \
    -default-port 22 \
    -session-connection-limit -1 \
    -ingress-worker-filter "$INGRESS_FILTER" \
    -egress-worker-filter "$EGRESS_FILTER" \
    -format json | jq -r '.item.id')

  boundary targets add-host-sources -id "$target_id" -host-source "$hostset_id" > /dev/null
  boundary targets add-credential-sources -id "$target_id" -application-credential-source "$CRED_ID" > /dev/null

  echo "      -> target $target_id  (host-set $hostset_id)"
done

echo
echo "Done. New tags take one sync interval to reflect in each new host-set."
