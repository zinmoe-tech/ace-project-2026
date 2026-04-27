resource "kubernetes_manifest" "kong_gateway_https" {
  for_each = var.domains

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"

    metadata = {
      name      = each.value.gateway_name
      namespace = each.value.kic_namespace
    }

    spec = {
      gatewayClassName = each.value.gateway_class

      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80

          allowedRoutes = {
            namespaces = {
              from = "Selector"

              selector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = each.value.route_namespace
                }
              }
            }
          }
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443

          tls = {
            mode = "Terminate"

            certificateRefs = [
              {
                group = ""
                kind  = "Secret"
                name  = kubernetes_secret_v1.tls[each.key].metadata[0].name
              }
            ]
          }

          allowedRoutes = {
            namespaces = {
              from = "Selector"

              selector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = each.value.route_namespace
                }
              }
            }
          }
        }
      ]
    }
  }
}
