terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
  }
}

# Configure Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "clouddev" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "clouddevel" {
  cidr_block        = cidrsubnet(aws_vpc.clouddev.cidr_block, 3, 1)
  vpc_id            = aws_vpc.clouddev.id
  availability_zone = var.availability_zone
}

resource "aws_internet_gateway" "clouddev_gw" {
  vpc_id = aws_vpc.clouddev.id
}

resource "aws_route_table" "clouddevel" {
  vpc_id = aws_vpc.clouddev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clouddev_gw.id
  }
}

resource "aws_route_table_association" "clouddevel" {
  subnet_id      = aws_subnet.clouddevel.id
  route_table_id = aws_route_table.clouddevel.id
}

resource "aws_security_group" "clouddev" {
  name = "allow-all"

  vpc_id = aws_vpc.clouddev.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "clouddev" {
  key_name   = var.key_pair_name
    public_key = tls_private_key.clouddev.public_key_openssh
}

resource "tls_private_key" "clouddev" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "tf_key" {
  content  = tls_private_key.clouddev.private_key_pem
  filename = var.file_name

}

resource "aws_instance" "test_env_ec2" {
  count                       = var.counter
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  security_groups             = [aws_security_group.clouddev.id]
  associate_public_ip_address = true

  subnet_id = aws_subnet.clouddevel.id

  tags = {
    Name = "${var.instance_tag}-${ count.index }"
  }
}