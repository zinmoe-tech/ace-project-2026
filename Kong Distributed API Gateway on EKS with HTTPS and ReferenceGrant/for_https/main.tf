locals {
  tls_secret_names = {
    for key, value in var.domains :
    key => "${replace(value.hostname, ".", "-")}-tls"
  }
}

data "aws_route53_zone" "public" {
  name         = "${var.route53_zone_name}."
  private_zone = false
}

resource "tls_private_key" "acme_account" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "acme_registration" "account" {
  account_key_pem = tls_private_key.acme_account.private_key_pem
  email_address   = var.acme_email
}

resource "acme_certificate" "cert" {
  for_each = var.domains

  account_key_pem = acme_registration.account.account_key_pem
  common_name     = each.value.hostname

  dns_challenge {
    provider = "route53"

    config = {
      AWS_PROFILE        = var.aws_profile
      AWS_REGION         = var.aws_region
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.public.zone_id
    }
  }
}

resource "kubernetes_secret_v1" "tls" {
  for_each = var.domains

  metadata {
    name      = local.tls_secret_names[each.key]
    namespace = each.value.kic_namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = "${acme_certificate.cert[each.key].certificate_pem}${acme_certificate.cert[each.key].issuer_pem}"
    "tls.key" = acme_certificate.cert[each.key].private_key_pem
  }
}
