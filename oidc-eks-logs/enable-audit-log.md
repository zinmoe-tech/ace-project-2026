aws eks update-cluster-config \
  --name eks-oidc-project \
  --region us-east-1 \
  --profile eks-admin \
  --logging '{"clusterLogging":[{"types":["audit"],"enabled":true}]}'