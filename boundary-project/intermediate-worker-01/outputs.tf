output "bastion_public_ip" {
  value = try(aws_instance.bastion[0].public_ip, null)
}

output "bastion_private_ip" {
  value = try(aws_instance.bastion[0].private_ip, null)
}

output "worker_private_ip" {
  value = try(aws_instance.worker[0].private_ip, null)
}

output "profile_ec2_private_ip" {
  value = try(aws_instance.profile_ec2[0].private_ip, null)
}
