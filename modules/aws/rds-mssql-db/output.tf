output "db_username" {
  value = local.db_username
}

output "db_password" {
  value = nonsensitive(local.db_password)
}

output "db_identifier" {
  value = local.db_identifier
}

output "db_address" {
  value = aws_db_instance.rds_db.address
}

output "db_endpoint" {
  value = aws_db_instance.rds_db.endpoint
}

output "db_arn" {
  value = aws_db_instance.rds_db.arn
}

output "db_engine" {
  value = aws_db_instance.rds_db.engine
}

output "db_port" {
  value = aws_db_instance.rds_db.port
}

