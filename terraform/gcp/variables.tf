variable "gcp_project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "gcp_credentials_file" {
  description = "Caminho do arquivo JSON da service account"
  type        = string
  sensitive   = true
}

variable "gcp_region" {
  description = "Região do GCP"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Zona do GCP"
  type        = string
  default     = "us-central1-a"
}

variable "gcp_machine_type" {
  description = "Tipo da máquina"
  type        = string
  default     = "e2-micro"
}

variable "gcp_disk_size" {
  description = "Tamanho do disco inicial em GB"
  type        = number
  default     = 50
}

variable "gcp_open_port_enable" {
  description = "Habilita a abertura das portas customizadas no firewall"
  type        = bool
  default     = true
}

variable "gcp_open_port_numbers" {
  description = "Portas TCP a liberar quando `gcp_open_port_enable` for true"
  type        = list(number)
  default     = [22, 80]
}

variable "gcp_open_port_cidr" {
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
