# Step 1: Get the token

JOHN_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=retail-banking-client&client_secret=c9bI4S3HAcB9LYaJES241py61Wc5Ues1&username=john&password=john123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

STEVE_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=retail-banking-client&client_secret=c9bI4S3HAcB9LYaJES241py61Wc5Ues1&username=steve&password=steve123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo $JOHN_TOKEN | head -c 50

# Step 2: Decode and print all keys

echo $RETAIL_TOKEN | cut -d'.' -f2 | python3 -c "
import sys,base64,json
p=sys.stdin.read().strip()
p+='='*(4-len(p)%4)
print(json.dumps(json.loads(base64.urlsafe_b64decode(p)), indent=2))
"
### Output
import sys,base64,json
p=sys.stdin.read().strip()
p+='='*(4-len(p)%4)
print(json.dumps(json.loads(base64.urlsafe_b64decode(p)), indent=2))
"
{
  "exp": 1780045125,
  "iat": 1780044825,
  "jti": "2c7db79f-d7a9-45d9-bf07-ec73a50d226e",
  "iss": "http://keycloak.hellocloud.io:8080/realms/hellocloudbank",
  "aud": "account",
  "sub": "27b06539-cf32-4445-98c4-19ec11868c02",
  "typ": "Bearer",
  "azp": "retail-banking-client",
  "sid": "0deac03e-f3d3-4d36-a8e4-ee11d1ad6b44",
  "acr": "1",
  "allowed-origins": [
    "/*"
  ],
  "realm_access": {
    "roles": [
      "offline_access",
      "default-roles-hellocloudbank",
      "uma_authorization",
      "retail-banking-user"
    ]
  },
  "resource_access": {
    "account": {
      "roles": [
        "manage-account",
        "manage-account-links",
        "view-profile"
      ]
    }
  },
  "scope": "profile email",
  "email_verified": true,
  "name": "Alice Smith",
  "preferred_username": "alice",
  "given_name": "Alice",
  "family_name": "Smith",
  "email": "alice@hellocloudbank.com"
}

So,
key : 	request.auth.claims[preferred_username]
value : alice

MESSI_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=grc-client&client_secret=0ba4aYlQdo7JwTLnFtp8eKnc5wpLL5ER&username=messi&password=messi123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

ADMIN_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-client&client_secret=fHOjQPS22PxfZUSymymH8hbfroxYBijg&username=admin-user&password=admin123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo $ADMIN_TOKEN | head -c 30


curl -s -o /dev/null -w "HTTP: %{http_code}\n" \
  -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $FELIX_TOKEN" \
  http://172.18.255.190/payments/transactions


curl -s -o /dev/null -w "HTTP: %{http_code}\n" \
  -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://172.18.255.190/retail-banking/customer-profile-svc

curl -s -o /dev/null -w "HTTP: %{http_code}\n" \
  -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $MESSI_TOKEN" \
  http://172.18.255.190/grc/audits

# NOTE: Add Group Membership Mapper to Keycloak Client
#
# Required so the "groups" claim appears in the JWT token.
# Without this, request.auth.claims[groups] will never match in AuthorizationPolicy.
#
# Steps:
#   1. Open http://keycloak.hellocloud.io:8080/admin
#   2. Login as admin / admin
#   3. Top-left dropdown → select realm: hellocloudbank
#   4. Left menu → Clients → retail-banking-client
#   5. Client Scopes tab → click "retail-banking-client-dedicated"
#   6. Mappers tab → Configure a new mapper → Group Membership
#   7. Fill in:
#        Name            : groups          ← must be "groups" (not "retail-group")
#        Token Claim Name: groups          ← must be "groups" (this is the JWT key)
#        Full group path : OFF
#        Add to access token: ON
#   8. Save
#
# Then assign the user to a group:
#   1. Left menu → Users → <username>
#   2. Groups tab → Join Group → select the group (e.g. retail-group)
#
# Verify the groups claim appears in the token:
#   echo $RETAIL_TOKEN | cut -d'.' -f2 | python3 -c "
#   import sys,base64,json
#   p=sys.stdin.read().strip()
#   p+='='*(4-len(p)%4)
#   d=json.loads(base64.urlsafe_b64decode(p))
#   print('groups:', d.get('groups', 'MISSING - mapper not configured'))
#   "
#   Expected: groups: ['retail-group']

# How to check token lifetime

echo $RETAIL_TOKEN | cut -d'.' -f2 | python3 -c "
import sys,base64,json,datetime
p=sys.stdin.read().strip()
p+='='*(4-len(p)%4)
d=json.loads(base64.urlsafe_b64decode(p))
iat=datetime.datetime.fromtimestamp(d['iat'])
exp=datetime.datetime.fromtimestamp(d['exp'])
print(f'Issued at : {iat}')
print(f'Expires at: {exp}')
print(f'Lifetime  : {d[\"exp\"]-d[\"iat\"]} seconds')
"
