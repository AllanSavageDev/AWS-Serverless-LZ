output "api_endpoint" {
  value = module.sys_lambda.api_gateway_endpoint
}

output "api_gateway_url" {
  value = module.sys_lambda.api_gateway_endpoint
}

output "cloudfront_url" {
  value = "https://${module.sys_www.cloudfront_domain_name}"
}

output "rds_endpoint" {
  value = module.sys_rds.db_host
}

output "bastion_ip" {
  value = module.sys_bastion.bastion_public_ip
}
output "bastion_instance_id" {
  value = module.sys_bastion.bastion_instance_id
}

output "module_path" {
  value = path.module
}
