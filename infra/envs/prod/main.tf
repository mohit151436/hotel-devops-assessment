# Internet -> ALB (public subnets) -> ECS/Fargate (private subnets) -> RDS (database subnets)

locals {
  name = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  single_nat_gateway = var.single_nat_gateway
}

module "ecs" {
  source = "../../modules/ecs"

  name               = local.name
  aws_region         = var.aws_region
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  container_image   = var.container_image
  container_port    = var.container_port
  health_check_path = var.health_check_path
  task_cpu          = var.task_cpu
  task_memory       = var.task_memory
  desired_count     = var.desired_count
  min_capacity      = var.min_capacity
  max_capacity      = var.max_capacity

  log_retention_days      = var.log_retention_days
  alb_deletion_protection = var.alb_deletion_protection
  certificate_arn         = var.certificate_arn

  db_host       = module.rds.address
  db_port       = module.rds.port
  db_name       = module.rds.db_name
  db_secret_arn = module.rds.master_user_secret_arn
}

module "rds" {
  source = "../../modules/rds"

  name                = local.name
  vpc_id              = module.network.vpc_id
  database_subnet_ids = module.network.database_subnet_ids

  # The only way into the database: from the ECS tasks' security group.
  allowed_security_group_ids = {
    ecs = module.ecs.ecs_security_group_id
  }

  db_name                 = var.db_name
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.db_skip_final_snapshot
  apply_immediately       = var.db_apply_immediately
}
