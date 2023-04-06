output "hello-world" {
description = "Print a Hello World text output"
value = "Hello World"
}
output "vpc_id" {
description = "Output the ID for the primary VPC"
value = aws_vpc.vpc.id
}

output "public_url" {
description = "Public URL for our Web Server"
value = "https://${aws_instance.web_server.private_ip}:8080/index.html"
}
output "vpc_information" {
description = "VPC Information about Environment"
value = "Your ${aws_vpc.vpc.tags.Environment} VPC has an ID of ${aws_vpc
.vpc.id}"
}

module "autoscaling" {
source = "terraform-aws-modules/autoscaling/aws"
version = "4.9.0"
# Autoscaling group
name = "myasg"
vpc_zone_identifier = [aws_subnet.private_subnets["private_subnet_1"].id
,
aws_subnet.private_subnets["private_subnet_2"].id,
aws_subnet.private_subnets["private_subnet_3"].id]
min_size = 0
max_size = 1
desired_capacity = 1

output "public_ip" {
description = "This is the public IP of my web server"
value = aws_instance.web_server.public_ip
}
output "ec2_instance_arn" {
value = aws_instance.web_server.arn
sensitive = true
}
