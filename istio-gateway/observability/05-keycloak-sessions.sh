#!/bin/bash
# ---------------------------------------------------------------
# Keycloak Live Session Monitor
# Shows who is currently logged in and active sessions per client
# ---------------------------------------------------------------

KEYCLOAK_URL="http://keycloak.hellocloud.io:8080"
REALM="hellocloudbank"

# Step 1: Get admin token from master realm
ADMIN_TOKEN=$(curl -s -X POST \
  "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli&username=admin&password=admin&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo "===================================================="
echo "  HelloCloudBank — Active Keycloak Sessions"
echo "===================================================="

# Step 2: Total active sessions in the realm
echo ""
echo "[1] Realm Session Stats:"
curl -s \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  "$KEYCLOAK_URL/admin/realms/$REALM/client-session-stats" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
for c in data:
    if c.get('activeSessions', 0) > 0:
        print(f\"  Client: {c.get('clientId','?'):35s}  Active Sessions: {c.get('activeSessions',0)}\")
"

# Step 3: Active user sessions per client
for CLIENT in retail-banking-client payments-client grc-client admin-client; do
  echo ""
  echo "[2] Active users — $CLIENT:"

  # Get client UUID
  CLIENT_ID=$(curl -s \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=$CLIENT" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id']) if d else print('')")

  if [ -z "$CLIENT_ID" ]; then
    echo "  (client not found)"
    continue
  fi

  # Get active sessions for this client
  curl -s \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    "$KEYCLOAK_URL/admin/realms/$REALM/clients/$CLIENT_ID/user-sessions" \
    | python3 -c "
import sys, json
sessions = json.load(sys.stdin)
if not sessions:
    print('  No active sessions')
else:
    for s in sessions:
        username = s.get('username', '?')
        ip_addr  = s.get('ipAddress', '?')
        started  = s.get('start', 0)
        import datetime
        ts = datetime.datetime.fromtimestamp(started/1000).strftime('%H:%M:%S')
        print(f'  User: {username:20s}  IP: {ip_addr:15s}  Started: {ts}')
"
done

echo ""
echo "===================================================="
echo "  Run again to refresh — sessions expire after 1h"
echo "===================================================="
