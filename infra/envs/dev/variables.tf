# ---------------------------------------------------------------------------
# General
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "project" {
  description = "Project name, used as a name prefix and tag."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string

  validation {
    condition     = var.environment == "dev"
    error_message = "This root module is the dev environment; environment must be \"dev\"."
  }
}

variable "plan_only" {
  description = "Mock AWS credentials so `plan -refresh=false` runs without an AWS account. For review and CI only."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "azs" {
  description = "Availability zones to use."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway across AZs to save cost."
  type        = bool
}

# ---------------------------------------------------------------------------
# ECS / ALB
# ---------------------------------------------------------------------------

variable "container_image" {
  description = "Application container image."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27-alpine"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALB health check path."
  type        = string
  default     = "/"
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
}

variable "task_memory" {
  description = "Fargate task memory (MiB)."
  type        = number
}

variable "desired_count" {
  description = "Initial number of tasks."
  type        = number
}

variable "min_capacity" {
  description = "Autoscaling minimum task count."
  type        = number
}

variable "max_capacity" {
  description = "Autoscaling maximum task count."
  type        = number
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the app."
  type        = number
}

variable "alb_deletion_protection" {
  description = "Enable ALB deletion protection."
  type        = bool
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN to enable HTTPS on the ALB."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# RDS
# ---------------------------------------------------------------------------

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "db_allocated_storage" {
  description = "Initial RDS storage (GiB)."
  type        = number
}

variable "db_max_allocated_storage" {
  description = "RDS storage autoscaling limit (GiB)."
  type        = number
}

variable "db_multi_az" {
  description = "Run RDS in Multi-AZ mode."
  type        = bool
}

variable "db_backup_retention_period" {
  description = "Automated backup retention (days)."
  type        = number
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection."
  type        = bool
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy."
  type        = bool
}

variable "db_apply_immediately" {
  description = "Apply RDS changes immediately rather than in the maintenance window."
  type        = bool
}
