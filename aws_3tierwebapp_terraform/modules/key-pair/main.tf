# Key Pair for the Public Web Server
resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "MyAWSKey.pem"
}

resource "aws_key_pair" "key_pair_publicserver" {
  key_name   = var.key-pair_name
  public_key = tls_private_key.generated.public_key_openssh
}