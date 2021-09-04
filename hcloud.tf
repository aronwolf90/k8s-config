terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

variable "hcloud_token" {}
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

resource "hcloud_volume" "data" {
  name      = "data"
  size      = 10
  format    = "ext4"
  location  = "hel1"
}

resource "hcloud_volume_attachment" "data" {
  volume_id = hcloud_volume.data.id
  server_id = hcloud_server.master.id
  automount = true
}

resource "hcloud_server" "master" {
  name        = "master"
  image       = "ubuntu-20.04"
  server_type = "cx21"
  ssh_keys    = [hcloud_ssh_key.default.id]
}

resource "null_resource" "setup_master" {
  triggers = {
    server_id        = hcloud_server.master.id
    volume_id        = hcloud_volume_attachment.data.id
  }

  connection {
    host        = hcloud_server.master.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = "install_kubedm.sh"
    destination = "/tmp/install_kubedm.sh"
  }
  provisioner "file" {
    source      = "install_cluster_autoscaler.sh"
    destination = "/tmp/install_cluster_autoscaler.sh"
  }
  provisioner "file" {
    source      = "install_master.sh"
    destination = "/tmp/install_master.sh"
  }
  provisioner "remote-exec" {
    inline = [
      # Install
      "export HCLOUD_TOKEN=${var.hcloud_token}",
      "export IP_ADDRESS=${hcloud_server.master.ipv4_address}",
      "export SSH_KEY=${hcloud_ssh_key.default.id}",
      "bash /tmp/install_master.sh",
    ]
  }
}
