variable "proxmox_api_url" {
  description = "URL da API do Proxmox (ex.: https://pve.exemplo.com:8006/api2/json)"
  type        = string
}

variable "proxmox_token_id" {
  description = "Token ID (ex.: terraform@pve!token)"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Token Secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nome do node Proxmox"
  type        = string
}

variable "proxmox_vm_id" {
  description = "ID da VM a ser criada"
  type        = number
  default     = 100
}

variable "proxmox_template_id" {
  description = "ID do template com cloud-init a ser clonado"
  type        = number
  default     = 9000
}

variable "vm_name" {
  description = "Nome do servidor"
  type        = string
  default     = "servidor-basico"
}

variable "vm_user" {
  description = "Usuário criado via cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "Chave pública SSH para acesso"
  type        = string
}
