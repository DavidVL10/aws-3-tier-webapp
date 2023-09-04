#!/bin/bash

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc
nvm install 16
nvm use 16

cd ~/
aws s3 cp s3://${s3_bucket_name}/web-tier web-tier --recursive
cd ~/web-tier
npm install 
npm run build

sudo yum install -y wget
sudo wget https://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
sudo rpm -ivh nginx-release-centos-7-0.el7.ngx.noarch.rpm
sudo yum install -y nginx

cd /etc/nginx
sudo rm nginx.conf
sudo aws s3 cp s3://${s3_bucket_name}/nginx.conf /etc/nginx

sudo service nginx restart
sudo chmod -R 755 /home/ec2-user

sudo chkconfig nginx on