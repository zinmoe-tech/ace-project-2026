# Retail Banking Email Alert

This sends an email to `zinawsglory@gmail.com` when the retail banking entry service receives more than 500 requests in 5 minutes.

The alert uses this Istio metric:

```promql
sum(increase(istio_requests_total{
  reporter="destination",
  destination_service_name="customer-profile-svc",
  destination_workload_namespace="retail-banking-ns"
}[5m])) > 500
```

## Install

Create the Alertmanager Gmail config secret first. Copy the example and replace `REPLACE_WITH_GMAIL_APP_PASSWORD` with a Gmail App Password, not your normal Gmail password.

```bash
cp istio-api-gateway/monitoring/retail-alertmanager-config.example.yaml /tmp/retail-alertmanager-config.yaml
vi /tmp/retail-alertmanager-config.yaml
kubectl apply -f /tmp/retail-alertmanager-config.yaml
```

Then deploy the alerting Prometheus and Alertmanager:

```bash
kubectl apply -f istio-api-gateway/monitoring/retail-banking-email-alerts.yaml
```

## Verify

```bash
kubectl get pods,svc -n istio-system | grep retail-alert
kubectl port-forward -n istio-system svc/retail-alert-prometheus 9091:9090
```

Open Prometheus:

```text
http://localhost:9091/alerts
```

Generate traffic:

```bash
while true; do curl -H "Host: retail-banking.ky-cloud.click" http://172.18.255.180; sleep 0.5; done
```

At `sleep 0.5`, traffic is around 600 requests in 5 minutes, so the alert should fire after the 5 minute window plus the 1 minute `for:` duration.
