module "cluster" {
  source = "../.."

  hcloud_token = var.hcloud_token
  nodes        = var.nodes
  k0s_version  = var.k0s_version
}

output "host" {
  value     = module.cluster.host
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.cluster.cluster_ca_certificate
  sensitive = true
}

output "client_certificate" {
  value     = module.cluster.client_certificate
  sensitive = true
}

output "client_key" {
  value     = module.cluster.client_key
  sensitive = true
}

output "hcloud_token" {
  value     = module.cluster.hcloud_token
  sensitive = true
}
