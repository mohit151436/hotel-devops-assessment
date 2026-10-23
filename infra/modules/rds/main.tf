# ---------------------------------------------------------------------------
# Security group: PostgreSQL only from the allowed (ECS) security groups.
# No CIDR rules, no egress rules. Terraform removes AWS's default allow-all
# egress rule from security groups it manages.
# ---------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "RDS PostgreSQL: accepts connections only from ECS tasks."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-rds-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  for_each = var.allowed_security_group_ids

  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from ${each.key}"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = each.value
}

# ---------------------------------------------------------------------------
# Networking and parameters
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-db-subnets"
  description = "Isolated database subnets for ${var.name}"
  subnet_ids  = var.database_subnet_ids

  tags = var.tags
}

resource "aws_db_parameter_group" "this" {
  name        = "${var.name}-${var.parameter_group_family}"
  family      = var.parameter_group_family
  description = "PostgreSQL parameters for ${var.name}"

  # Reject unencrypted client connections.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # Log any statement slower than 500 ms to CloudWatch for query tuning.
  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Database instance
# ---------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier = var.name

  engine                     = "postgres"
  engine_version             = var.engine_version
  auto_minor_version_upgrade = true
  instance_class             = var.instance_class
  parameter_group_name       = aws_db_parameter_group.this.name

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.master_username
  port     = 5432

  # RDS generates the password and stores it in Secrets Manager, so it never
  # appears in code, tfvars or Terraform state.
  manage_master_user_password         = true
  iam_database_authentication_enabled = true

  # Private only: isolated subnets, no public IP, ECS-only security group.
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = true
  delete_automated_backups  = !var.deletion_protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  apply_immediately = var.apply_immediately

  tags = merge(var.tags, { Name = var.name })
}
