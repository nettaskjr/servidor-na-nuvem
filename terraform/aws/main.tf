terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "acesso" {
  key_name   = "${var.server_name}-key"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "servidor" {
  name        = "${var.server_name}-sg"
  description = "Acesso SSH (22) e HTTP (80)"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.server_name
  }
}

resource "aws_instance" "servidor" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.acesso.key_name
  vpc_security_group_ids = [aws_security_group.servidor.id]

  tags = {
    Name = var.server_name
  }
}

output "public_ip" {
  description = "IP público do servidor"
  value       = aws_instance.servidor.public_ip
}

output "ssh_command" {
  description = "Comando para acessar via SSH"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.servidor.public_ip}"
}
