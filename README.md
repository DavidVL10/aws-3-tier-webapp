# AWS Infrastructure Deployment with Terraform :computer:

## This comprehensive project showcases the power of Infrastructure as Code (IaC) through Terraform, focusing on AWS deployment.

#### :pushpin: Key Features:

- IaC Mastery: Gain hands-on experience with Terraform, a leading IaC tool.
- AWS Expertise: Explore AWS services, provisioning, and configuration.
- Inventory Web App: Create a dynamic web application for managing an inventory system.
- Database Integration: Learn how to add, update, and retrieve items from a database.
- Full Functionality: Experience a fully operational system from start to finish.

#### :clipboard: This project shows how to do the following:

- Create an isolated network with the following components:
  
  - VPC
  - Subnets
  - Route Tables
  - Internet Gateway
  - NAT gateway
  - Security Groups
    
- Deploy Database Layer:
  
  - Subnet Groups
  - RDS Database

- S3 Bucket:

  - Create a S3 Bucket :file_folder:
  - Upload an object to our S3 Bucket

- Create an EC2 Instance:
    
  - IAM EC2 Instance Profile creation
  - Use a Terraform Data Block to look up for a specific AMI :mag_right:
  - Create an EC2 Instance
  - Generate a Key Pair for our Public Web Server :key:
  - Connect to the EC2 intance using Session Manager and SSH
  - Copy objects from S3
    
- Batch Script
  
  - Create a batch script to configure our EC2 instance :bookmark_tabs:
    
- Load Balancers and Auto Scaling Groups:
  
  - Create an AMI 
  - Create a Launch Template
  - Configure the ASG
  - Deploy Load Balancers

## Architecture Overview :mag_right:

<img src="https://miro.medium.com/v2/resize:fit:761/1*DvuvxEPeuCgjefJugj4Idg.jpeg" alt="Descripción de la imagen" />

In this architecture, a public-facing Application Load Balancer forwards client traffic to our web tier EC2 instances. The web tier is running Nginx web servers that are configured to serve a React.js website and redirects our API calls to the application tier’s internal facing load balancer. The internal facing load balancer then forwards that traffic to the application tier, which is written in Node.js. The application tier manipulates data in a RDS MySQL database and returns it to our web tier. Load balancing, health checks, and auto-scaling groups are created at each layer to maintain the availability of this architecture.

## How to deploy this 3-Tier WebApp project on Terraform :bulb:

1. In the file **terraform.tfvars** change the path where you save the folder application-code
```
folder_path = "[Your Path]"
```   
2. In AWS, generate an access key and secret key :key: from an IAM user with Administrative privileges. Once you have credentials, set the following environment variables for Linux, MacOS, or Bash on Windows:
```
export AWS_ACCESS_KEY_ID="<YOUR ACCESS KEY>"
export AWS_SECRET_ACCESS_KEY="<YOUR SECRET KEY>"
```
If you’re running PowerShell on Windows, you’ll need to use the following to set your AWS credentials:
```
PS C:\> $Env:AWS_ACCESS_KEY_ID="<YOUR ACCESS KEY>"
PS C:\> $Env:AWS_SECRET_ACCESS_KEY="<YOUR SECRET KEY>"
```
If you’re using the default Windows command prompt, you can use the following to set your AWS credentials:
```
C:\> setx AWS_ACCESS_KEY_ID <YOUR ACCESS KEY>
C:\> setx AWS_SECRET_ACCESS_KEY <YOUR SECRET KEY>
```
3. Set up the environment for your Terraform project
```
terraform init
```
4. The deployment of the infrastructure will be step by step, comment all the code that is after the module "Private-EC2-Server" in our main.tf 
5. Run the command
```
terraform apply -auto-approve
```
6. Use the AWS Management Console to connect to the Private AppTier EC2 Server Instance.
**For the step 6 you must use all the commands of the userer_data.sh that is created in the root folder, this is just an example**

6.1 When you first connect to your instance like this, you will be logged in as ssm-user which is the default user. Switch to ec2-user by executing the following command in the browser terminal:
```
sudo -u ec2-user -i
```
6.2 Configure the database
```
sudo dnf update -y
sudo dnf install mariadb105 -y

# Configurar MySQL
mysql -h terraform-20230904082833027800000006.ca56pdjfburr.us-east-1.rds.amazonaws.com -u admin --password=project1234 <<EOF
CREATE DATABASE IF NOT EXISTS webappdb;
USE webappdb;

CREATE TABLE IF NOT EXISTS transactions(id INT NOT NULL AUTO_INCREMENT, amount DECIMAL(10,2), description VARCHAR(100), PRIMARY KEY(id));

INSERT INTO transactions (amount,description) VALUES ('400','groceries');
EOF
```   
6.3  Install all the necessary components to run our backend application. 
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc
nvm install 16
nvm use 16
npm install -g pm2
```
6.4  Download the code from your S3 Bucket:
```
cd ~/
aws s3 cp s3://webapp-project-ded089ac429f/app-tier/ app-tier --recursive
```
6.5 Verify that the DbConfig file.js is not empty if so, run the following commands:

On Terraform
```
terraform apply -replace="module.db-config.aws_s3_object.dbconfig_file"
```
Private AppTier EC2 Server instance
```
cd app-tier/
aws s3 cp s3://**BUCKET_NAME**/app-tier/DbConfig.js DbConfig.js 
```
6.6 Start the app with pm2, make sure the app is running correctly
```
cd ~/app-tier
npm install
pm2 start index.js
pm2 list
pm2 startup
```
After running this you will see a message similar to this.
**[PM2] To setup the Startup Script, copy/paste the following command: sudo env PATH=$PATH:/home/ec2-user/.nvm/versions/node/v16.0.0/bin /home/ec2-user/.nvm/versions/node/v16.0.0/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user —hp /home/ec2-user**

6.7 DO NOT run the above command, rather you should copy and past the command in the output you see in your own terminal. After you run it, save the current list of node processes with the following command:
```
pm2 save
```
6.8 Test the App Tier:
- To hit out health check endpoint, copy this command into your SSM terminal. This is our simple health check endpoint that tells us if the app is simply running. The response should looks like the following -> "This is the health check"
```
curl http://localhost:4000/health
```
- Next, test your database connection. You can do that by hitting the following endpoint locally. The response should looks like the following -> {"result":[{"id":1,"amount":400,"description":"groceries"},{"id":2,"amount":100,"description":"class"},{"id":3,"amount":200,"description":"other groceries"},{"id":4,"amount":10,"description":"brownies"}]}
```
curl http://localhost:4000/transaction
```
7. Create the Public Web Server so uncomment until the module "public-ec2-server" and run on terraform:
```
terraform apply -auto-approve
```
9. Uncomment the pending code and run on terraform:
```
terraform apply -auto-approve
```

:white_check_mark: Congratulations you finished your WebApp, copy in your browser the DNS Name of your public-alb-webtier to access your application :white_check_mark:

:triangular_flag_on_post:
**Don't forget to destroy your resources on AWS to avoid being charged**
```
terraform destroy -auto-approve
```

