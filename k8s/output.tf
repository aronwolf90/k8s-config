output "kubeconfig" {
  value    = k0s_cluster.cluster.kubeconfig
  sensitive = true
}

output "host" {
  value = "${yamldecode(k0s_cluster.cluster.kubeconfig)["clusters"][0]["cluster"]["server"]}"
}

output "cluster_ca_certificate" {
  value = "${base64decode(yamldecode(k0s_cluster.cluster.kubeconfig)["clusters"][0]["cluster"]["certificate-authority-data"])}"
  sensitive = true
}

output "client_certificate" {
  value = "${base64decode(yamldecode(k0s_cluster.cluster.kubeconfig)["users"][0]["user"]["client-certificate-data"])}"
  sensitive = true
}

output "client_key" {
  value = "${base64decode(yamldecode(k0s_cluster.cluster.kubeconfig)["users"][0]["user"]["client-key-data"])}"
  sensitive = true
}
