output "public_alb_sg_id" {
  value = aws_security_group.public_alb_sg.id
}

output "webtier_servers_sg_id" {
  value = aws_security_group.webtier_servers_sg.id
}

output "private_alb_sg_id" {
  value = aws_security_group.private_alb_sg.id
}

output "private_servers_sg_id" {
  value = aws_security_group.private_servers_sg.id
}

output "db_sg_id" {
  value = aws_security_group.db_sg.id
}

output "ssh_access_sg_id" {
  value = aws_security_group.ssh_access_sg.id
}