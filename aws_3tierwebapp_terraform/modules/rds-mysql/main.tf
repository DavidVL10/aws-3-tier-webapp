# RDS DB Subnet group
resource "aws_db_subnet_group" "rds_db_subnetgroup" {
  name        = "rds_db_subnetgroup"
  description = "Subnet group for the DB layer"
  subnet_ids  = var.private_subnets_db_id

  tags = {
    Name = "My DB subnet group"
  }
}

# RDS DB
resource "aws_db_instance" "db_mysql" {
  allocated_storage      = 20
  db_name                = var.db_name
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = var.db_user
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  availability_zone      = var.db_az
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds_db_subnetgroup.id
  publicly_accessible    = false
  vpc_security_group_ids = var.db_sg
}