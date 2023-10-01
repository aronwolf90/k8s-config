locals {
  kubeconfig = file("config") 
}

output "host" {
  value = local.host
}

output "cluster_ca_certificate" {
  value = local.cluster_ca_certificate 
}

output "client_certificate" {
  value = local.client_certificate 
}

output "client_key" {
  value = local.client_key 
}

output "public_ssh_keys" {
  value = local.public_ssh_keys
}
