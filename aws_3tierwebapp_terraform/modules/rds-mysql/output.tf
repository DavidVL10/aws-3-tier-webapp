output "rds_endpoint" {
  description = "Endpoint of the RDS DB"
  value       = aws_db_instance.db_mysql.address
}