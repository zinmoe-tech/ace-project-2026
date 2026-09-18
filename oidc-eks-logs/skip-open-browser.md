test@test:~$ kubectl oidc-login setup \
  --oidc-issuer-url="https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698" \
  --oidc-client-id="0oa17n5mtdmEXDT8x698" \
  --oidc-extra-scope="profile" \
  --oidc-extra-scope="email" \
  --grant-type=authcode \
  --listen-address=127.0.0.1:8000 \
  --skip-open-browser \
  -v=5
Authentication in progress...
I0918 11:21:35.450357  312989 authentication.go:99] initializing an OpenID Connect client
I0918 11:21:35.450756  312989 logging.go:30] GET /oauth2/aus17ole72l3gv8RR698/.well-known/openid-configuration HTTP/1.1
Host: trial-6095961.okta.com
User-Agent: Go-http-client/1.1
Accept-Encoding: gzip

I0918 11:21:36.662760  312989 logging.go:40] HTTP/1.1 200 OK
Transfer-Encoding: chunked
Accept-Ch: Sec-CH-UA-Platform-Version
Cache-Control: max-age=86400, must-revalidate
Connection: keep-alive
Content-Security-Policy: default-src 'self' trial-6095961.okta.com *.oktacdn.com; connect-src 'self' trial-6095961.okta.com trial-6095961-admin.okta.com *.oktacdn.com *.mixpanel.com *.mapbox.com trial-6095961.kerberos.okta.com trial-6095961.mtls.okta.com *.authenticatorlocalprod.com:8769 http://localhost:8769 http://127.0.0.1:8769 *.authenticatorlocalprod.com:65111 http://localhost:65111 http://127.0.0.1:65111 *.authenticatorlocalprod.com:65121 http://localhost:65121 http://127.0.0.1:65121 *.authenticatorlocalprod.com:65131 http://localhost:65131 http://127.0.0.1:65131 *.authenticatorlocalprod.com:65141 http://localhost:65141 http://127.0.0.1:65141 *.authenticatorlocalprod.com:65151 http://localhost:65151 http://127.0.0.1:65151 https://oinmanager.okta.com data: *.ingest.sentry.io; script-src 'unsafe-inline' 'nonce-6TpOkRdkABIcGkLHNEUErQ' 'self' 'report-sample' trial-6095961.okta.com *.oktacdn.com; style-src 'unsafe-inline' 'nonce-6TpOkRdkABIcGkLHNEUErQ' 'self' 'report-sample' trial-6095961.okta.com *.oktacdn.com; frame-src 'self' trial-6095961.okta.com trial-6095961-admin.okta.com login.okta.com *.vidyard.com com-okta-authenticator:; img-src 'self' trial-6095961.okta.com *.oktacdn.com *.tiles.mapbox.com *.mapbox.com *.vidyard.com data: blob:; font-src 'self' trial-6095961.okta.com data: *.oktacdn.com fonts.gstatic.com; frame-ancestors 'self'
Content-Type: application/json
Date: Fri, 18 Sep 2026 07:21:36 GMT
Expires: Sat, 19 Sep 2026 07:21:36 GMT
P3p: CP="HONK"
Referrer-Policy: strict-origin-when-cross-origin
Server: nginx
Strict-Transport-Security: max-age=315360000; includeSubDomains
Vary: Origin
X-Content-Type-Options: nosniff
X-Okta-Request-Id: b0473b2ad622651b6becabf069b98fce
X-Xss-Protection: 0

c1d
{"issuer":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698","authorization_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/authorize","token_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/token","userinfo_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/userinfo","registration_endpoint":"https://trial-6095961.okta.com/oauth2/v1/clients","jwks_uri":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/keys","response_types_supported":["code","id_token","code id_token","code token","id_token token","code id_token token"],"response_modes_supported":["query","fragment","form_post","okta_post_message"],"grant_types_supported":["authorization_code","implicit","refresh_token","password","urn:ietf:params:oauth:grant-type:device_code","urn:openid:params:grant-type:ciba","urn:okta:params:oauth:grant-type:otp","http://auth0.com/oauth/grant-type/mfa-otp","urn:okta:params:oauth:grant-type:oob","http://auth0.com/oauth/grant-type/mfa-oob"],"subject_types_supported":["public"],"id_token_signing_alg_values_supported":["RS256"],"id_token_encryption_alg_values_supported":["RSA-OAEP-256","RSA-OAEP-384","RSA-OAEP-512"],"id_token_encryption_enc_values_supported":["A256GCM"],"scopes_supported":["openid","profile","email","address","phone","offline_access","device_sso","interclient_access"],"token_endpoint_auth_methods_supported":["client_secret_basic","client_secret_post","client_secret_jwt","private_key_jwt","none"],"claims_supported":["iss","ver","sub","aud","iat","exp","jti","auth_time","amr","idp","nonce","name","nickname","preferred_username","given_name","middle_name","family_name","email","email_verified","profile","zoneinfo","locale","address","phone_number","picture","website","gender","birthdate","updated_at","at_hash","c_hash"],"code_challenge_methods_supported":["S256"],"introspection_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/introspect","introspection_endpoint_auth_methods_supported":["client_secret_basic","client_secret_post","client_secret_jwt","private_key_jwt","none"],"revocation_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/revoke","revocation_endpoint_auth_methods_supported":["client_secret_basic","client_secret_post","client_secret_jwt","private_key_jwt","none"],"end_session_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/logout","request_parameter_supported":true,"request_object_signing_alg_values_supported":["HS256","HS384","HS512","RS256","RS384","RS512","ES256","ES384","ES512"],"device_authorization_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/device/authorize","pushed_authorization_request_endpoint":"https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698/v1/par","backchannel_token_delivery_modes_supported":["poll"],"backchannel_authentication_request_signing_alg_values_supported":["HS256","HS384","HS512","RS256","RS384","RS512","ES256","ES384","ES512"],"dpop_signing_alg_values_supported":["RS256","RS384","RS512","ES256","ES384","ES512"]}
0

I0918 11:21:36.663434  312989 browser.go:34] starting the authentication code flow using the browser
Please visit the following URL in your browser: http://localhost:8000/
I0918 11:21:36.664290  312989 server.go:59] oauth2cli: starting a server at 127.0.0.1:8000




test@test:~$ ss -lntp | grep 8000
LISTEN 0      4096       127.0.0.1:8000       0.0.0.0:*    users:(("kubectl-oidc_lo",pid=322299,fd=6))
test@test:~$ 

test@test:~$ lsof -i :8000
COMMAND      PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
kubectl-o 330587 test    6u  IPv4 609021      0t0  TCP localhost:8000 (LISTEN)
test@test:~$ 

