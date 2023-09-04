#!/bin/bash

sudo -u ec2-user -i
# Actualizar e instalar MariaDB
sudo dnf update -y
sudo dnf install mariadb105 -y

# Configurar MySQL
mysql -h ${db_host} -u ${db_user} --password=${db_password} <<EOF
CREATE DATABASE IF NOT EXISTS webappdb;
USE webappdb;

CREATE TABLE IF NOT EXISTS transactions(id INT NOT NULL AUTO_INCREMENT, amount DECIMAL(10,2), description VARCHAR(100), PRIMARY KEY(id));

INSERT INTO transactions (amount,description) VALUES ('400','groceries');
EOF

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc
nvm install 16
nvm use 16
npm install -g pm2

cd ~/
aws s3 cp s3://${s3_bucket_name}/app-tier/ app-tier --recursive

cd ~/app-tier
npm install

pm2 start index.js
pm2 list
pm2 startup

#copy.....

pm2 save

# rm /var/lib/cloud/instances/instance-id/
