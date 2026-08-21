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

resource "google_compute_network" "rede" {
  name                    = "${var.server_name}-vpc"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.server_name}-allow-ssh"
  network = google_compute_network.rede.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "http" {
  name    = "${var.server_name}-allow-http"
  network = google_compute_network.rede.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
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
      size  = 20
    }
  }

  network_interface {
    network = google_compute_network.rede.name
    access_config {
      # IP público efêmero
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
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
