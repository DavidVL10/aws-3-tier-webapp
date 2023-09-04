data "template_file" "db_config" {
  template = file("${path.module}/DbConfig.tpl")

  vars = {
    db_host = var.db_host
    db_user = var.db_user
    db_pwd  = var.db_pwd
  }
}

resource "local_file" "create_db_config_file" {
  content  = data.template_file.db_config.rendered
  filename = "C://Users//dveg7//OneDrive//Documentos//AWS//3 Tier Web App Project//aws-three-tier-web-architecture-workshop-main//application-code//app-tier//DbConfig.js"
}

resource "aws_s3_object" "dbconfig_file" {

  bucket = var.s3_bucket-id
  key    = "app-tier/DbConfig.js"
  source = local_file.create_db_config_file.source
}