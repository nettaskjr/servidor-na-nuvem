variable "aws_access_key" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "aws_ami_id" {
  description = "ID da AMI (vazio = usa Ubuntu 22.04 LTS da região)"
  type        = string
  default     = ""
}

variable "aws_disk_size" {
  description = "Tamanho do disco inicial em GB"
  type        = number
  default     = 50
}

variable "server_name" {
  description = "Nome do servidor"
  type        = string
  default     = "servidor-basico"
}

variable "ssh_public_key" {
  description = "Chave pública SSH para acesso"
  type        = string
}
