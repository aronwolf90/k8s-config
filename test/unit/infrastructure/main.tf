terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = "123456789_123456789_123456789_123456789_123456789_123456789_1234"
}

variable "private_ssh_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "nodes" {
  type = map(
    object({
      image       = string
      location    = string
      server_type = string
      role        = string
    })
  )

  default = {
    "controller1" = { image = "ubuntu-22.04", location = "fsn1", server_type = "cx21", role = "controller+worker" },
    "controller2" = { image = "ubuntu-22.04", location = "fsn1", server_type = "cx21", role = "controller+worker" },
    "controller3" = { image = "ubuntu-22.04", location = "fsn1", server_type = "cx21", role = "controller+worker" },
  }
}

module "infrastructure" {
  source = "../../../infrastructure"

  private_ssh_key_path = var.private_ssh_key_path
  nodes                = var.nodes
}

output "nodes" {
  value = module.infrastructure.nodes
}

output "load_balancer_ipv4_address" {
  value = module.infrastructure.load_balancer_ipv4_address
}
