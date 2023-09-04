/*
Name: 3-Tier Web App Project
Description: AWS Infrastructure Build out
Contributors: David Vega Leon
*/

module "vpc" {
  source   = "../modules/vpc"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
}

module "security-group" {
  source = "../modules/security-group"
  vpc_id = module.vpc.vpc_id
}

module "rds-mysql" {
  source                = "../modules/rds-mysql"
  private_subnets_db_id = [module.vpc.private_subnet_db_1_id, module.vpc.private_subnet_db_2_id]
  db_name               = var.db_name
  db_user               = var.db_user
  db_password           = sensitive(var.db_password)
  db_az                 = module.vpc.availability_zones[0]
  db_sg                 = [module.security-group.db_sg_id]
}

module "db-config" {
  source       = "../modules/db-config"
  db_host      = module.rds-mysql.rds_endpoint
  db_user      = var.db_user
  db_pwd       = var.db_password
  s3_bucket-id = module.s3_bucket.s3_bucket_id
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "webapp-project-${random_id.s3-bucket-id.hex}"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

}

resource "random_id" "s3-bucket-id" {
  byte_length = 6
}

# Upload the app-tier folder with the code for the app tier
resource "aws_s3_object" "webapp_code" {
  for_each = fileset(var.folder_path, "**/*")

  bucket = module.s3_bucket.s3_bucket_id
  key    = each.value
  source = "${var.folder_path}/${each.value}"
}

module "private-ec2-batch_script" {
  source         = "../modules/private-ec2-batch_script"
  db_host        = module.rds-mysql.rds_endpoint
  s3_bucket_name = module.s3_bucket.s3_bucket_id
  db_user        = var.db_user
  db_password    = var.db_password
}

module "ec2-iam-role" {
  source  = "Smartbrood/ec2-iam-role/aws"
  name    = var.ec2_role_name
  version = "0.4.0"

  policy_arn = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

# Terraform Data Block - To Lookup Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

module "private-ec2-server" {
  source           = "../modules/private-ec2-server"
  ec2_ami          = data.aws_ami.amazon_linux.id
  subnet_id        = module.vpc.private_subnet_1_id
  private-ec2_sg   = [module.security-group.private_servers_sg_id]
  instance_profile = module.ec2-iam-role.profile_name
  #user-data        = module.private-ec2-batch_script.user_data_path
}



# Create My own AMI from the private server apptier
resource "aws_ami_from_instance" "app-tier-ami" {
  name               = "AppTier AMI"
  source_instance_id = module.private-ec2-server.private_server_id
  description        = "App Tier AMI"
}

# ALB for the private app instances
module "private_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = var.private_alb_name

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = [module.vpc.private_subnet_1_id, module.vpc.private_subnet_2_id]
  security_groups = [module.security-group.private_alb_sg_id]
  internal        = true
  target_groups = [
    {
      name_prefix      = "apptie"
      backend_protocol = "HTTP"
      backend_port     = 4000
      target_type      = "instance"
      health_check = {
        protocol = "HTTP"
        path     = "/health"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

}

# Autoscaling group and private launch template for the private instances
module "private_asg" {
  source = "terraform-aws-modules/autoscaling/aws"


  # Autoscaling group
  name = var.private_asg_name

  min_size                  = 2
  max_size                  = 2
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "ELB"
  vpc_zone_identifier       = [module.vpc.private_subnet_1_id, module.vpc.private_subnet_2_id]
  target_group_arns         = [module.private_alb.target_group_arns[0]]

  # Launch template
  launch_template_name = var.private_launch-template_name
  image_id             = aws_ami_from_instance.app-tier-ami.id
  instance_type        = "t2.micro"

  create_iam_instance_profile = false
  iam_instance_profile_name   = module.ec2-iam-role.profile_name

  security_groups = [module.security-group.private_servers_sg_id]

}

module "nginx-config" {
  source          = "../modules/nginx-config"
  private-alb-dcn = module.private_alb.lb_dns_name
  s3_bucket-id    = module.s3_bucket.s3_bucket_id
}

module "public-ec2-batch_script" {
  source         = "../modules/public-ec2-batch_script"
  s3_bucket_name = module.s3_bucket.s3_bucket_id
}

module "key-pair" {
  source        = "../modules/key-pair"
  key-pair_name = var.key-pair_name
}

module "public-ec2-server" {
  source            = "../modules/public-ec2-server"
  ec2_ami           = data.aws_ami.amazon_linux.id
  subnet_id         = module.vpc.public_subnet_1_id
  public-ec2_sg     = [module.security-group.webtier_servers_sg_id, module.security-group.ssh_access_sg_id]
  key-pair          = module.key-pair.key_pair
  instance_profile  = module.ec2-iam-role.profile_name
  key_pem           = module.key-pair.key_pem
  batch_script_path = module.public-ec2-batch_script.batch_script_path
  nginx_file        = module.nginx-config

}

# Create My own AMI from the public server webtier
resource "aws_ami_from_instance" "web-tier-ami" {
  name               = "WebTier AMI"
  source_instance_id = module.public-ec2-server.public_server_id
  description        = "Web Tier AMI"
}

# ALB for the public web instances
module "public_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = var.public_alb_name

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
  security_groups = [module.security-group.public_alb_sg_id]

  target_groups = [
    {
      name_prefix      = "webtg"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        protocol = "HTTP"
        path     = "/health"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

}

# Autoscaling group and launch template for the public web instances
module "public_asg" {
  source = "terraform-aws-modules/autoscaling/aws"


  # Autoscaling group
  name = var.public_asg_name

  min_size                  = 2
  max_size                  = 2
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "ELB"
  vpc_zone_identifier       = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
  target_group_arns         = [module.public_alb.target_group_arns[0]]

  # Launch template
  launch_template_name = var.public_launch-template_name
  image_id             = aws_ami_from_instance.web-tier-ami.id
  instance_type        = "t2.micro"

  create_iam_instance_profile = false
  iam_instance_profile_name   = module.ec2-iam-role.profile_name

  security_groups = [module.security-group.webtier_servers_sg_id]

}

