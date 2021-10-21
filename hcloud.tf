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

provider "hcloud" {
  token = var.hcloud_token
}

variable "private_key" {
  default = "~/.ssh/id_rsa"
}

resource "hcloud_ssh_key" "default" {
  name = "Default ssh key"
  public_key = file(var.public_key)
}

resource "hcloud_server" "master" {
  name        = "master"
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
  type             = "server"
  load_balancer_id = hcloud_load_balancer.master.id
  server_id        = hcloud_server.master.id
}

resource "hcloud_load_balancer_service" "load_balancer_service" {
  load_balancer_id = hcloud_load_balancer.master.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

resource "null_resource" "setup_master" {
  triggers = {
    server_id          = hcloud_server.master.id
    kubernetes_version = var.kubernetes_version
  }

  connection {
    host        = hcloud_server.master.ipv4_address
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
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /backups"
    ]
  }
  provisioner "file" {
    source      = "backups/"
    destination = "/backups/"
  }
  provisioner "remote-exec" {
    inline = [
      # Install
      "export HCLOUD_TOKEN=${var.hcloud_token}",
      "export LOAD_BALANCER_IP=${hcloud_load_balancer.master.ipv4}",
      "export SSH_KEY=${hcloud_ssh_key.default.id}",
      "export LOCATION=${var.location}",
      "export KUBERNETES_VERSION=${var.kubernetes_version}",
      "bash /tmp/install_master.sh",
    ]
  }
}

data "external" "token" {
  depends_on = [null_resource.setup_master]

  program = [
    "bash",
    "-c",
    "MASTER_IP=${hcloud_server.master.ipv4_address} ${path.module}/get_token.sh"
  ]
}

output "token" {
  value = data.external.token.result.token 
}

output "host" {
  value = "https://${hcloud_load_balancer.master.ipv4}:6443"
}
