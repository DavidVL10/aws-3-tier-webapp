output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "availability_zones" {
  value = local.availability_zones
}

output "private_subnet_1_id" {
  value = aws_subnet.private_subnets[0].id
}

output "private_subnet_2_id" {
  value = aws_subnet.private_subnets[1].id
}

output "private_subnet_db_1_id" {
  value = aws_subnet.private_subnets_db[0].id
}

output "private_subnet_db_2_id" {
  value = aws_subnet.private_subnets_db[1].id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_subnets[0].id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_subnets[1].id
}