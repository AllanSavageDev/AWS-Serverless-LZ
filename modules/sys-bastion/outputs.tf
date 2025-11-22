output "bastion_instance_id" {
  description = "ID of the bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion instance"
  value       = aws_instance.bastion.public_ip
}

output "bastion_primary_eni_id" {
  description = "Primary ENI of the bastion host"
  value       = aws_instance.bastion.primary_network_interface_id
}
