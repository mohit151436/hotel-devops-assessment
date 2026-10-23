# Dev: small, cheap and easy to tear down.

aws_region  = "ap-south-1"
project     = "hotel"
environment = "dev"

# Network
vpc_cidr           = "10.10.0.0/16"
azs                = ["ap-south-1a", "ap-south-1b"]
single_nat_gateway = true # one NAT gateway to save cost

# ECS / ALB
task_cpu                = 256 # 0.25 vCPU
task_memory             = 512
desired_count           = 1
min_capacity            = 1
max_capacity            = 2
log_retention_days      = 7
alb_deletion_protection = false

# RDS
db_name                    = "hotel"
db_instance_class          = "db.t4g.micro"
db_allocated_storage       = 20
db_max_allocated_storage   = 50
db_multi_az                = false
db_backup_retention_period = 1     # short retention
db_deletion_protection     = false # dev can be destroyed freely
db_skip_final_snapshot     = true
db_apply_immediately       = true
