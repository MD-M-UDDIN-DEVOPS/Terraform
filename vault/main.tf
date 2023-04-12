provider "vault" {
address = "http://127.0.0.1:8200"
token = <root token>
}


data "vault_generic_secret" "phone_number" {
path = "secret/app"
}


output "phone_number" {
value = data.vault_generic_secret.phone_number.data["phone_number"]
sensitive = true
}

# Security Groups
resource "aws_security_group" "ingress-ssh" {
name = "allow-all-ssh"
vpc_id = aws_vpc.vpc.id
ingress {
cidr_blocks = [
"0.0.0.0/0"
]
from_port = 22
to_port = 22
protocol = "tcp"
}
// Terraform removes the default rule
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}


# Create Security Group - Web Traffic
resource "aws_security_group" "vpc-web" {
name = "vpc-web-${terraform.workspace}"
vpc_id = aws_vpc.vpc.id
description = "Web Traffic"
ingress {
description = "Allow Port 80"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
description = "Allow Port 443"
from_port = 443
to_port = 443


protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
egress {
description = "Allow all ip and ports outbound"
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}
resource "aws_security_group" "vpc-ping" {
name = "vpc-ping"
vpc_id = aws_vpc.vpc.id
description = "ICMP for Ping Access"
ingress {
description = "Allow ICMP Traffic"
from_port = -1
to_port = -1
protocol = "icmp"
cidr_blocks = ["0.0.0.0/0"]
}
egress {
description = "Allow all ip and ports outboun"
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_instance" "ubuntu_server" {
ami = data.aws_ami.ubuntu.id
instance_type = "t2.micro"
subnet_id = aws_subnet.public_subnets["public_subnet_1
"].id
security_groups = [aws_security_group.vpc-ping.id,
aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
associate_public_ip_address = true
key_name = aws_key_pair.generated.key_name
connection {
user = "ubuntu"
private_key = tls_private_key.generated.private_key_pem
host = self.public_ip
}
tags = {
Name = "Ubuntu EC2 Server"
}
lifecycle {
ignore_changes = [security_groups]
}
}

terraform {
backend "remote" {
hostname = "app.terraform.io"
organization = "Enterprise-Cloud"
workspaces {
name = "my-aws-app"
}
}
}
# Leave the first part of the block unchanged and create our `local-exec`
provisioner
provisioner "local-exec" {
command = "chmod 600 ${local_file.private_key_pem.filename}"
}
provisioner "remote-exec" {
inline = [
"sudo rm -rf /tmp",
"sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp
",
"sudo sh /tmp/assets/setup-web.sh",
]
}

resource "aws_subnet" "variables-subnet" {
vpc_id = aws_vpc.vpc.id
cidr_block = "10.0.250.0/24"
availability_zone = "us-east-1a"
map_public_ip_on_launch = true
tags = {
Name = "sub-variables-us-east-1a"
Terraform = "true"
}
}