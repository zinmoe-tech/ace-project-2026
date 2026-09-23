# Amazon EKS Authentication with Okta OIDC

This repository documents a proof-of-concept integration between **Okta OIDC** and **Amazon EKS** for Kubernetes user authentication, with **Kubernetes RBAC** for authorization.

## Architecture

```mermaid
flowchart LR
    U[User] --> K[kubectl]
    K --> L[kubelogin / oidc-login]
    L --> O[Okta]
    O -->|OIDC ID Token| E[Amazon EKS API Server]
    E --> I[Kubernetes Identity]
    I --> R[Kubernetes RBAC]
    R --> A[eks-admins: cluster-admin]
    R --> D[eks-developers: namespace access]
```

## Access Model

| Okta Group | Kubernetes Permission |
|---|---|
| `eks-admins` | Cluster-wide administrator |
| `eks-developers` | Restricted to `developers-team` namespace |

## Documentation

- [Full implementation](docs/IMPLEMENTATION.md)
- [Evidence photo index](docs/EVIDENCE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Security guidance](SECURITY.md)

## Repository Structure

```text
eks-okta-oidc/
├── README.md
├── SECURITY.md
├── docs/
├── images/
├── kubernetes/
└── scripts/
```
