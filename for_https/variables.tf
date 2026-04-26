variable "aws_region" {
  description = "AWS region that contains the EKS/Kong load balancers."
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile used for Route 53 DNS validation."
  type        = string
  default     = "demo-microservices"
}

variable "route53_zone_name" {
  description = "Public Route 53 hosted zone name."
  type        = string
  default     = "mini-apps.click"
}

variable "acme_email" {
  description = "Email address for Let's Encrypt registration and expiry notices."
  type        = string
}

variable "acme_server_url" {
  description = "ACME directory URL. The default is Let's Encrypt production."
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig for the EKS cluster."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubeconfig context for the EKS cluster."
  type        = string
  default     = "arn:aws:eks:ap-southeast-1:122610519603:cluster/demo-eks-cluster"
}

variable "domains" {
  description = "Domain hostnames and the Kong Gateway/KIC namespace they belong to."
  type = map(object({
    hostname        = string
    kic_namespace   = string
    gateway_name    = string
    gateway_class   = string
    route_namespace = string
  }))

  default = {
    retail_banking = {
      hostname        = "retail-banking.mini-apps.click"
      kic_namespace   = "retail-banking-kic"
      gateway_name    = "retail-banking-kong-api-gateway"
      gateway_class   = "retail-banking-kong-gatewayclass"
      route_namespace = "retail-banking"
    }

    payments = {
      hostname        = "payments.mini-apps.click"
      kic_namespace   = "payments-kic"
      gateway_name    = "payments-kong-api-gateway"
      gateway_class   = "payments-kong-gatewayclass"
      route_namespace = "payments"
    }

    grc = {
      hostname        = "grc.mini-apps.click"
      kic_namespace   = "grc-kic"
      gateway_name    = "grc-kong-api-gateway"
      gateway_class   = "grc-kong-gatewayclass"
      route_namespace = "grc"
    }
  }
}
