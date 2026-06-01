#!/bin/bash
# ---------------------------------------------------------------
# Non-stop load generator using hey
# Only hits the 3 routed endpoints (as per Kong HTTPRoute config)
#   /retail-banking/customer-profile-svc  → john token
#   /payments/transactions                → steve token
#   /grc/audits                           → messi token
# ---------------------------------------------------------------

KONG_IP="172.18.255.190"
KEYCLOAK_URL="http://keycloak.hellocloud.io:8080"
CONCURRENCY=300

get_token() {
  curl -s -X POST "$KEYCLOAK_URL/realms/hellocloudbank/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$1&client_secret=$2&username=$3&password=$4&grant_type=password" \
    | jq -r '.access_token'
}

fetch_tokens() {
  echo "Fetching tokens..."
  JOHN_TOKEN=$(get_token     retail-banking-client c9bI4S3HAcB9LYaJES241py61Wc5Ues1 john  john123)
  MESSI_TOKEN=$(get_token    grc-client            d3PFwfYOzTfCOqyMeUBAbMwM25XZPvtq messi messi123)
  PAYMENTS_TOKEN=$(get_token payments-client       KkCk1GmVTmNADrr0Qy2LjlTiQWghUOMR steve steve123)

  [[ "$JOHN_TOKEN"     == "null" || -z "$JOHN_TOKEN"     ]] && echo "ERROR: john token failed"     && exit 1
  [[ "$MESSI_TOKEN"    == "null" || -z "$MESSI_TOKEN"    ]] && echo "ERROR: messi token failed"    && exit 1
  [[ "$PAYMENTS_TOKEN" == "null" || -z "$PAYMENTS_TOKEN" ]] && echo "ERROR: payments token failed" && exit 1
  echo "Tokens OK."
}

verify_endpoints() {
  echo ""
  echo "Verifying endpoints..."
  printf "%-55s %s\n" ENDPOINT STATUS
  echo "-----------------------------------------------------------"

  check() {
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Host: finance.hellocloud.io" \
      -H "Authorization: Bearer $2" \
      "http://$KONG_IP$1")
    printf "%-55s HTTP %s\n" "$1" "$code"
    [[ "$code" == "200" ]]
  }

  local all_ok=true
  check /retail-banking/customer-profile-svc "$JOHN_TOKEN"     || all_ok=false
  check /payments/transactions               "$PAYMENTS_TOKEN" || all_ok=false
  check /grc/audits                          "$MESSI_TOKEN"    || all_ok=false

  echo ""
  if $all_ok; then
    echo "All endpoints OK. Starting load test..."
  else
    echo "Some endpoints failed. Fix above errors before running load."
    exit 1
  fi
}

run_worker() {
  local url=$1 token=$2
  while true; do
    hey -n 10000 -c $CONCURRENCY \
      -H "Host: finance.hellocloud.io" \
      -H "Authorization: Bearer $token" \
      "http://$KONG_IP$url" > /dev/null 2>&1
  done
}

start_workers() {
  run_worker /retail-banking/customer-profile-svc "$JOHN_TOKEN"     &
  run_worker /payments/transactions               "$PAYMENTS_TOKEN" &
  run_worker /grc/audits                          "$MESSI_TOKEN"    &
  echo "3 workers started ($CONCURRENCY concurrent each = $((CONCURRENCY * 3)) total connections)"
}

stop_workers() {
  kill $(jobs -p) 2>/dev/null
  wait 2>/dev/null
}

trap 'echo ""; echo "Stopping..."; stop_workers; exit 0' INT

fetch_tokens
verify_endpoints
start_workers

echo "Press Ctrl+C to stop."
echo ""

# Refresh tokens every 55 min and restart workers
while true; do
  sleep 3300
  echo "Refreshing tokens..."
  stop_workers
  fetch_tokens
  start_workers
done


#watch -n 3 "kubectl top pods -A | grep -E 'NAMESPACE|retail-banking-team|payments-team|grc-team'; echo; kubectl get hpa -A | grep -E 'NAMESPACE|retail-banking-team|payments-team|grc-team'"
