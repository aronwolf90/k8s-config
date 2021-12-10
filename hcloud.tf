terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

variable "hcloud_token" {}

variable "location" {
  default = "fsn1"
}
variable "kubernetes_version" {
  default = "1.19.15"
}

variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "master_nodes" {
  type = list(
    object({
      name     = string
      image    = string
    })
  )

  default = [
    { name = "master", image = "ubuntu-20.04" },
  ]
}

variable "main_master_name" {
  default = "master"
}

provider "hcloud" {
  token = var.hcloud_token
}

locals {
  transformed_master_nodes = {for node in var.master_nodes : node.name => { image = node.image }}
}

variable "private_key" {
  default = "~/.ssh/id_rsa"
}

resource "hcloud_ssh_key" "default" {
  name       = "Default ssh key"
  public_key = file(var.public_key)
}

resource "hcloud_server" "master" {
  for_each = local.transformed_master_nodes

  name        = each.key
  image       = "ubuntu-20.04"
  server_type = "cx21"
  ssh_keys    = [hcloud_ssh_key.default.id]
  location    = var.location
}

resource "hcloud_load_balancer" "master" {
  name               = "master"
  load_balancer_type = "lb11"
  depends_on         = [hcloud_server.master]
  location           = var.location
}

resource "hcloud_load_balancer_target" "master" {
  for_each = hcloud_server.master

  depends_on = [
    hcloud_server.master
  ]

  type             = "server"
  load_balancer_id = hcloud_load_balancer.master.id
  server_id        = each.value.id
}

resource "hcloud_load_balancer_service" "load_balancer_service" {
  load_balancer_id = hcloud_load_balancer.master.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

resource "null_resource" "clean" {
  for_each = hcloud_server.master

  depends_on = [
    hcloud_server.master,
    hcloud_load_balancer.master,
    hcloud_load_balancer_target.master,
    hcloud_load_balancer_service.load_balancer_service
  ]

  triggers = {
    private_key  = var.private_key
    ipv4_address = each.value.ipv4_address
    hcloud_token = var.hcloud_token
  }

  connection {
    host        = self.triggers.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(self.triggers.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/delete_worder_nodes.sh"
    destination = "/usr/local/bin/delete_worder_nodes.sh"
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "export HCLOUD_TOKEN=${self.triggers.hcloud_token}",
      "bash /usr/local/bin/delete_worder_nodes.sh"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/remove_master_from_cluster.sh"
    destination = "/usr/local/bin/remove_master_from_cluster.sh"
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "export NAME=${each.key}",
      "bash /usr/local/bin/remove_master_from_cluster.sh"
    ]
  }

}

resource "null_resource" "setup_master" {
  for_each = hcloud_server.master

  triggers = {
    server_id          = each.value.id
    kubernetes_version = var.kubernetes_version
  }

  connection {
    host        = each.value.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/install_kubedm.sh"
    destination = "/tmp/install_kubedm.sh"
  }
  provisioner "file" {
    source      = "${path.module}/install_cluster_autoscaler.sh"
    destination = "/tmp/install_cluster_autoscaler.sh"
  }
  provisioner "file" {
    source      = "${path.module}/install_master.sh"
    destination = "/tmp/install_master.sh"
  }
  provisioner "file" {
    source      = "${path.module}/hcloud.sh"
    destination = "/tmp/hcloud.sh"
  }
  provisioner "file" {
    source      = "${path.module}/token.yaml"
    destination = "/tmp/token.yaml"
  }
  provisioner "local-exec" {
    command = <<EOT
      if [ ${var.main_master_name} != ${each.key} ]; then
        export MAIN_MASTER_IP=${hcloud_server.master[var.main_master_name].ipv4_address}
        ${path.module}/generate_join_command.sh
      fi
    EOT
  }
  provisioner "file" {
    source      = "${path.module}/master_join_command.txt"
    destination = "/tmp/master_join_command.txt"
  }
  provisioner "remote-exec" {
    inline = [
      # Install
      "export HCLOUD_TOKEN=${var.hcloud_token}",
      "export LOAD_BALANCER_IP=${hcloud_load_balancer.master.ipv4}",
      "export SSH_KEY=${hcloud_ssh_key.default.id}",
      "export LOCATION=${var.location}",
      "export KUBERNETES_VERSION=${var.kubernetes_version}",
      "if [ ${var.main_master_name} != ${each.key} ]; then export MASTER_JOIN_COMMAND=\"$(cat /tmp/master_join_command.txt)\"; fi",
      "bash /tmp/install_master.sh",
    ]
  }
}

data "external" "token" {
  depends_on = [null_resource.setup_master]

  program = [
    "bash",
    "-c",
    "MASTER_IPS=\"${join(" ",[for key, node in hcloud_server.master : node.ipv4_address])}\" ${path.module}/get_token.sh"
  ]
}

output "token" {
  value = data.external.token.result.token
}

output "host" {
  value = "https://${hcloud_load_balancer.master.ipv4}:6443"
}

output "master_nodes" {
  value = {
    for key, node in hcloud_server.master : key => { ipv4_address = node.ipv4_address }
  }
}
