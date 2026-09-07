variable "ssh_public_key" {
  description = "Chave pública SSH para acesso"
  type        = string
}

variable "os_user" {
  description = "Usuário padrão do sistema"
  type        = string
  default     = "ubuntu"
}

variable "cloud_name" {
  description = "Nome da cloud (usado na mensagem final do cloud-init)"
  type        = string
  default     = ""
}
