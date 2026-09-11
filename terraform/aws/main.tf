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

module "cloud_init" {
  source = "../modules/cloud-init"

  ssh_public_key = var.ssh_public_key
  os_user        = "ubuntu"
  cloud_name     = "AWS"
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
  description = "Acesso às portas configuradas"

  dynamic "ingress" {
    for_each = var.aws_open_port_enable ? var.aws_open_port_numbers : []
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.aws_open_port_cidr]
    }
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
  ami                    = var.aws_ami_id != "" ? var.aws_ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.aws_instance_type
  key_name               = aws_key_pair.acesso.key_name
  vpc_security_group_ids = [aws_security_group.servidor.id]
  user_data              = module.cloud_init.rendered

  root_block_device {
    volume_size = var.aws_disk_size
    volume_type = "gp3"
  }

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

output "cloud_init_log_command" {
  description = "Comando para acompanhar a saída do cloud-init em tempo real"
  value       = "sudo tail -f /var/log/cloud-init-output.log"
}
