# Troubleshooting

## AWS CLI cannot find credentials

```text
Unable to locate credentials
```

Verify:

```bash
aws sts get-caller-identity --profile eks-admin
```

## kubectl asks for credentials

Check the active context, AWS profile, EKS access entry, and OIDC kubeconfig user.

## OIDC discovery returns 404

The lab encountered this when the Okta Authorization Server ID in the issuer URL was incorrect.

Use the exact issuer URL shown by Okta.

## OIDC login succeeds but EKS returns Unauthorized

Verify:

1. token `iss` matches the EKS issuer configuration exactly;
2. token `aud` matches the Okta Client ID configured in EKS;
3. the EKS identity provider is `ACTIVE`;
4. the `email` claim exists;
5. `eks_groups` exists;
6. the corresponding RoleBinding/ClusterRoleBinding exists.

## Group claim is missing

Check the Okta claim:

- Name: `eks_groups`
- Value type: Groups
- Filter: starts with `eks-`
- Included in ID token

## Clear cached OIDC token

```bash
kubectl oidc-login clean
```
