output "kubeconfig" {
  value = file("${path.module}/config")
}

output "host" {
  value = "https://128.140.25.64:6443"
}

output "cluster_ca_certificate" {
  value = "certificate-authority-data-test"
}

output "client_certificate" {
  value = "client-certificate-data-test"
}

output "client_key" {
  value = "client-key-data-test"
}
