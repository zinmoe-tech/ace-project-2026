test@test:~$ kubectl oidc-login setup \
  --oidc-issuer-url="https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698" \
  --oidc-client-id="0oa17n5mtdmEXDT8x698" \
  --oidc-extra-scope="profile" \
  --oidc-extra-scope="email" \
  --grant-type=authcode \
  --listen-address=127.0.0.1:8000 \
  -v=5
Authentication in progress...
I0918 10:52:45.991946  225215 authentication.go:99] initializing an OpenID Connect client
I0918 10:52:45.992351  225215 logging.go:30] GET /oauth2/aus17ole72l3gv8RR698/.well-known/openid-configuration HTTP/1.1
Host: trial-6095961.okta.com
User-Agent: Go-http-client/1.1
Accept-Encoding: gzip

I0918 10:52:47.884971  225215 logging.go:40] HTTP/1.1 200 OK
Transfer-Encoding: chunked
Accept-Ch: Sec-CH-UA-Platform-Version
Cache-Control: max-age=86400, must-revalidate
Connection: keep-alive
Content-Security-Policy: default-src 'self' trial-6095961.okta.com *.oktacdn.com; connect-src 'self' trial-6095961.okta.com trial-6095961-admin.okta.com *.oktacdn.com *.mixpanel.com *.mapbox.com trial-6095961.kerberos.okta.com trial-6095961.mtls.okta.com *.authenticatorlocalprod.com:8769 http://localhost:8769 http://127.0.0.1:8769 *.authenticatorlocalprod.com:65111 http://localhost:65111 http://127.0.0.1:65111 *.authenticatorlocalprod.com:65121 http://localhost:65121 http://127.0.0.1:65121 *.authenticatorlocalprod.com:65131 http://localhost:65131 http://127.0.0.1:65131 *.authenticatorlocalprod.com:65141 http://localhost:65141 http://127.0.0.1:65141 *.authenticatorlocalprod.com:65151 http://localhost:65151 http://127.0.0.1:65151 https://oinmanager.okta.com data: *.ingest.sentry.io; script-src 'unsafe-inline' 'nonce-1w_Hh1SLiBwPUQwHE8qdUQ' 'self' 'report-sample' trial-6095961.okta.com *.oktacdn.com; style-src 'unsafe-inline' 'nonce-1w_Hh1SLiBwPUQwHE8qdUQ' 'self' 'report-sample' trial-6095961.okta.com *.oktacdn.com; frame-src 'self' trial-6095961.okta.com trial-6095961-admin.okta.com login.okta.com *.vidyard.com com-okta-authenticator:; img-src 'self' trial-6095961.okta.com *.oktacdn.com *.tiles.mapbox.com *.mapbox.com *.vidyard.com data: blob:; font-src 'self' trial-6095961.okta.com data: *.oktacdn.com fonts.gstatic.com; frame-ancestors 'self'
Content-Type: application/json
Date: Fri, 18 Sep 2026 06:52:47 GMT
Expires: Sat, 19 Sep 2026 06:52:47 GMT
P3p: CP="HONK"
Referrer-Policy: strict-origin-when-cross-origin
Server: nginx
Strict-Transport-Security: max-age=315360000; includeSubDomains
Vary: Origin
X-Content-Type-Options: nosniff
X-Okta-Request-Id: fbdd8c2d9fddcc14e7e7674e199b64b1
X-Xss-Protection: 0

