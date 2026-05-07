# Kong Plugins

This section extends the project from routing-only behavior to API gateway
policy enforcement.

Start with the Payments domain because it is easy to test through the existing
global route:

```text
https://mybank.mini-apps.click/payments
```

## Step 1 - Add Rate Limiting To Payments

The first plugin is:

```text
apps/payments/03-rate-limit-plugin.yaml
```

It creates a `KongPlugin` named `rate-limit-payments` in the same namespace as
the Payments `HTTPRoute`.

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: rate-limit-payments
  namespace: payments-team
plugin: rate-limiting
config:
  minute: 5
  policy: local
```

What each part means:

- `KongPlugin`: a Kubernetes custom resource understood by Kong Ingress Controller.
- `namespace: payments-team`: the plugin lives beside the route that uses it.
- `plugin: rate-limiting`: tells Kong which built-in plugin to enable.
- `minute: 5`: allows only 5 requests per minute.
- `policy: local`: keeps the rate-limit counter inside the Kong proxy pod.

The plugin is attached to the Payments route with this annotation:

```yaml
metadata:
  annotations:
    konghq.com/plugins: rate-limit-payments
```

## Apply

Apply the plugin first, then re-apply the route that references it:

```bash
kubectl apply -f apps/payments/03-rate-limit-plugin.yaml
kubectl apply -f apps/payments/02-transfer-httproute.yaml
```

## Verify

Check that the plugin exists:

```bash
kubectl get kongplugin -n payments-team
kubectl describe kongplugin rate-limit-payments -n payments-team
```

Send more than 5 requests to Payments:

```bash
for i in {1..7}; do
  curl -i https://mybank.mini-apps.click/payments
done
```

Expected result:

```text
First 5 requests: HTTP 200
After the limit: HTTP 429 Too Many Requests
```

## Why This Is The Best First Plugin

Rate limiting teaches the basic Kong extension pattern:

```text
Create KongPlugin
-> attach it to HTTPRoute
-> Kong Ingress Controller configures Kong Gateway
-> Kong Gateway changes request behavior
```

## Step 2 - Add Key-Auth To Payments

The second plugin is:

```text
apps/payments/04-key-auth-plugin.yaml
```

It contains three Kubernetes resources:

```text
KongPlugin
Secret
KongConsumer
```

### 1. KongPlugin

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: key-auth-payments
  namespace: payments-team
plugin: key-auth
```

This tells Kong to require an API key before allowing traffic through the
Payments route.

### 2. Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: payments-client-key-auth
  namespace: payments-team
  labels:
    konghq.com/credential: key-auth
stringData:
  key: payments-demo-key
```

This stores the demo API key. The label tells Kong this secret is a `key-auth`
credential.

Do not use demo keys like this in production. For a real system, generate a
strong secret value and manage it with your normal secret-management process.

### 3. KongConsumer

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: payments-client
  namespace: payments-team
  annotations:
    kubernetes.io/ingress.class: kong
username: payments-client
credentials:
- payments-client-key-auth
```

This creates a Kong consumer named `payments-client` and attaches the API-key
secret to that consumer.

The Payments route now has two plugins attached:

```yaml
metadata:
  annotations:
    konghq.com/plugins: rate-limit-payments,key-auth-payments
```

This means Payments traffic must pass both checks:

```text
1. Is the API key valid?
2. Is the client still under the rate limit?
```

## Apply Key-Auth

Apply the Key-Auth resources first:

```bash
kubectl apply -f apps/payments/04-key-auth-plugin.yaml
```

Then re-apply the Payments route:

```bash
kubectl apply -f apps/payments/02-transfer-httproute.yaml
```

## Verify Key-Auth

Check the plugin, consumer, and secret:

```bash
kubectl get kongplugin -n payments-team
kubectl get kongconsumer -n payments-team
kubectl get secret payments-client-key-auth -n payments-team --show-labels
```

Test without an API key:

```bash
curl -i https://mybank.mini-apps.click/payments
```

Expected result:

```text
HTTP 401 Unauthorized
```

Test with the API key:

```bash
curl -i https://mybank.mini-apps.click/payments \
  -H "apikey: payments-demo-key"
```

Expected result:

```text
HTTP 200 OK
```

If you run the valid-key request more than 5 times in one minute, you should
then see:

```text
HTTP 429 Too Many Requests
```

After this works, the next plugin should be JWT.
