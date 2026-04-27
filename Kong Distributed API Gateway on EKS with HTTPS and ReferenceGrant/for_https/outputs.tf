output "route53_zone_id" {
  value = data.aws_route53_zone.public.zone_id
}

output "tls_secret_names" {
  value = {
    for key, secret in kubernetes_secret_v1.tls :
    key => "${secret.metadata[0].namespace}/${secret.metadata[0].name}"
  }
}

output "https_urls" {
  value = {
    for key, value in var.domains :
    key => "https://${value.hostname}/"
  }
}