c1d
{"issuer":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698","authorization_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/authorize","token_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/token","userinfo_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/userinfo","registration_endpoint":"https://trial-6095961.okta.com/oauth2/v1/clients","jwks_uri":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/keys","response_types_supported":["code","id_token","code id_token","code token","id_token token","code id_token token"],"response_modes_supported":["query","fragment","form_post","okta_post_message"],"grant_types_supported":["authorization_code","implicit","refresh_token","password","urn:ietf:params:oauth:grant-type:device_code","urn:openid:params:grant-type:ciba","urn:okta:params:oauth:grant-type:otp","http://auth0.com/oauth/grant-type/mfa-otp","urn:okta:params:oauth:grant-type:oob","http://auth0.com/oauth/grant-type/mfa-oob"],"subject_types_supported":["public"],"id_token_signing_alg_values_supported":["RS256"],"id_token_encryption_alg_values_supported":["RSA-OAEP-256","RSA-OAEP-384","RSA-OAEP-512"],"id_token_encryption_enc_values_supported":["A256GCM"],"scopes_supported":["openid","profile","email","address","phone","offline_access","device_sso","interclient_access"],"token_endpoint_auth_methods_supported":["client_secret_basic","client_secret_post","client_secret_jwt","private_key_jwt","none"],"claims_supported":["iss","ver","sub","aud","iat","exp","jti","auth_time","amr","idp","nonce","name","nickname","preferred_username","given_name","middle_name","family_name","email","email_verified","profile","zoneinfo","locale","address","phone_number","picture","website","gender","birthdate","updated_at","at_hash","c_hash"],"code_challenge_methods_supported":["S256"],"introspection_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/introspect","introspection_endpoint_auth_methods_supported":["client_secret_basic","client_secret_post","client_secret_jwt","private_key_jwt","none"],"revocation_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/revoke","revocation_endpoint_auth_methods_supported":["client_secret_basic","client_secret_post","client_secret_jwt","private_key_jwt","none"],"end_session_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/logout","request_parameter_supported":true,"request_object_signing_alg_values_supported":["HS256","HS384","HS512","RS256","RS384","RS512","ES256","ES384","ES512"],"device_authorization_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/device/authorize","pushed_authorization_request_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/par","backchannel_token_delivery_modes_supported":["poll"],"backchannel_authentication_request_signing_alg_values_supported":["HS256","HS384","HS512","RS256","RS384","RS512","ES256","ES384","ES512"],"dpop_signing_alg_values_supported":["RS256","RS384","RS512","ES256","ES384","ES512"]}
0

I0918 10:52:47.885570  225215 browser.go:34] starting the authentication code flow using the browser
I0918 10:52:47.886443  225215 browser.go:102] opening http://localhost:8000/ in the browser
I0918 10:52:47.886606  225215 server.go:59] oauth2cli: starting a server at 127.0.0.1:8000
Gtk-Message: 10:52:48.147: Not loading module "atk-bridge": The functionality is provided by GTK natively. Please try to not load it.
I0918 10:52:48.357659  225215 server.go:157] oauth2cli: sending redirect to https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/authorize?access_type=offline&client_id=0oa17n5mtdmEXDT8x698&code_challenge=fgxoyV4C3miifhhLKDeb8jmSL4lJVDm0oP0xB_Gdx2o&code_challenge_method=S256&nonce=BoNUHeffmfvnvFVOlMohHYOW_1HPtIddpbMmEQWasU0&redirect_uri=http%3A%2F%2Flocalhost%3A8000&response_type=code&scope=profile+email+openid&state=HMzsTm6bLp7BaGSsE6zV-LffPISZm13oUESBSiYf_qo
I0918 10:53:40.526928  225215 server.go:92] oauth2cli: shutting down the server
I0918 10:53:40.527119  225215 server.go:73] oauth2cli: stopped the server
I0918 10:53:40.527256  225215 oauth2cli.go:163] oauth2cli: exchanging the code and token
I0918 10:53:40.527635  225215 logging.go:30] POST /oauth2/aus17ole72l3gv8RR698/v1/token HTTP/1.1
Host: trial-6095961.okta.com
User-Agent: Go-http-client/1.1
Content-Length: 210
Content-Type: application/x-www-form-urlencoded
Accept-Encoding: gzip

