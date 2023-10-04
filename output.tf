output "host" {
  value = module.k8s.host
  sensitive = true
}

output "cluster_ca_certificate" {
  value = module.k8s.cluster_ca_certificate
  sensitive = true
}

output "client_certificate" {
  value = module.k8s.client_certificate
  sensitive = true
}

output "client_key" {
  value = module.k8s.client_key
  sensitive = true
}

output "hcloud_token" {
  value = var.hcloud_token
  sensitive = true
}

output "kubeconfig" {
  value = module.k8s.kubeconfig
  sensitive = true
}
