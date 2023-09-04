data "template_file" "public_server_batch_script" {
  template = file("${path.module}/batch_script.tpl")

  vars = {
    s3_bucket_name = var.s3_bucket_name
  }
}

resource "local_file" "batch_script_file" {
  content  = data.template_file.public_server_batch_script.rendered
  filename = "batch_script.sh"
}