client_id=0oa17n5mtdmEXDT8x698&code=NT5dp4Y0o2eNAcg6lU6HNOAVDozFMQjUKSNOqB36NH4&code_verifier=2MczxuNRCoAZlv8dnC2g5bZrnWxec3oT2zuger__O00&grant_type=authorization_code&redirect_uri=http%3A%2F%2Flocalhost%3A8000
I0918 10:53:41.136916  225215 logging.go:40] HTTP/1.1 200 OK
Transfer-Encoding: chunked
Accept-Ch: Sec-CH-UA-Platform-Version
Cache-Control: no-cache, no-store
Connection: keep-alive
Content-Security-Policy: default-src 'self' trial-6095961.okta.com *.oktacdn.com; connect-src 'self' trial-6095961.okta.com trial-6095961-admin.okta.com *.oktacdn.com *.mixpanel.com *.mapbox.com trial-6095961.kerberos.okta.com trial-6095961.mtls.okta.com *.authenticatorlocalprod.com:8769 http://localhost:8769 http://127.0.0.1:8769 *.authenticatorlocalprod.com:65111 http://localhost:65111 http://127.0.0.1:65111 *.authenticatorlocalprod.com:65121 http://localhost:65121 http://127.0.0.1:65121 *.authenticatorlocalprod.com:65131 http://localhost:65131 http://127.0.0.1:65131 *.authenticatorlocalprod.com:65141 http://localhost:65141 http://127.0.0.1:65141 *.authenticatorlocalprod.com:65151 http://localhost:65151 http://127.0.0.1:65151 https://oinmanager.okta.com data: *.ingest.sentry.io; script-src 'unsafe-inline' 'nonce-fgoPUUtcZdvcyN8XZskuEw' 'self' 'report-sample' trial-6095961.okta.com *.oktacdn.com; style-src 'unsafe-inline' 'nonce-fgoPUUtcZdvcyN8XZskuEw' 'self' 'report-sample' trial-6095961.okta.com *.oktacdn.com; frame-src 'self' trial-6095961.okta.com trial-6095961-admin.okta.com login.okta.com *.vidyard.com com-okta-authenticator:; img-src 'self' trial-6095961.okta.com *.oktacdn.com *.tiles.mapbox.com *.mapbox.com *.vidyard.com data: blob:; font-src 'self' trial-6095961.okta.com data: *.oktacdn.com fonts.gstatic.com; frame-ancestors 'self'
Content-Type: application/json
Date: Fri, 18 Sep 2026 06:53:41 GMT
Expires: 0
P3p: CP="HONK"
Pragma: no-cache
Referrer-Policy: strict-origin-when-cross-origin
Server: nginx
Set-Cookie: sid="";Version=1;Path=/;Max-Age=0
Set-Cookie: xids="";Version=1;Path=/;Max-Age=0
Set-Cookie: autolaunch_triggered=""; Expires=Thu, 01 Jan 1970 00:00:10 GMT; Path=/
Set-Cookie: activate_ca_modal_triggered=""; Expires=Thu, 01 Jan 1970 00:00:10 GMT; Path=/
Set-Cookie: JSESSIONID=A999C44D7D2CEA44A824D7EF3B578731; Path=/; Secure; HttpOnly
Strict-Transport-Security: max-age=315360000; includeSubDomains
X-Content-Type-Options: nosniff
X-Okta-Request-Id: eb4e2e797e280682f5fdbbb25ad07a58
X-Rate-Limit-Limit: 1000
X-Rate-Limit-Remaining: 999
X-Rate-Limit-Reset: 1789714480
X-Robots-Tag: noindex,nofollow
X-Xss-Protection: 0

