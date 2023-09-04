data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    db_host        = var.db_host
    s3_bucket_name = var.s3_bucket_name
    db_user        = var.db_user  
    db_password    = var.db_password
  }
}

resource "local_file" "user-data_file" {
  content  = data.template_file.user_data.rendered
  filename = "user_data.sh"
}