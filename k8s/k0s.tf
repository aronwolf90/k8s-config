terraform {
  required_providers {
    k0s = {
      source = "alessiodionisi/k0s"
    }
  }
}

resource "k0s_cluster" "cluster" {
  name    = "cluster"
  version = var.k0s_version

  hosts = [
    for node in var.nodes :
    {
      role = node.role,
      no_taints = tonumber(join("", regex("([0-9]+).([0-9]+)", var.k0s_version))) > 122 ? true : null
      ssh  = {
        address  = node.ipv4
        port     = 22
        user     = "root"
        key_path = var.private_ssh_key_path
      } 
      install_flags = [
        "--enable-cloud-provider=true",
        "--kubelet-extra-args=--cloud-provider=external",
      ]
    }
  ]

  config = yamlencode({
    spec = {
      api = {
        externalAddress = var.load_balancer_ipv4,
        sans = [var.load_balancer_ipv4]
      }
    }
  })
}
