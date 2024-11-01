terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "clouddevel" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "clouddevel"
  }

}