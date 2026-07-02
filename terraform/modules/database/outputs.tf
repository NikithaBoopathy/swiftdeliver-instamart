output "rds_endpoint" {
  description = "The dynamic connection endpoint for the RDS instance"
  value       = aws_db_instance.postgres_db.endpoint
}

output "rds_database_name" {
  description = "The name of the default database"
  value       = aws_db_instance.postgres_db.db_name
}
