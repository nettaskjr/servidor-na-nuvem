locals {
  rendered = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    os_user        = var.os_user
    ssh_public_key = var.ssh_public_key
    cloud_name     = var.cloud_name
  })
}

output "rendered" {
  description = "Conteúdo do cloud-init renderizado"
  value       = local.rendered
}

output "rendered_base64" {
  description = "Conteúdo do cloud-init renderizado e codificado em base64"
  value       = base64encode(local.rendered)
}
