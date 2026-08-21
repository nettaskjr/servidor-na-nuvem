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

variable "server_name" {
  description = "Nome do servidor"
  type        = string
  default     = "servidor-basico"
}

variable "ssh_public_key" {
  description = "Chave pública SSH para acesso"
  type        = string
}
