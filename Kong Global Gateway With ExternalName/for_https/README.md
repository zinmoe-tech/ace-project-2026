# HTTPS for Kong Gateway API

This Terraform configuration enables trusted HTTPS for:

- `https://mybank.mini-apps.click/`
- `https://retail-banking.mini-apps.click/`
- `https://payments.mini-apps.click/`
- `https://grc.mini-apps.click/`

It uses Let's Encrypt ACME DNS validation through Route 53, creates Kubernetes TLS Secrets in the Kong KIC namespaces, and updates each Gateway with an HTTPS listener on port `443`.

## Prerequisites

- `terraform` installed.
- AWS profile `demo-microservices` can edit Route 53 records in `mini-apps.click`.
- `kubectl` is configured for the EKS cluster.
- The Gateway API CRDs and Kong/KIC Gateways already exist.

## Usage

```bash
cd for_https
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set `acme_email`.

Then run:

```bash
terraform init
terraform plan
terraform apply
```

After apply:

```bash
kubectl get gateway -A
kubectl get secret -n global-kic
kubectl get secret -n retail-banking-kic
kubectl get secret -n payments-kic
kubectl get secret -n grc-kic

curl -i https://mybank.mini-apps.click/retail-banking
curl -i https://retail-banking.mini-apps.click/
curl -i https://payments.mini-apps.click/ \
  -H "apikey: payments-demo-key"
curl -i https://grc.mini-apps.click/
```

## Important

The issued certificate private keys are stored in Terraform state. Keep the `terraform.tfstate` file private.

If you want to test first without Let's Encrypt production rate limits, temporarily set:

```hcl
acme_server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
```
