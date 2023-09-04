data "template_file" "nginx_config" {
  template = file("${path.module}/nginx.conf.tpl")

  vars = {
    private-alb-dcn = var.private-alb-dcn
  }
}

resource "local_file" "create_nginx_config_file" {
  content  = data.template_file.nginx_config.rendered
  filename = "C://Users//dveg7//OneDrive//Documentos//AWS//3 Tier Web App Project//aws-three-tier-web-architecture-workshop-main//application-code//nginx.conf"
}

resource "aws_s3_object" "nginx_file" {

  bucket = var.s3_bucket-id
  key    = "nginx.config"
  source = local_file.create_nginx_config_file.source
}