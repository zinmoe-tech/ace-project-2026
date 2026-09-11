# Azure to HCP Vault public connectivity

Use this guide first. Boundary cannot request SSH certificates from Vault until
the Boundary worker in Azure can reach the HCP Vault public URL.

For the full picture, see
[Boundary with HCP Vault overall diagram](overall-architecture-diagram.md).

For this lab, use the public Vault URL:

```text
https://vault-cluster-public-vault-ca07e311.e1ca4617.z1.hashicorp.cloud:8200
```

Do not save Vault tokens in Markdown files, Terraform files, Git, screenshots,
or chat messages. Treat a Vault token like a password.

## What needs to connect

Only the Boundary worker or controller needs network access to Vault:

```text
Boundary worker in Azure ---> HCP Vault public URL on TCP 8200
```

The Linux target VMs do not need to connect to Vault. Later, they only need the
Vault SSH CA public key installed locally.

## Step 1: check HCP Vault public access

In the HCP portal:

1. Open your HCP Vault cluster.
2. Open `Cluster networking`.
3. Confirm public access is enabled.
4. If an IP allow list is enabled, add the outbound public IP used by your Azure
   Boundary worker.

## Step 2: check Azure outbound access

In the Azure portal:

1. Open the Boundary worker VM.
2. Open `Networking`.
3. Open the network security group attached to the VM or subnet.
4. Confirm outbound TCP `8200` is allowed.

Most Azure NSGs allow outbound internet traffic by default. If your lab uses a
custom deny rule, add an allow rule for Vault:

```text
Direction: Outbound
Protocol: TCP
Port: 8200
Destination: Internet
Action: Allow
```

## Step 3: test from the Boundary worker

SSH to the Boundary worker VM and run:

```bash
curl https://vault-cluster-public-vault-ca07e311.e1ca4617.z1.hashicorp.cloud:8200/v1/sys/health
```

If it works, Vault returns a small JSON response. The HTTP status can be `200`,
`429`, `472`, `473`, or `501` depending on Vault state. Any Vault JSON response
is enough for this connectivity test.

If the command times out or says it cannot connect, check:

- HCP Vault public access is enabled.
- HCP Vault IP allow list includes the Azure outbound public IP.
- Azure NSG allows outbound TCP `8200`.
- The Boundary worker VM has internet access.

After this test works, continue with `ssh-certificate-injection.md`.
