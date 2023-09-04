resource "aws_instance" "public_server" {
  ami                         = var.ec2_ami
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
  security_groups             = var.public-ec2_sg
  associate_public_ip_address = true
  key_name                    = var.key-pair
  iam_instance_profile        = var.instance_profile
  depends_on                  = [var.nginx_file]
  connection {
    user        = "ec2-user"
    private_key = var.key_pem
    host        = self.public_ip
  }

  provisioner "file" {
    source      = var.batch_script_path
    destination = "batch_script.sh"

  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y dos2unix",
      "cd",
      "dos2unix batch_script.sh",
      "chmod 777 batch_script.sh",
      "./batch_script.sh",
    ]
  }

  tags = {
    Name = "Public WebTier EC2 Server"
  }

  lifecycle {
    ignore_changes = [security_groups]
  }

}

