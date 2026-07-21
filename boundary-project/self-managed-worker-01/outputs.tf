output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}

output "worker_private_ip" {
  value = aws_instance.worker.private_ip
}

output "nat_gateway_public_ip" {
  value = aws_eip.nat.public_ip
}
