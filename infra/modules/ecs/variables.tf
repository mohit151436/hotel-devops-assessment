variable "name" {
  description = "Name prefix for ECS and ALB resources (e.g. hotel-dev). Keep it short: ALB and target group names are limited to 32 characters."
  type        = string

  validation {
    condition     = length(var.name) <= 24
    error_message = "name must be 24 characters or less so derived ALB/target group names stay under 32 characters."
  }
}

variable "aws_region" {
  description = "AWS region, used for the CloudWatch Logs driver configuration."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the security groups and target group in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the internet-facing ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets for the Fargate tasks."
  type        = list(string)
}

variable "container_image" {
  description = "Container image for the application. A plain Nginx image is used as a placeholder backend."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27-alpine"
}

variable "container_port" {
  description = "Port the application container listens on."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path the ALB uses to check task health."
  type        = string
  default     = "/"
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)."
  type        = number

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.task_cpu)
    error_message = "task_cpu must be a valid Fargate CPU value."
  }
}

variable "task_memory" {
  description = "Fargate task memory in MiB. Must be a valid combination with task_cpu."
  type        = number
}

variable "desired_count" {
  description = "Initial number of running tasks. After creation, autoscaling owns this value."
  type        = number
}

variable "min_capacity" {
  description = "Minimum number of tasks for service autoscaling."
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of tasks for service autoscaling."
  type        = number
}

variable "cpu_target_percent" {
  description = "Average CPU utilisation the service autoscaler tries to maintain."
  type        = number
  default     = 60
}

variable "log_retention_days" {
  description = "How long to keep container logs in CloudWatch."
  type        = number
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights on the cluster."
  type        = bool
  default     = true
}

variable "alb_deletion_protection" {
  description = "Prevent the ALB from being deleted accidentally."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN. When set, the ALB serves HTTPS on 443 and redirects HTTP to HTTPS. When null, the ALB serves plain HTTP on 80."
  type        = string
  default     = null
}

variable "db_host" {
  description = "Database hostname passed to the application."
  type        = string
}

variable "db_port" {
  description = "Database port passed to the application."
  type        = number
}

variable "db_name" {
  description = "Database name passed to the application."
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the database username and password (managed by RDS)."
  type        = string
}

variable "tags" {
  description = "Extra tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
