output "host" {
  value = local.host
  sensitive = true
}

output "cluster_ca_certificate" {
  value = local.cluster_ca_certificate 
  sensitive = true
}

output "client_certificate" {
  value = local.client_certificate 
  sensitive = true
}

output "client_key" {
  value = local.client_key 
  sensitive = true
}

output "hcloud_token" {
  value = var.hcloud_token
  sensitive = true
}

output "kubeconfig" {
  value = local.kubeconfig
  sensitive = true
}
