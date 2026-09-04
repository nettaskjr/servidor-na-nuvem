variable "oci_tenancy_ocid" {
  description = "Tenancy OCID"
  type        = string
}

variable "oci_user_ocid" {
  description = "User OCID"
  type        = string
}

variable "oci_fingerprint" {
  description = "Fingerprint da chave de API"
  type        = string
}

variable "oci_private_key_path" {
  description = "Caminho da chave privada PEM"
  type        = string
  sensitive   = true
}

variable "oci_region" {
  description = "Região da OCI"
  type        = string
  default     = "us-ashburn-1"
}

variable "oci_compartment_ocid" {
  description = "Compartment OCID"
  type        = string
}

variable "oci_shape" {
  description = "Shape da instância"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "oci_ocpus" {
  description = "OCPUs (shapes flexíveis). Deixe 0 para shapes não-flexíveis"
  type        = number
  default     = 0
}

variable "oci_memory_in_gbs" {
  description = "Memória em GB (shapes flexíveis). Deixe 0 para shapes não-flexíveis"
  type        = number
  default     = 0
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

# Opção para abrir portas arbitrárias na Security List do subnet
# Habilite definindo `open_port_enable = true` em terraform.tfvars
variable "open_port_enable" {
  description = "Habilita abertura de portas customizadas na Security List do subnet"
  type        = bool
  default     = true
}

variable "open_port_numbers" {
  description = "Vetor com números de portas a abrir quando `open_port_enable` for true"
  type        = list(number)
  default     = [8000]
}

variable "open_port_cidr" {
  description = "CIDR fonte permitido para as portas abertas (ex: 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}
