variable "k0s_version" {
  type = string
}

module "k8s" {
  source = "../../../k8s"

  k0s_version          = var.k0s_version
  private_ssh_key_path = "~/.ssh/id_rsa"
  load_balancer_ipv4   = "127.0.0.4"
  drain_timeout        = 40
  nodes = {
    "controller1" = { ipv4 = "127.0.0.1", role = "controller+worker" },
    "controller2" = { ipv4 = "127.0.0.2", role = "controller+worker" },
    "controller3" = { ipv4 = "127.0.0.3", role = "controller+worker" },
  }
}

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

output "kubeconfig" {
  value = module.k8s.kubeconfig
  sensitive = true
}