85a
{"token_type":"Bearer","expires_in":3600,"access_token":"eyJraWQiOiJvRGx5UjdrVmNUMFY2MnNnamdOeW44TGJvRC1wU29wb1ZmV1BScURiNWdBIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULk5mcGFza09obzdWR0E2elpmVXJpajBiQW9IMTAzLXFMaHJyOFRCVGFSX1kiLCJpc3MiOiJodHRwczovL3RyaWFsLTYwOTU5NjEub2t0YS5jb20vb2F1dGgyL2F1czE3b2xlNzJsM2d2OFJSNjk4IiwiYXVkIjoiYXBpOi8vZWtzIiwiaWF0IjoxNzg5NzE0NDIwLCJleHAiOjE3ODk3MTgwMjAsImNpZCI6IjBvYTE3bjVtdGRtRVhEVDh4Njk4IiwidWlkIjoiMDB1MTdwZ2NxeW95aU5tZEw2OTgiLCJzY3AiOlsib3BlbmlkIiwicHJvZmlsZSIsImVtYWlsIl0sImF1dGhfdGltZSI6MTc4OTcxNDQxOSwic3ViIjoicHJvb2Z0aGVvcnk1QGdtYWlsLmNvbSJ9.VUDyfGUkZxVxsbHMSmu3zGfDiF3LQdbEYOotVwyvg87i7nk9scKraRUyR_XlPeJ6yGBGfyxYH8qdlOCrVfbSGeYH5A5MZiNQtxKhM0AhqDa6MZH170Ii3qPK1S7-J6ovQsDrnA86crenETjlx67SbcVmd5g852pDg4X8XYrl9B4-ystlR8SZ017wEzrrAFpoJ-fMFbj2vT3FmPRChE7qwto_VoMYjiQvjYZKyIchogQa9I52Dhf9bOrtNdGHX6ALJlpzs2x_QFc5KvymrGIPRwoiK3E7z2To-tmE2F_vyuemafj1lfmbkwnFku6h2gi7dWIclIPnf0Xdk09dMhZF6A","scope":"openid profile email","id_token":"eyJraWQiOiJvRGx5UjdrVmNUMFY2MnNnamdOeW44TGJvRC1wU29wb1ZmV1BScURiNWdBIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHUxN3BnY3F5b3lpTm1kTDY5OCIsIm5hbWUiOiJkZXZlbG9wZXItbWVtYmVyIDAxIiwiZW1haWwiOiJwcm9vZnRoZW9yeTVAZ21haWwuY29tIiwidmVyIjoxLCJpc3MiOiJodHRwczovL3RyaWFsLTYwOTU5NjEub2t0YS5jb20vb2F1dGgyL2F1czE3b2xlNzJsM2d2OFJSNjk4IiwiYXVkIjoiMG9hMTduNW10ZG1FWERUOHg2OTgiLCJpYXQiOjE3ODk3MTQ0MjAsImV4cCI6MTc4OTcxODAyMCwianRpIjoiSUQuWUcyZHJ3T1pKU2EzdF9CSFVLN1FXd25Lb0NCVDI1dENQOU43SjBCbXY5SSIsImFtciI6WyJtZmEiLCJvdHAiLCJwd2QiLCJva3RhX3ZlcmlmeSJdLCJpZHAiOiIwMG8xN2xuNW1mMzVveE85bDY5OCIsIm5vbmNlIjoiQm9OVUhlZmZtZnZudkZWT2xNb2hIWU9XXzFIUHRJZGRwYk1tRVFXYXNVMCIsInByZWZlcnJlZF91c2VybmFtZSI6InByb29mdGhlb3J5NUBnbWFpbC5jb20iLCJhdXRoX3RpbWUiOjE3ODk3MTQ0MTksImF0X2hhc2giOiJOejZPdkhkLTF0Ql93clBNc2lfeVBRIiwiZWtzX2dyb3VwcyI6WyJla3MtZGV2ZWxvcGVycyJdfQ.EATKIiF88k2HNwDqrupoilVNn3C2qcqOGFlDnbgk-dZrpRfCXlugN8e7QIF4VHJdPEx3i4JzWMGmSIGeRaIuOYVgSCVwBbpAx4lL0L95Q-P0vQkfMLQrc0Tf8HmcZsZx6uAOUmdd8AZ3K5pZSD-77PD9eIv4_jD1GH1z6qpFYT5nNxr1Tfqot59UXnBIpipS3tQQ-CS1VgzZdtELrCuEgUiV5Rr3NAwMg8Lhp_s4GXF7TuMmsjV3iITAwCwFu5YlHwz6wOMFrv-4XRmmNV1jk2w5dy-7d5ci96RAPXwF66Oe5uFXMsoBTVMM5gPAMHRxLFIEInoi_HroF89JDp7DKQ"}
0

I0918 10:53:41.137874  225215 logging.go:30] GET /oauth2/aus17ole72l3gv8RR698/v1/keys HTTP/1.1
Host: trial-6095961.okta.com
User-Agent: Go-http-client/1.1
Cache-Control: no-cache
Accept-Encoding: gzip

