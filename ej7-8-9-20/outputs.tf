output "public_ip" {
  description = "IP pública de la instancia EC2"
  value       = module.ec2.public_ip
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = module.red.vpc_id
}

output "subnet_ids" {
  description = "IDs de subredes"
  value       = module.red.subnet_ids
}