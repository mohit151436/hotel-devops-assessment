variable "name" {
  description = "Name prefix / identifier for the RDS resources (e.g. hotel-dev)."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the RDS security group in."
  type        = string
}

variable "database_subnet_ids" {
  description = "Isolated database subnets (at least two AZs) for the DB subnet group."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the database, keyed by a static label (e.g. { ecs = sg-123 }). In this design, only the ECS tasks."
  type        = map(string)
}

variable "engine_version" {
  description = "PostgreSQL engine version. A major version (e.g. \"16\") lets RDS pick the latest minor version."
  type        = string
  default     = "16"
}

variable "parameter_group_family" {
  description = "DB parameter group family. Must match the engine major version."
  type        = string
  default     = "postgres16"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
}

variable "max_allocated_storage" {
  description = "Upper limit in GiB for storage autoscaling."
  type        = number
}

variable "multi_az" {
  description = "Run a synchronous standby in a second AZ for automatic failover."
  type        = bool
}

variable "db_name" {
  description = "Name of the initial database."
  type        = string
  default     = "hotel"
}

variable "master_username" {
  description = "Master username. The password is generated and rotated by RDS in Secrets Manager."
  type        = string
  default     = "hotel_admin"
}

variable "backup_retention_period" {
  description = "Days to keep automated backups (enables point-in-time recovery). 0 disables backups."
  type        = number

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "Daily UTC window for automated backups (must not overlap the maintenance window)."
  type        = string
  default     = "20:00-21:00"
}

variable "maintenance_window" {
  description = "Weekly UTC maintenance window."
  type        = string
  default     = "sun:21:30-sun:22:30"
}

variable "deletion_protection" {
  description = "Block deletion of the database through the API or Terraform."
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when the database is destroyed. Should be false for prod."
  type        = bool
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights for query-level monitoring."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply modifications immediately instead of in the next maintenance window."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
