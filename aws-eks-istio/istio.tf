# ---------------------------------------------------------------------------
# Istio CONTROL PLANE only (base + istiod), installed via Helm by Terraform.
#
#   1. istio-base  -> the FOUNDATION. Registers Istio's CRDs (so the cluster
#                     understands Gateway / VirtualService / DestinationRule)
#                     plus cluster RBAC and the validation webhook. No pods run.
#
#   2. istiod      -> the CONTROL PLANE ("d" = daemon). The running brain of the
#                     mesh: programs every Envoy proxy with your routing rules,
#                     issues mTLS certificates, does service discovery and
#                     sidecar injection. Needs the CRDs from istio-base first.
#
# The GATEWAYS (team ingress GWs + the global edge GW) and all routing are NOT
# created here. They mirror the istio-gateway-cilium project and are applied on
# top via istioctl + kubectl from ./istio-manifests/ (see that README). This
# keeps Terraform = infra + control plane, exactly like cluster-with-cilium was
# infra-only in the local setup.
# ---------------------------------------------------------------------------

locals {
  istio_repo = "https://istio-release.storage.googleapis.com/charts"
}

# LAYER 1 — istio-base: installs Istio's CRDs + cluster-wide foundation.
# This is what makes `kubectl apply` of a Gateway/VirtualService even valid.
# No pods; it just registers definitions into the cluster.
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = local.istio_repo
  chart            = "base"
  version          = var.istio_version
  namespace        = "istio-system"
  create_namespace = true

  # Mark the plain (non-revisioned) istiod as the default revision, so Istio's
  # config-validation webhook is wired to it. Equivalent to:
  #   helm install istio-base base --set defaultRevision=default
  # (The "CRDs before istiod" ordering is handled by depends_on, not this value.)
  set {
    name  = "defaultRevision"
    value = "default"
  }

  depends_on = [module.eks]
}

# LAYER 2 — istiod: the running control plane (pods in istio-system). It pushes
# config to all Envoy proxies, is the mTLS certificate authority, and injects
# sidecars. depends_on istio_base so the CRDs exist before istiod starts.
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = local.istio_repo
  chart      = "istiod"
  version    = var.istio_version
  namespace  = "istio-system"

  depends_on = [helm_release.istio_base]
}