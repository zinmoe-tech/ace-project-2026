# Kong Distributed Gateway on EKS

This project deploys a distributed Kong Gateway API setup on Amazon EKS.

It includes:

- A global Kong Gateway layer using Kubernetes Gateway API.
- Domain-specific Kong gateways for retail banking, payments, and GRC.
- Cross-namespace routing with `ReferenceGrant`.
- Demo backend service chains using `nicholasjackson/fake-service`.
- Route 53 domain routing for `mini-apps.click`.
- Terraform support for enabling HTTPS with Let's Encrypt certificates.

## Main Domains

- `retail-banking.mini-apps.click`
- `payments.mini-apps.click`
- `grc.mini-apps.click`

## Important Folders

- `kong/`: global Gateway API resources.
- `apps/retail-banking/`: retail banking gateway, route, and demo services.
- `apps/payments/`: payments gateway, route, and demo services.
- `apps/grc/`: GRC gateway, route, and demo services.
- `for_https/`: Terraform for DNS-validated HTTPS certificates and Gateway HTTPS listeners.

## Notes

Do not commit local Terraform state, `terraform.tfvars`, kubeconfig, AWS credentials, or private keys.
