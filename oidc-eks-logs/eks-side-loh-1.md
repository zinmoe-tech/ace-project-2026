test@test:~$ aws eks describe-identity-provider-config \
  --cluster-name eks-oidc-project \
  --identity-provider-config type=oidc,name=okta-eks \
  --region us-east-1 \
  --profile eks-admin
{
    "identityProviderConfig": {
        "oidc": {
            "identityProviderConfigName": "okta-eks",
            "identityProviderConfigArn": "arn:aws:eks:us-east-1:691914216603:identityproviderconfig/eks-oidc-project/oidc/okta-eks/b8d0596d-d627-a3c7-ad62-665effa75fba",
            "clusterName": "eks-oidc-project",
            "issuerUrl": "https://trial-6095961.okta.com/oauth2/aus17ole72l3gv8RR698",
            "clientId": "0oa17n5mtdmEXDT8x698",
            "usernameClaim": "email",
            "groupsClaim": "eks_groups",
            "requiredClaims": {},
            "tags": {},
            "status": "ACTIVE"
        }
    }
}
test@test:~$ kubectl create -f - -o yaml --validate=false <<'EOF'
apiVersion: authentication.k8s.io/v1
kind: SelfSubjectReview
EOF
E0918 12:20:51.960559  463322 memcache.go:287] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
E0918 12:20:52.359487  463322 memcache.go:121] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
apiVersion: authentication.k8s.io/v1
kind: SelfSubjectReview
metadata:
  creationTimestamp: "2026-09-18T08:20:52Z"
status:
  userInfo:
    extra:
      authentication.kubernetes.io/credential-id:
      - JTI=ID.AT4yiAC_CWlT73T4DamrHvuHzNZ5FstTooJ6pW7OARE
    groups:
    - eks-developers
    - system:authenticated
    username: prooftheory5@gmail.com
test@test:~$ 
