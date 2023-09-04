output "key_pair" {
  value = aws_key_pair.key_pair_publicserver.key_name
}

output "key_pem" {
  value = tls_private_key.generated.private_key_pem  
}
