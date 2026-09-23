# Evidence Photo Index

Copy the screenshots from your `EKS with OIDC` folder into `images/` and rename the selected evidence files as below.

| Step | GitLab filename | Original project screenshot | Evidence |
|---|---|---|---|
| 1 | `step-01-okta-oidc-app.png` | `04f50bea-011a-4369-b3fa-af89e639b433.png` | Okta OIDC app / Client ID / PKCE |
| 2 | `step-02-authorization-server.png` | authorization-server screenshot from the same sequence | EKS authorization server |
| 3 | `step-03-access-policy.png` | `0286d676-01c3-48e7-aa28-51b8bed33977.png` | Access policy |
| 4 | `step-04-authorization-rule.png` | rule screenshots following the policy | Authorization Code + scopes |
| 5 | `step-05-okta-groups.png` | Okta groups/users screenshot | Group membership |
| 6 | `step-06-eks-groups-claim.png` | `e2ea8e58-95b5-4e67-834a-6465edf4bca8.png` | `eks_groups` claim |
| 7 | `step-07-eks-cluster-role.png` | `7f941839-9f18-4872-8cfe-eaef0c5ed55f.png` | Cluster-role policies |
| 8 | `step-08-eks-node-role.png` | EKS Auto Node Role screenshot | Node role |
| 9 | `step-09-eks-cluster.png` | EKS cluster Active screenshot | Cluster status |
| 10 | `step-10-eks-access-entry.png` | EKS access-entry screenshot | Bootstrap admin |
| 11 | `step-11-admin-kubeconfig.png` | update-kubeconfig terminal screenshot | Admin kubeconfig |
| 12 | `step-12-associate-oidc.png` | `596827a7-d485-4d26-9ced-69d5cd8248da.png` | Okta/EKS association |
| 13 | `step-13-oidc-active.png` | EKS OIDC Active screenshot | Provider Active |
| 14 | `step-14-admin-rbac.png` | `okta-eks-admins` binding screenshot | Admin RBAC |
| 17 | `step-17-developer-group.png` | developer group screenshot | Developer membership |
| 18 | `step-18-kubelogin.png` | kubelogin install/version screenshot | Plugin installed |
| 19 | `step-19-token-claims.png` | successful OIDC token screenshot | Token claims |
| 20 | `step-20-oidc-kubeconfig.png` | OIDC set-credentials screenshot | kubeconfig exec |
| 21 | `step-21-context.png` | context screenshot | OIDC context |
| 22 | `step-22-admin-test.png` | `kubectl auth can-i '*' '*'` screenshot | Admin authorization |
| 23 | `step-23-self-subject-review.png` | SelfSubjectReview screenshot | email + developer group |
| 24 | `step-24-developer-rbac-test.png` | final can-i screenshot | least-privilege proof |

## Recommended captions

- Figure 1 — Okta OIDC application configured with PKCE
- Figure 2 — Okta Authorization Server for Amazon EKS
- Figure 3 — Access policy assigned to EKS OIDC application
- Figure 4 — Authorization Code rule and OIDC scopes
- Figure 5 — Custom `eks_groups` claim
- Figure 6 — EKS cluster IAM role permissions
- Figure 7 — Okta associated as EKS OIDC provider
- Figure 8 — EKS OIDC provider Active
- Figure 9 — `eks-admins` mapped to `cluster-admin`
- Figure 10 — Successful Okta OIDC token
- Figure 11 — Kubernetes recognizes `eks-developers`
- Figure 12 — Developer namespace allow/deny RBAC test

## Redact before public upload

Replace organization-specific values with placeholders where appropriate:

`<AWS_ACCOUNT_ID>`, `<OKTA_DOMAIN>`, `<OKTA_CLIENT_ID>`, `<AUTHORIZATION_SERVER_ID>`, `<USER_EMAIL>`, `<IAM_ROLE_ARN>`

Never publish AWS secret keys, session tokens, passwords, Okta API tokens, or private keys.
