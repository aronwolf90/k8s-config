terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

variable "hcloud_token" {}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name = "Default ssh key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "hcloud_server" "master" {
  name        = "master"
  image       = "ubuntu-20.04"
  server_type = "cx21"
  ssh_keys    = [hcloud_ssh_key.default.id]

}

resource "hcloud_floating_ip" "master" {
  name      = "master"
  type      = "ipv4"
  server_id = hcloud_server.master.id
}

resource "hcloud_volume" "master_config" {
  name       = "master_config"
  size       = 10
  format     = "ext4"
  server_id  = hcloud_server.master.id
}

resource "hcloud_volume" "master_etcd" {
  depends_on = [hcloud_volume.master_config]

  name       = "master_etcd"
  size       = 15
  format     = "ext4"
  server_id  = hcloud_server.master.id
}

resource "null_resource" "install_kubernetes" {
  depends_on = [
    hcloud_volume.master_config,
    hcloud_volume.master_etcd,
    hcloud_server.master,
    hcloud_floating_ip.master
  ]

  connection {
    host        = hcloud_server.master.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
  }
  provisioner "file" {
    source      = "kubeadm_token.sh"
    destination = "/usr/bin/kubeadm_token.sh"
  }
  provisioner "file" {
    source      = "install_kubedm.rb"
    destination = "/tmp/install_kubedm.rb"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod u+xrw /usr/bin/kubeadm_token.sh",
      "ip addr add ${hcloud_floating_ip.master.ip_address} dev eth0",
      "mkdir -p /etc/kubernetes",
      "mkfs.ext4 -F ${hcloud_volume.master_config.linux_device}",
      "mount -o discard,defaults ${hcloud_volume.master_config.linux_device} /etc/kubernetes",
      "echo \"${hcloud_volume.master_config.linux_device} /etc/kubernetes $FILESYSTEM discard,nofail,defaults 0 0\" >> /etc/fstab",
      "mkdir -p /var/lib/etcd",
      "mount -o discard,defaults ${hcloud_volume.master_etcd.linux_device} /var/lib/etcd",
      "echo \"${hcloud_volume.master_etcd.linux_device} /var/lib/etcd ext4 discard,nofail,defaults 0 0\" >> /etc/fstab",
      "rm -r /var/lib/etcd/lost+found/ || true",
      "bash /tmp/install_kubedm.rb",
      "kubeadm init --apiserver-advertise-address ${hcloud_floating_ip.master.ip_address} --ignore-preflight-errors=DirAvailable--var-lib-etcd",
      "curl -LO \"https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
    ]
  }
}

resource "null_resource" "configure_kubernetes" {
  depends_on = [null_resource.install_kubernetes]

  connection {
    host        = hcloud_server.master.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
  }
  provisioner "remote-exec" {
    inline = [
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
    private_key = file("~/.ssh/id_rsa")
  }
  provisioner "file" {
    source      = "install_kubedm.rb"
    destination = "/tmp/install_kubedm.rb"
  }
  provisioner "remote-exec" {
    inline = [
      "bash /tmp/install_kubedm.rb",
      "${data.external.kubeadm_join.result.command}"
    ]
  }
}

data "external" "kubeadm_join" {
  program = ["./kubeadm_token.sh"]

  query = {
    host = hcloud_server.master.ipv4_address
  }

  depends_on = [null_resource.install_kubernetes]
}
