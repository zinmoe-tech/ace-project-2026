# Boundary with HCP Vault overall diagram

This diagram shows the lab flow when Azure uses the HCP Vault public endpoint.

```mermaid
flowchart LR
  user[User laptop\nBoundary CLI]

  subgraph hcp_boundary[HCP Boundary]
    boundary[Boundary controller]
  end

  subgraph azure[Azure: West US 2]
    rg[Resource group\nboundary_resource-west_us_2]
    vnet[VNet\nboundary-ingress-vn\n10.1.0.0/16]
    subnet[Subnet\nboundary-ingress-subnet\n10.1.100.0/24]
    worker1[ingress-worker-01\n10.1.100.4]
    worker2[ingress-worker-02\n10.1.100.5]
    nsg[NSG rules\nOutbound 9202 to Boundary\nOutbound 8200 to Vault]
  end

  subgraph hcp_vault[HCP Vault]
    vault[Vault public endpoint\nvault-cluster-public...\nTCP 8200]
    sshca[Vault SSH CA\nssh-client-signer]
  end

  subgraph targets[Linux target VMs]
    target[SSH target VM\ntrusts Vault CA public key]
  end

  user -->|boundary connect ssh| boundary
  boundary -->|session coordination| worker1
  boundary -->|session coordination| worker2

  worker1 -->|TCP 9202 outbound| boundary
  worker2 -->|TCP 9202 outbound| boundary

  worker1 -->|HTTPS TCP 8200\nrequest SSH certificate| vault
  worker2 -->|HTTPS TCP 8200\nrequest SSH certificate| vault
  vault --> sshca

  worker1 -->|SSH with short-lived cert| target
  worker2 -->|SSH with short-lived cert| target
  target -->|verifies cert signature locally| sshca

  rg --> vnet
  vnet --> subnet
  subnet --> worker1
  subnet --> worker2
  nsg --> worker1
  nsg --> worker2
```

## Important traffic

```text
Boundary worker ---> HCP Boundary controller/upstreams: TCP 9202
Boundary worker ---> HCP Vault public endpoint: TCP 8200
Boundary worker ---> Linux target VM: TCP 22
```

The Linux target VM does not need to connect to Vault during login. It only
checks that the SSH certificate was signed by the Vault SSH CA public key it
already trusts.
