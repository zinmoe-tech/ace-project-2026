#!/bin/bash
# ---------------------------------------------------------------
# Non-stop load generator — runs until Ctrl+C
# Sends traffic to all 3 namespaces simultaneously
# ---------------------------------------------------------------

KONG_IP="172.18.255.190"

echo "Fetching tokens..."

JOHN_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=retail-banking-client&client_secret=c9bI4S3HAcB9LYaJES241py61Wc5Ues1&username=john&password=john123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

MESSI_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=grc-client&client_secret=d3PFwfYOzTfCOqyMeUBAbMwM25XZPvtq&username=messi&password=messi123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

PAYMENTS_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=payments-client&client_secret=KkCk1GmVTmNADrr0Qy2LjlTiQWghUOMR&username=steve&password=steve123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo "Tokens ready. Starting non-stop traffic. Press Ctrl+C to stop."
echo ""

ROUND=0
while true; do
  ROUND=$((ROUND+1))
  echo -ne "\rRound $ROUND — sending 90 parallel requests..."

  # retail-banking
  for i in $(seq 1 30); do
    curl -s -o /dev/null \
      -H "Host: finance.hellocloud.io" \
      -H "Authorization: Bearer $JOHN_TOKEN" \
      http://$KONG_IP/retail-banking/customer-profile-svc &
  done

  # payments
  for i in $(seq 1 30); do
    curl -s -o /dev/null \
      -H "Host: finance.hellocloud.io" \
      -H "Authorization: Bearer $PAYMENTS_TOKEN" \
      http://$KONG_IP/payments/transactions &
  done

  # grc
  for i in $(seq 1 30); do
    curl -s -o /dev/null \
      -H "Host: finance.hellocloud.io" \
      -H "Authorization: Bearer $MESSI_TOKEN" \
      http://$KONG_IP/grc/audits &
  done

  # Refresh tokens every 50 rounds (~every 50 iterations)
  if [ $((ROUND % 50)) -eq 0 ]; then
    echo ""
    echo "Refreshing tokens..."
    JOHN_TOKEN=$(curl -s -X POST \
      http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=retail-banking-client&client_secret=c9bI4S3HAcB9LYaJES241py61Wc5Ues1&username=john&password=john123&grant_type=password" \
      | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
    MESSI_TOKEN=$(curl -s -X POST \
      http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=grc-client&client_secret=d3PFwfYOzTfCOqyMeUBAbMwM25XZPvtq&username=messi&password=messi123&grant_type=password" \
      | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
    PAYMENTS_TOKEN=$(curl -s -X POST \
      http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=payments-client&client_secret=KkCk1GmVTmNADrr0Qy2LjlTiQWghUOMR&username=steve&password=steve123&grant_type=password" \
      | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
  fi
done
