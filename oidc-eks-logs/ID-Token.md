test@test:~$ kubectl oidc-login get-token \
  --oidc-issuer-url="https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698" \
  --oidc-client-id="0oa17n5mtdmEXDT8x698" \
  --oidc-extra-scope="profile" \
  --oidc-extra-scope="email" \
  --grant-type=authcode
Gtk-Message: 11:25:41.011: Not loading module "atk-bridge": The functionality is provided by GTK natively. Please try to not load it.
{"kind":"ExecCredential","apiVersion":"client.authentication.k8s.io/v1beta1","spec":{"interactive":false},"status":{"expirationTimestamp":"2026-09-18T08:25:42Z","token":"eyJraWQiOiJvRGx5UjdrVmNUMFY2MnNnamdOeW44TGJvRC1wU29wb1ZmV1BScURiNWdBIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHUxN3BnY3F5b3lpTm1kTDY5OCIsIm5hbWUiOiJkZXZlbG9wZXItbWVtYmVyIDAxIiwiZW1haWwiOiJwcm9vZnRoZW9yeTVAZ21haWwuY29tIiwidmVyIjoxLCJpc3MiOiJodHRwczovL3RyaWFsLTYwOTU5NjEub2t0YS5jb20vb2F1dGgyL2F1czE3b2xlNzJsM2d2OFJSNjk4IiwiYXVkIjoiMG9hMTduNW10ZG1FWERUOHg2OTgiLCJpYXQiOjE3ODk3MTYzNDIsImV4cCI6MTc4OTcxOTk0MiwianRpIjoiSUQuQVQ0eWlBQ19DV2xUNzNUNERhbXJIdnVIek5aNUZzdFRvb0o2cFc3T0FSRSIsImFtciI6WyJtZmEiLCJvdHAiLCJwd2QiLCJva3RhX3ZlcmlmeSJdLCJpZHAiOiIwMG8xN2xuNW1mMzVveE85bDY5OCIsIm5vbmNlIjoiMURMWnpaN280bWN5dUJheXhPTmNuT0IxWFZRY1QzR0V6U21SVmFESWx5RSIsInByZWZlcnJlZF91c2VybmFtZSI6InByb29mdGhlb3J5NUBnbWFpbC5jb20iLCJhdXRoX3RpbWUiOjE3ODk3MTQ0MTksImF0X2hhc2giOiJYdGswRS1sUXdLbWZkZHFqTWp0SUt3IiwiZWtzX2dyb3VwcyI6WyJla3MtZGV2ZWxvcGVycyJdfQ.LAr2T1j98iDTs6xwFHdVUmfZc1_p-UWc0gy3hVfltt-daXGQUjBW8Zs1nlF7PQlP8UvEJIeBK3ygbSYPoauDupx8rgKRlwjx62xlCOQlmemk43DynydmBsgcYGHM6ROTI7h-SxE0Vurz_mvm2-4GOwoXky0hzRI1JGzQNd6cuwTkZa3lMf6HzqnfAHxbCiXa6vbGBSXegEgaItId9_FIDRh-RqVZB-T1vBe-Xw2Ho0_1nhzOCMqenP3Iyt15otjuTC1zZaRQnm-c6TUoh-E_AKG-jb4RF7UWgxiafrgBn4sJEzh560QF-ghYTpi2S_thhuQYe70zlBU7zE65Dy7TNw"}}
test@test:~$ TOKEN=$(kubectl oidc-login get-token \
  --oidc-issuer-url="https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698" \
  --oidc-client-id="0oa17n5mtdmEXDT8x698" \
  --oidc-extra-scope="profile" \
  --oidc-extra-scope="email" \
  --grant-type=authcode \
  -o json | jq -r '.status.token')
error: unknown shorthand flag: 'o' in -o
test@test:~$ TOKEN=$(kubectl oidc-login get-token \
  --oidc-issuer-url="https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698" \
  --oidc-client-id="0oa17n5mtdmEXDT8x698" \
  --oidc-extra-scope="profile" \
  --oidc-extra-scope="email" \
  --grant-type=authcode \
  | jq -r '.status.token')
test@test:~$ echo "$TOKEN" \
  | cut -d. -f2 \
  | tr '_-' '/+' \
  | awk '{l=length($0)%4; if(l==2) $0=$0"=="; else if(l==3) $0=$0"="; print}' \
  | base64 -d 2>/dev/null \
  | jq
{
  "sub": "00u17pgcqyoyiNmdL698",
  "name": "developer-member 01",
  "email": "prooftheory5@gmail.com",
  "ver": 1,
  "iss": "https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698",
  "aud": "0oa17n5mtdmEXDT8x698",
  "iat": 1789716342,
  "exp": 1789719942,
  "jti": "ID.AT4yiAC_CWlT73T4DamrHvuHzNZ5FstTooJ6pW7OARE",
  "amr": [
    "mfa",
    "otp",
    "pwd",
    "okta_verify"
  ],
  "idp": "00o17ln5mf35oxO9l698",
  "nonce": "1DLZzZ7o4mcyuBayxONcnOB1XVQcT3GEzSmRVaDIlyE",
  "preferred_username": "prooftheory5@gmail.com",
  "auth_time": 1789714419,
  "at_hash": "Xtk0E-lQwKmfddqjMjtIKw",
  "eks_groups": [
    "eks-developers"
  ]
}
test@test:~$ 
test@test:~$ echo "$TOKEN" \
  | cut -d. -f2 \
  | base64 -d 2>/dev/null \
  | jq