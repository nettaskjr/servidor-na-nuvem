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

variable "server_name" {
  description = "Nome do servidor"
  type        = string
  default     = "servidor-basico"
}

variable "ssh_public_key" {
  description = "Chave pública SSH para acesso"
  type        = string
}
