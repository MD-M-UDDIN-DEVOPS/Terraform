resource "aws_instance" "web" {
ami = var.ami
instance_type = var.size
subnet_id = var.subnet_id
vpc_security_group_ids = var.security_groups
tags = {
"Name" = "Server from Module"
"Environment" = "Training"
}
}

######### module "autoscaling" {
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