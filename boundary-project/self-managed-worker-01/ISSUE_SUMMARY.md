# Issue Summary — Self-Managed Worker Packer Build

---

## Issue 1: HCP Packer publish fails after `packer build` — unzip exit code 50 (disk full)

**Error:**
```
Error: publishing build metadata to HCP Packer for "boundary-worker.amazon-ebs.boundary_worker" failed

build failed, not uploading artifacts

Build 'boundary-worker.amazon-ebs.boundary_worker' errored after 2 minutes 7 seconds: Script exited with non-zero exit status: 50. Allowed exit codes are: [0]
```

**Cause:** The HCP Packer publish failure is a downstream symptom, not the root cause — no artifact means nothing to publish. The real failure is the `shell` provisioner (`scripts/install-boundary.sh`) exiting 50, which is `unzip`'s exit code for "disk full during extraction" (`unzip -o /tmp/boundary.zip -d /tmp/boundary` at line 11). The `amazon-ebs` source in `packer/boundary-worker.pkr.hcl` had no `launch_block_device_mappings`, so the temporary build instance inherited the source Ubuntu AMI's default root volume (~8GB) — not enough headroom once `apt-get update`/`install` package caches and the downloaded + unpacked Boundary Enterprise zip land on the same filesystem.

**Fix:** Add an explicit larger root volume to the `amazon-ebs` source block in `packer/boundary-worker.pkr.hcl`:
```hcl
launch_block_device_mappings {
  device_name           = "/dev/sda1"
  volume_size           = 16
  volume_type           = "gp3"
  delete_on_termination = true
}
```

**Note:** `/dev/sda1` is the standard root device name for Canonical's Ubuntu AMIs. If the build still fails on the block device mapping, confirm the actual root device name via `aws ec2 describe-images` on the AMI ID Packer resolves.

**Update — root volume bump alone did not fix it:** Re-running after the `launch_block_device_mappings` change failed identically (same exit code, same ~2min duration), which means the root EBS volume was never the constraint. On Ubuntu cloud images `/tmp` is commonly a RAM-backed `tmpfs` sized ~50% of instance memory — completely independent of root disk size. `instance_type = "t3.micro"` only has 1GB RAM, so `/tmp` caps out around ~512MB, and the Boundary Enterprise zip alone is ~190MB; downloading the zip *and* unzipping it to another path under `/tmp` in the same script pushed that over the tmpfs limit.

**Real fix:** Do the download/extraction under `/opt` (root filesystem) instead of `/tmp`, in `packer/scripts/install-boundary.sh`:
```bash
WORKDIR=/opt/boundary-build
sudo mkdir -p "$WORKDIR"
sudo chown "$(id -u):$(id -g)" "$WORKDIR"

curl -fsSL -o "$WORKDIR/boundary.zip" "$BOUNDARY_URL"
unzip -o "$WORKDIR/boundary.zip" -d "$WORKDIR/boundary"
sudo mv "$WORKDIR/boundary/boundary" /usr/local/bin/boundary
rm -rf "$WORKDIR"
```
The `launch_block_device_mappings` addition is left in place (harmless, and gives headroom for `apt-get` package caches) but was not the actual fix.

---

## Issue 2: `rm: cannot remove '/opt/boundary-build': Permission denied`

**Error:**
```
==> boundary-worker.amazon-ebs.boundary_worker: rm: cannot remove '/opt/boundary-build': Permission denied
```

**Cause:** Introduced by the Issue 1 fix. `$WORKDIR` (`/opt/boundary-build`) was created with `sudo mkdir` then `chown`'d to the SSH user so `curl`/`unzip` could write into it without `sudo`. But `/opt` itself is root-owned (`755`) — deleting a directory *entry* requires write permission on its **parent**, not ownership of the directory being removed. The unqualified `rm -rf "$WORKDIR"` at the end of `install-boundary.sh` ran as the SSH user, which owns the directory's contents but not `/opt`.

**Fix:** Run the cleanup with `sudo`:
```bash
sudo rm -rf "$WORKDIR"
```

---

## Issue 3: `boundary-worker.service` restart-loops on first boot — `curl: (22) The requested URL returned error: 401`

**Error** (`journalctl -u boundary-worker` on the worker instance):
```
render-boundary-config.sh[717]: curl: (22) The requested URL returned error: 401
boundary-worker.service: Control process exited, code=exited, status=22/n/a
boundary-worker.service: Failed with result 'exit-code'.
boundary-worker.service: Start request repeated too quickly.
```

**Cause:** `packer/files/render-boundary-config.sh` (runs as `ExecStartPre`) fetched the instance's private IP from the EC2 metadata service with a plain, unauthenticated GET (IMDSv1-style). This worker instance enforces **IMDSv2** (token-required), which rejects unauthenticated metadata requests with `401`. `ExecStartPre` failing every time means `boundary-worker.service` never gets past the "render config" step, and Boundary itself never even starts — hits systemd's restart-rate limit and gives up (`Start request repeated too quickly`).

**Fix:** Get an IMDSv2 session token first, then pass it on the metadata request, in `packer/files/render-boundary-config.sh`:
```bash
IMDS_TOKEN=$(curl -fsSL -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
PRIVATE_ADDR=$(curl -fsSL -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)
```

**Two-part rollout:** The already-running worker instance was built from an AMI baked *before* this fix, so it needed the same patch applied live to `/usr/local/bin/render-boundary-config.sh` on the instance (via SSH) plus `sudo systemctl reset-failed boundary-worker && sudo systemctl restart boundary-worker` to clear the rate-limit and retry. The source fix in `packer/files/render-boundary-config.sh` only takes effect for AMIs built *after* this change — any worker instance already running on an older AMI needs the live patch too, and a future AMI rebuild + instance replacement to fully pick it up.

---
