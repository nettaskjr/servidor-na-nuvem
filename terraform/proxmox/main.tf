terraform {
  required_version = ">= 1.3"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.48"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
  insecure  = true
}

resource "proxmox_virtual_environment_vm" "servidor" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.proxmox_vm_id

  clone {
    vm_id = var.proxmox_template_id
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = var.vm_user
      keys     = [var.ssh_public_key]
    }
  }
}

output "vm_id" {
  description = "ID da VM criada"
  value       = proxmox_virtual_environment_vm.servidor.vm_id
}

output "vm_name" {
  description = "Nome da VM criada"
  value       = proxmox_virtual_environment_vm.servidor.name
}
