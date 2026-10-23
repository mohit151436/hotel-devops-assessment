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
    condition     = var.environment == "prod"
    error_message = "This root module is the prod environment; environment must be \"prod\"."
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
  description = "Share one NAT gateway across AZs. Must be false in prod so one AZ outage can't cut off the others."
  type        = bool

  validation {
    condition     = var.single_nat_gateway == false
    error_message = "Prod must use one NAT gateway per AZ (single_nat_gateway = false)."
  }
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

  validation {
    condition     = var.min_capacity >= 2
    error_message = "Prod must run at least 2 tasks for availability."
  }
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

  validation {
    condition     = var.db_multi_az
    error_message = "Prod RDS must be Multi-AZ."
  }
}

variable "db_backup_retention_period" {
  description = "Automated backup retention (days)."
  type        = number

  validation {
    condition     = var.db_backup_retention_period >= 7
    error_message = "Prod must keep automated backups for at least 7 days."
  }
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection."
  type        = bool

  validation {
    condition     = var.db_deletion_protection
    error_message = "Prod RDS must have deletion protection enabled."
  }
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy."
  type        = bool

  validation {
    condition     = var.db_skip_final_snapshot == false
    error_message = "Prod must take a final snapshot before the database is ever deleted."
  }
}

variable "db_apply_immediately" {
  description = "Apply RDS changes immediately rather than in the maintenance window."
  type        = bool
}
