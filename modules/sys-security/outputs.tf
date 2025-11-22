output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}

