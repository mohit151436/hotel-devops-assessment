output "address" {
  description = "Private DNS hostname of the database."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "security_group_id" {
  description = "Security group ID of the database."
  value       = aws_security_group.rds.id
}

output "instance_identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.identifier
}
