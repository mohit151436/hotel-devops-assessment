output "alb_dns_name" {
  description = "Public DNS name of the ALB (the application URL)."
  value       = aws_lb.this.dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID of the ECS tasks. The RDS security group allows only this group."
  value       = aws_security_group.ecs.id
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.app.name
}

output "log_group_name" {
  description = "CloudWatch log group for the application container."
  value       = aws_cloudwatch_log_group.app.name
}
