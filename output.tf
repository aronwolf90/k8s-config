output "host" {
  value = "https://${hcloud_load_balancer.master.ipv4}:6443"
}

output "token" {
  value = base64decode(data.external.get_access_data.result.token)
}

output "cluster_ca_certificate" {
  value = base64decode(data.external.get_access_data.result.cluster_ca_certificate)
}

output "master_nodes" {
  value = {
    for key, node in hcloud_server.master : key => { ipv4_address = node.ipv4_address }
  }
}

output "hcloud_token" {
  value = var.hcloud_token
}