I0918 10:53:41.609180  225215 logging.go:40] HTTP/1.1 200 OK
Transfer-Encoding: chunked
Accept-Ch: Sec-CH-UA-Platform-Version
Cache-Control: max-age=3885115, must-revalidate
Connection: keep-alive
Content-Security-Policy: default-src 'self' trial-6095961.okta.com *.oktacdn.com; connect-src 'self' trial-6095961.okta.com trial-6095961-admin.okta.com *.oktacdn.com *.mixpanel.com *.mapbox.com trial-6095961.kerberos.okta.com trial-6095961.mtls.okta.com *.authenticatorlocalprod.com:8769 http://localhost:8769 http://127.0.0.1:8769 *.authenticatorlocalprod.com:65111 http://localhost:65111 http://127.0.0.1:65111 *.authenticatorlocalprod.com:65121 http://localhost:65121 http://127.0.0.1:65121 *.authenticatorlocalprod.com:65131 http://localhost:65131 http://127.0.0.1:65131 *.authenticatorlocalprod.com:65141 http://localhost:65141 http://127.0.0.1:65141 *.authenticatorlocalprod.com:65151 http://localhost:65151 http://127.0.0.1:65151 https://oinmanager.okta.com data: *.ingest.sentry.io; script-src 'unsafe-inline' 'nonce-USXnGWY191uFe1nj5aJrgg' 'self' 'report-sample' trial-6095961.okta.com *.oktacdn.com; style-src 'unsafe-inline' 'nonce-USXnGWY191uFe1nj5aJrgg' 'self' 'report-sample' trial-6095961.okta.com *.oktacdn.com; frame-src 'self' trial-6095961.okta.com trial-6095961-admin.okta.com login.okta.com *.vidyard.com com-okta-authenticator:; img-src 'self' trial-6095961.okta.com *.oktacdn.com *.tiles.mapbox.com *.mapbox.com *.vidyard.com data: blob:; font-src 'self' trial-6095961.okta.com data: *.oktacdn.com fonts.gstatic.com; frame-ancestors 'self'
Content-Type: application/json
Date: Fri, 18 Sep 2026 06:53:41 GMT
Expires: Mon, 02 Nov 2026 06:05:36 GMT
P3p: CP="HONK"
Referrer-Policy: strict-origin-when-cross-origin
Server: nginx
Strict-Transport-Security: max-age=315360000; includeSubDomains
Vary: Origin
X-Content-Type-Options: nosniff
X-Okta-Request-Id: 4e643890088367d71607f14048c8e97d
X-Xss-Protection: 0

1ce
{"keys":[{"kty":"RSA","alg":"RS256","kid":"oDlyR7kVcT0V62sgjgNyn8LboD-pSopoVfWPRqDb5gA","use":"sig","e":"AQAB","n":"obgz6A9-54Dab_km6Uzw9E-VHVdhtmXsfsWE0oViNr-1LN6TxxkEtltgW6bmbobKsdHhTCxsyazZ2-F3d8lBo_rjj0DFP3Qu_Y4XbUL5k_B2rvnkSfHs079VA5pOR2NHJ-5Ow9Y4xrhqR8TlhFrOnCnbMUTEJPmz68wL7XIni_kyPnTdRX-BZkpRGl1vcGdBHb9ilrEFCqqtNq5cPm5iOejgnojrbytzUUvQQsDHpMoSuJuVo_gZaxRLDF2EKc68hsSBd1fIL0V5YbvXQU1XuTJP82FfhOk4C-CwjPfcrn7oUMdj_wb929b-EWkrAPR8jYLU4lGFMAS6Z2QVaxvcMw"}]}
0

I0918 10:53:41.610533  225215 browser.go:86] got a token set by the authorization code flow
I0918 10:53:41.610589  225215 browser.go:92] finished the authorization code flow via the browser
## Authenticated with the OpenID Connect Provider

You got the token with the following claims:

```
{
  "sub": "00u17pgcqyoyiNmdL698",
  "name": "developer-member 01",
  "email": "prooftheory5@gmail.com",
  "ver": 1,
  "iss": "https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698",
  "aud": "0oa17n5mtdmEXDT8x698",
  "iat": 1789714420,
  "exp": 1789718020,
  "jti": "ID.YG2drwOZJSa3t_BHUK7QWwnKoCBT25tCP9N7J0Bmv9I",
  "amr": [
    "mfa",
    "otp",
    "pwd",
    "okta_verify"
  ],
  "idp": "00o17ln5mf35oxO9l698",
  "nonce": "BoNUHeffmfvnvFVOlMohHYOW_1HPtIddpbMmEQWasU0",
  "preferred_username": "prooftheory5@gmail.com",
  "auth_time": 1789714419,
  "at_hash": "Nz6OvHd-1tB_wrPMsi_yPQ",
  "eks_groups": [
    "eks-developers"
  ]
}
```

## Set up the kubeconfig

You can run the following command to set up the kubeconfig:

```
kubectl config set-credentials oidc \
  --exec-api-version=client.authentication.k8s.io/v1 \
  --exec-interactive-mode=Never \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg="--oidc-issuer-url=https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698" \
  --exec-arg="--oidc-client-id=0oa17n5mtdmEXDT8x698" \
  --exec-arg="--oidc-extra-scope=profile" \
  --exec-arg="--oidc-extra-scope=email" \
  --exec-arg="--grant-type=authcode" \
  --exec-arg="--listen-address=127.0.0.1:8000" \
  --exec-arg="--v=5"
```
test@test:~$ 

