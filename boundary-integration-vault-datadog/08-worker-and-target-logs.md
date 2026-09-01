# Session 08 — Worker and Target Logs

## Goal

Observe the automatic process from the worker and the SSH target.

# Part A — Boundary Worker

Service:

```text
boundary-worker.service
```

Check:

```bash
systemctl status boundary-worker.service
```

Read CloudEvents JSON cleanly:

```bash
sudo journalctl -u boundary-worker.service \
  --since "2026-09-01 17:25:30" \
  --until "2026-09-01 17:27:20" \
  --no-pager \
  -o cat \
| jq
```

Why `-o cat`?

Without it, journal prefixes can cause:

```text
jq: parse error: Invalid numeric literal
```

## Evidence from the lab

Vault command:

```text
2026-09-01T17:25:55.138813044Z
Invoking command COMMAND_VAULT_PROXY_POST for worker: w_xQ5XFPEe0D
```

SSH handler:

```text
2026-09-01T17:26:04.111302823Z
ssh protocol handler successfully connected
connection id: sc_NckdASQaPL
```

Proxy chain:

```text
2026-09-01T17:26:04.111431497Z
multihop chain established
connection id: sc_NckdASQaPL
```

## What does `COMMAND_VAULT_PROXY_POST` prove?

It proves the worker received a command related to a Vault proxy POST.

By itself, it does not show the complete Vault API request body or signed response.

For that, Vault audit logging is the stronger evidence.

# Part B — Target SSHD

Enable verbose logging:

```bash
sudo tee /etc/ssh/sshd_config.d/99-boundary-pov.conf > /dev/null <<'EOF'
LogLevel VERBOSE
EOF

sudo sshd -t
sudo systemctl reload ssh
```

Live log:

```bash
sudo journalctl -u ssh -f
```

Historical filter:

```bash
sudo journalctl -u ssh \
  --since "2026-09-01 17:25:30" \
  --until "2026-09-01 17:27:30" \
  --no-pager \
  -o short-iso \
| grep -Ei "Accepted|certificate|CERT|vault-token|session opened"
```

## Evidence from the lab

Target logged:

```text
Accepted certificate ID "vault-token-..."
signed by RSA CA SHA256:<CA fingerprint>
via /etc/ssh/trusted-user-ca-keys.pem
```

Then:

```text
Accepted publickey for azureuser
from 10.1.10.4
ssh2: ED25519-CERT
```

Then:

```text
session opened for user azureuser
```

## What does this prove?

```text
source IP = worker
certificate type = SSH certificate
CA = trusted Vault CA
user = azureuser
authentication = successful
session = opened
```
