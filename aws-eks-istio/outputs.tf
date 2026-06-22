output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "region" {
  description = "AWS region."
  value       = var.region
}

output "configure_kubectl" {
  description = "Run this to point kubectl at the new cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "global_gateway_lb_hint" {
  description = "How to find the external NLB hostname once the gateway is up."
  value       = "kubectl -n global-istio-ingress get svc global-istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
