terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
        source = "harshicorp/aws"
        version = "~> 3.0"

    }
  }
}
