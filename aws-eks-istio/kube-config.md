unset KUBECONFIG
aws eks update-kubeconfig --region ap-southeast-1 --name idp-cluster --profile
kubectl config get-contexts
kubectl get nodes