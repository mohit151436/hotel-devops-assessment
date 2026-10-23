# Prod: highly available, larger, protected against accidental deletion.

aws_region  = "ap-south-1"
project     = "hotel"
environment = "prod"

# Network
vpc_cidr           = "10.20.0.0/16"
azs                = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
single_nat_gateway = false # one NAT gateway per AZ

# ECS / ALB
task_cpu                = 1024 # 1 vCPU
task_memory             = 2048
desired_count           = 2
min_capacity            = 2
max_capacity            = 6
log_retention_days      = 90
alb_deletion_protection = true

# Set this to an ACM certificate ARN to serve HTTPS (HTTP then redirects to HTTPS).
# certificate_arn = "arn:aws:acm:ap-south-1:123456789012:certificate/xxxx"

# RDS
db_name                    = "hotel"
db_instance_class          = "db.r6g.large"
db_allocated_storage       = 100
db_max_allocated_storage   = 500
db_multi_az                = true
db_backup_retention_period = 30   # 30 days of point-in-time recovery
db_deletion_protection     = true # cannot be deleted by accident
db_skip_final_snapshot     = false
db_apply_immediately       = false # changes wait for the maintenance window
