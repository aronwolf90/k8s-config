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
variable "private_key" {
  default = "~/.ssh/id_rsa"
}

provider "hcloud" {
  token = var.hcloud_token
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
}

resource "hcloud_floating_ip" "master" {
  name      = "masterv1"
  type      = "ipv4"
  server_id = hcloud_server.master.id
}

resource "null_resource" "install_kubernetes" {
  depends_on = [
    hcloud_server.master,
    hcloud_floating_ip.master
  ]

  triggers = {
    hcloud_server_master_id = hcloud_server.master.id
  }

  connection {
    host        = hcloud_server.master.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key)
  }
  provisioner "file" {
    source      = "ca.crt"
    destination = "/tmp/ca.crt"
  }
  provisioner "file" {
    source      = "ca.key"
    destination = "/tmp/ca.key"
  }
  provisioner "file" {
    source      = "install_kubedm.rb"
    destination = "/tmp/install_kubedm.rb"
  }
  provisioner "remote-exec" {
    inline = [
      "ip addr add ${hcloud_floating_ip.master.ip_address} dev eth0",
      "mkdir -p /etc/kubernetes/pki/",
      "cp /tmp/ca.crt /etc/kubernetes/pki/ca.crt",
      "cp /tmp/ca.key /etc/kubernetes/pki/ca.key",
      # Install
      "bash /tmp/install_kubedm.rb",
      "kubeadm init --apiserver-advertise-address ${hcloud_floating_ip.master.ip_address} --ignore-preflight-errors=DirAvailable--var-lib-etcd --pod-network-cidr=10.244.0.0/16",
      "curl -LO \"https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl annotate node master flannel.alpha.coreos.com/public-ip-overwrite=${hcloud_floating_ip.master.ip_address}",
      "kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml",
      "kubectl create secret generic hcloud-csi -n kube-system --from-literal=token=${var.hcloud_token}",
      "kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.5.1/deploy/kubernetes/hcloud-csi.yml"
    ]
  }
}

resource "hcloud_server" "node1" {
  depends_on   = [null_resource.install_kubernetes]

  name        = "node1"
  image       = "ubuntu-20.04"
  server_type = "cx31"
  ssh_keys    = [hcloud_ssh_key.default.id]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key)
  }
  provisioner "file" {
    source      = "install_kubedm.rb"
    destination = "/tmp/install_kubedm.rb"
  }
  provisioner "remote-exec" {
    inline = [
      "bash /tmp/install_kubedm.rb",
      data.external.kubeadm_join.result.command
    ]
  }
}

data "external" "kubeadm_join" {
  program = ["./kubeadm_token.sh"]

  query = {
    host = hcloud_server.master.ipv4_address
    key = var.private_key
  }

  depends_on = [null_resource.install_kubernetes]
}
