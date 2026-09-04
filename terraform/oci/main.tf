terraform {
  required_version = ">= 1.3"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_fingerprint
  private_key_path = var.oci_private_key_path
  region           = var.oci_region
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_compartment_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.oci_compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  is_arm_shape = length(regexall("a1", lower(var.oci_shape))) > 0

  ubuntu_images_aarch64 = [for img in data.oci_core_images.ubuntu.images : img if can(img.display_name) && length(regexall("aarch64", tostring(img.display_name))) > 0]

  selected_ubuntu_image_id = local.is_arm_shape ? try(local.ubuntu_images_aarch64[0].id, data.oci_core_images.ubuntu.images[0].id) : data.oci_core_images.ubuntu.images[0].id
}

resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.oci_compartment_ocid
  cidr_block     = "10.0.0.0/16"
  display_name   = "${var.server_name}-vcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.server_name}-igw"
}

# Security List opcional para abrir uma porta arbitrária no subnet.
# Para habilitar, defina em `terraform/oci/terraform.tfvars`:
#   open_port_enable = true
#   open_port_number = 2222          # número da porta desejada
#   open_port_cidr   = "1.2.3.4/32" # (opcional) CIDR de origem permitido
resource "oci_core_security_list" "open_port" {
  count          = var.open_port_enable ? 1 : 0
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.server_name}-open-port"

  dynamic "ingress_security_rules" {
    for_each = var.open_port_numbers
    content {
      description = "Allow port ${ingress_security_rules.value}"
      protocol    = "6" # TCP
      source      = var.open_port_cidr
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_default_route_table" "rt" {
  manage_default_resource_id = oci_core_virtual_network.vcn.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_subnet" "subnet" {
  compartment_id             = var.oci_compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "${var.server_name}-subnet"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_virtual_network.vcn.default_route_table_id
  # Anexa a Security List criada acima quando `open_port_enable` = true
  security_list_ids          = var.open_port_enable ? [oci_core_security_list.open_port[0].id] : []
}

resource "oci_core_instance" "servidor" {
  compartment_id      = var.oci_compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = var.oci_shape
  display_name        = var.server_name

  dynamic "shape_config" {
    for_each = var.oci_ocpus > 0 ? [1] : []
    content {
      ocpus         = var.oci_ocpus
      memory_in_gbs = var.oci_memory_in_gbs
    }
  }

  source_details {
    source_type = "image"
    source_id   = local.selected_ubuntu_image_id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

output "public_ip" {
  description = "IP público do servidor"
  value       = oci_core_instance.servidor.public_ip
}

output "ssh_command" {
  description = "Comando para acessar via SSH"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${oci_core_instance.servidor.public_ip}"
}
