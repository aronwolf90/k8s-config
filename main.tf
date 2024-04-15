terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    k0s = {
      source = "alessiodionisi/k0s"
    }
    null  = {}
    local = {}
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

module "infrastructure" {
  source = "./infrastructure"

  public_ssh_keys      = var.public_ssh_keys
  private_ssh_key_path = var.private_ssh_key_path
  nodes                = var.nodes
}

module "k8s" {
  depends_on = [module.infrastructure]

  source = "./k8s"

  k0s_version          = var.k0s_version
  private_ssh_key_path = var.private_ssh_key_path
  load_balancer_ipv4   = module.infrastructure.load_balancer_ipv4_address
  nodes                = module.infrastructure.nodes
  drain_timeout        = var.drain_timeout
}

module "config" {
  depends_on = [module.infrastructure, module.k8s]

  source = "./config"

  kubeconfig   = module.k8s.kubeconfig
  hcloud_token = var.hcloud_token
}
