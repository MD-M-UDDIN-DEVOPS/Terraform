# begins a single-line comment, ending at the end of the line.
// also begins a single-line comment, as an alternative to #.
/* and */ are start and end delimiters for a comment that might span over
multiple lines.

# IaC Buildout for Terraform Associate Exam
/*
Name: IaC Buildout for Terraform Associate Exam
Description: AWS Infrastructure Buildout
Contributors: Md
*/

### Configure the AWS Provider

provider "aws" {
region = "us-east-2"
}


####Retrieve the list of AZs in the current AWS region
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}


###Define the VPC
resource "aws_vpc" "vpc" {
cidr_block = var.vpc_cidr
tags = {
Name = var.vpc_name
Environment = "demo_environment"
Terraform = "true"
}
}


#Deploy the private subnets
resource "aws_subnet" "private_subnets" {
for_each = var.private_subnets
vpc_id = aws_vpc.vpc.id
cidr_block = cidrsubnet(var.vpc_cidr, 8, each.value)
availability_zone = tolist(data.aws_availability_zones.available.names)[
each.value]
tags = {
Name = each.key
Terraform = "true"
}
}
#Bootstrap Jenkins installation and start  
  user_data = <<-EOF
  #!/bin/bash
  sudo yum update -y
  sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
  sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
  sudo yum upgrade
  sudo amazon-linux-extras install java-openjdk11 -y (k)
  sudo yum install jenkins -y
  sudo systemctl enable jenkins
  sudo systemctl start jenkins
  EOF

  user_data_replace_on_change = true
}

#Create security group 
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Open ports 22, 8080, and 443"

  #Allow incoming TCP requests on port 22 from any IP
  ingress {
    description = "Incoming SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow incoming TCP requests on port 8080 from any IP
  ingress {
    description = "Incoming 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow incoming TCP requests on port 443 from any IP
  ingress {
    description = "Incoming 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_sg"
  }
}
#Deploy the public subnets
resource "aws_subnet" "public_subnets" {
for_each = var.public_subnets
vpc_id = aws_vpc.vpc.id
cidr_block = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
availability_zone = tolist(data.aws_availability_zones.available.
names)[each.value]
map_public_ip_on_launch = true
tags = {
Name = each.key
Terraform = "true"
}
}



#Create route tables for public and private subnets
resource "aws_route_table" "public_route_table" {
vpc_id = aws_vpc.vpc.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.internet_gateway.id

#nat_gateway_id = aws_nat_gateway.nat_gateway.id
}

tags = {
Name = "demo_public_rtb"
Terraform = "true"
}
}
resource "aws_route_table" "private_route_table" {
vpc_id = aws_vpc.vpc.id
route {
cidr_block = "0.0.0.0/0"
        
        
        
# gateway_id = aws_internet_gateway.internet_gateway.id
nat_gateway_id = aws_nat_gateway.nat_gateway.id
}
tags = {
Name = "demo_private_rtb"
Terraform = "true"
}
}



#Create route table associations
resource "aws_route_table_association" "public" {
depends_on = [aws_subnet.public_subnets]
route_table_id = aws_route_table.public_route_table.id
for_each = aws_subnet.public_subnets
subnet_id = each.value.id
}
resource "aws_route_table_association" "private" {
depends_on = [aws_subnet.private_subnets]
route_table_id = aws_route_table.private_route_table.id
for_each = aws_subnet.private_subnets
subnet_id = each.value.id
}



#Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
vpc_id = aws_vpc.vpc.id
tags = {
Name = "demo_igw"
}
}
#Create EIP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
vpc = true
depends_on = [aws_internet_gateway.internet_gateway]
tags = {
Name = "demo_igw_eip"
}
}



#Create NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
depends_on = [aws_subnet.public_subnets]
allocation_id = aws_eip.nat_gateway_eip.id
subnet_id = aws_subnet.public_subnets["public_subnet_1"].id
tags = {
Name = "demo_nat_gateway"
}
}



# Terraform Data Block - To Lookup Latest Ubuntu 20.04 AMI Image
data "aws_ami" "ubuntu" {
most_recent = true
filter {
name = "name"
values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
}
filter {
name = "virtualization-type"
values = ["hvm"]
}
owners = ["099720109477"]
}



# Terraform Resource Block - To Build EC2 instance in Public Subnet
resource "aws_instance" "web_server" {
ami = data.aws_ami.ubuntu.id
instance_type = "t2.micro"
subnet_id = aws_subnet.public_subnets["public_subnet_1"].id
tags = {
Name = "Ubuntu EC2 Server"
}
}
 # Generate SSH key
resource "tls_private_key" "generated" {
algorithm = "RSA"
}
resource "local_file" "private_key_pem" {
content = tls_private_key.generated.private_key_pem
filename = "MyAWSKey.pem"
}
                                   



resource "aws_key_pair" "generated" {
key_name = "MyAWSKey"
public_key = tls_private_key.generated.public_key_openssh
lifecycle {
ignore_changes = [key_name]
}
}



variable "us-east-1-azs" {
type = list(string)
default = [
  "us-east-1a",
"us-east-1b",
"us-east-1c",
"us-east-1d",
"us-east-1e"
]
}

# Launch template
use_lt = true
create_lt = true
image_id = data.aws_ami.ubuntu.id
instance_type = "t3.micro"
tags_as_map = {
Name = "Web EC2 Server 2"
}
}

##module "s3-bucket" {
source = "terraform-aws-modules/s3-bucket/aws"
version = "2.11.1"
}
output "s3_bucket_name" {
value = module.s3-bucket.s3_bucket_bucket_domain_name
}
