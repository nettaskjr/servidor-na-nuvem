terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project     = var.gcp_project_id
  credentials = var.gcp_credentials_file
  region      = var.gcp_region
  zone        = var.gcp_zone
}

module "cloud_init" {
  source = "../modules/cloud-init"

  ssh_public_key = var.ssh_public_key
  os_user        = "ubuntu"
  cloud_name     = "GCP"
}

resource "google_compute_network" "rede" {
  name                    = "${var.server_name}-vpc"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "open_ports" {
  count   = var.gcp_open_port_enable ? 1 : 0
  name    = "${var.server_name}-allow-ports"
  network = google_compute_network.rede.name

  allow {
    protocol = "tcp"
    ports    = [for p in var.gcp_open_port_numbers : tostring(p)]
  }

  source_ranges = [var.gcp_open_port_cidr]
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "servidor" {
  name         = var.server_name
  machine_type = var.gcp_machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.gcp_disk_size
    }
  }

  network_interface {
    network = google_compute_network.rede.name
    access_config {
      # IP público efêmero
    }
  }

  metadata = {
    ssh-keys  = "ubuntu:${var.ssh_public_key}"
    user-data = module.cloud_init.rendered
  }
}

output "public_ip" {
  description = "IP público do servidor"
  value       = google_compute_instance.servidor.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "Comando para acessar via SSH"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${google_compute_instance.servidor.network_interface[0].access_config[0].nat_ip}"
}

output "cloud_init_log_command" {
  description = "Comando para acompanhar a saída do cloud-init em tempo real"
  value       = "sudo tail -f /var/log/cloud-init-output.log"
}
