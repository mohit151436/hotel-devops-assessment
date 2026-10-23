output "app_url" {
  description = "URL of the application behind the ALB."
  value       = "${var.certificate_arn == null ? "http" : "https"}://${module.ecs.alb_dns_name}"
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.ecs.service_name
}

output "rds_address" {
  description = "Private hostname of the RDS instance (reachable only from ECS tasks)."
  value       = module.rds.address
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN holding the database master credentials."
  value       = module.rds.master_user_secret_arn
}
