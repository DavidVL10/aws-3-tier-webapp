resource "aws_instance" "private_server" {
  ami                  = var.ec2_ami
  instance_type        = "t2.micro"
  subnet_id            = var.subnet_id
  security_groups      = var.private-ec2_sg
  iam_instance_profile = var.instance_profile
  #user_data            = filebase64("${var.user-data}")

  tags = {
    Name = "Private AppTier EC2 Server"
  }

  lifecycle {
    ignore_changes = [security_groups]
  }

}