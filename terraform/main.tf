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

resource "aws_security_group_rule" "allow_kib_access" {
  type              = "ingress"
  from_port         = 5601
  to_port           = 5601
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.clouddev.id
}

resource "aws_security_group_rule" "allow_es_access" {
  type              = "ingress"
  from_port         = 9200
  to_port           = 9200
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.clouddev.id
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
  content         = tls_private_key.clouddev.private_key_pem
  filename        = var.file_name
  file_permission = "0400"

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

  # Provisioners for configuring the EC2 instance after it's launched
  provisioner "file" {
    source      = "./scripts/deploy_elastic_in_docker.sh"  # Source path of the file to transfer
    destination = "/tmp/deploy_elastic_in_docker.sh"       # Destination path on the instance
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/deploy_elastic_in_docker.sh",         # Make the script executable
      "/tmp/deploy_elastic_in_docker.sh",
      "sudo docker ps -a | grep elasticsearch | awk '{print $1}' | xargs sudo docker container logs | grep -a1 Password",
      "sudo docker ps -a | grep elasticsearch | awk '{print $1}' | xargs sudo docker container logs | grep -a1 'Copy the following enrollment token and paste it into Kibana in your browser'", # Execute the script
    ]
  }

  # Connection block to specify how Terraform connects to the instance for provisioning
  connection {
    type        = "ssh"
    user        = "ubuntu"             # Default username for Ubuntu AMIs
    private_key = file(var.file_name)  # Private key for SSH access
    host        = self.public_ip       # Use the instance's public IP address for SSH connection
  }
}
