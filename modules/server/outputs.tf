output "public_ip" {
value = aws_instance.web.public_ip
}
output "public_dns" {
value = aws_instance.web.public_dns
}

# Configure the AWS Provider
provider "aws" {
region = "us-west-2"
default_tags {
tags = {
Owner = "Acme"
Provisoned = "Terraform"
}
}
}