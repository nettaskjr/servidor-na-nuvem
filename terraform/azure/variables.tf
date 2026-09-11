variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Azure Client ID (App ID)"
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "azure_location" {
  description = "Localização (região) do Azure"
  type        = string
  default     = "eastus"
}

variable "azure_vm_size" {
  description = "Tamanho da VM"
  type        = string
  default     = "Standard_B1s"
}

variable "azure_disk_size" {
  description = "Tamanho do disco inicial em GB"
  type        = number
  default     = 50
}

variable "azure_open_port_enable" {
  description = "Habilita a abertura das portas customizadas no Network Security Group"
  type        = bool
  default     = true
}

variable "azure_open_port_numbers" {
  description = "Portas TCP a liberar quando `azure_open_port_enable` for true"
  type        = list(number)
  default     = [22, 80]
}

variable "azure_open_port_cidr" {
  description = "CIDR de origem permitido para as portas liberadas"
  type        = string
  default     = "0.0.0.0/0"
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
