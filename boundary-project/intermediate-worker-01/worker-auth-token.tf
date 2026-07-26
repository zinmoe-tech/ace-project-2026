# Fetches the PKI worker's self-generated auth_request_token so it can be
# handed to `boundary workers create worker-led` without SSHing in by hand.
#
# The token doesn't exist until boundary-worker.service has actually started
# on the worker (see packer/files/render-boundary-config.sh) — it's written
# to auth_storage_path on first successful start, not baked into the AMI.
# The worker sits in a private subnet, so this reaches it by proxying
# through the bastion, the same path a human would use.
#
# Gated on both instances existing: the bastion is the only thing with a
# route to the worker's private IP, and the worker is what generates the
# token in the first place.
resource "null_resource" "fetch_worker_auth_token" {
  count = var.create_worker_instance && var.create_bastion_instance ? 1 : 0

  triggers = {
    worker_instance_id = aws_instance.worker[0].id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      BASTION_IP="${aws_instance.bastion[0].public_ip}"
      WORKER_IP="${aws_instance.worker[0].private_ip}"
      BASTION_KEY="${path.module}/../../jump-host-key-pair.pem"
      WORKER_KEY="${path.module}/../../self-managed-worker-01.pem"
      SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"

      ssh_worker() {
        ssh $SSH_OPTS \
          -o ProxyCommand="ssh $SSH_OPTS -i $BASTION_KEY -W %h:%p ubuntu@$BASTION_IP" \
          -i "$WORKER_KEY" ubuntu@"$WORKER_IP" "$1"
      }

      for i in $(seq 1 30); do
        if ssh_worker "sudo test -f /etc/boundary.d/worker/auth_request_token"; then
          break
        fi
        echo "waiting for auth_request_token to be generated ($i/30)..." >&2
        sleep 10
      done

      ssh_worker "sudo cat /etc/boundary.d/worker/auth_request_token" > "${path.module}/.worker-auth-token"
    EOT
  }
}

data "local_file" "worker_auth_token" {
  count = var.create_worker_instance && var.create_bastion_instance ? 1 : 0

  filename   = "${path.module}/.worker-auth-token"
  depends_on = [null_resource.fetch_worker_auth_token]
}

output "worker_auth_request_token" {
  description = "PKI worker's self-generated auth request token, for `boundary workers create worker-led -worker-generated-auth-token=<this>`."
  value       = var.create_worker_instance && var.create_bastion_instance ? trimspace(data.local_file.worker_auth_token[0].content) : null
  sensitive   = true
}
