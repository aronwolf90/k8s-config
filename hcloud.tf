terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "ssh_public_keys" {
  for_each = local.transfored_public_ssh_keys

  name       = each.key
  public_key = each.value
}

resource "hcloud_server" "master" {
  for_each = local.transformed_master_nodes

  name        = each.key
  image       = each.value.image
  server_type = "cx21"
  location    = each.value.location
  ssh_keys    = [for _, public_ssh_value in hcloud_ssh_key.ssh_public_keys : public_ssh_value.id]
}

resource "hcloud_load_balancer" "master" {
  name               = "master"
  load_balancer_type = "lb11"
  depends_on         = [hcloud_server.master]
  location           = var.master_load_balancer_location
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

resource "null_resource" "remove_master" {
  for_each = hcloud_server.master

  triggers = {
    private_key  = var.private_key
    ipv4_address = each.value.ipv4_address
  }

  connection {
    host        = self.triggers.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(self.triggers.private_key)
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

resource "null_resource" "clean" {
  depends_on = [
    hcloud_server.master,
    hcloud_load_balancer.master,
    hcloud_load_balancer_target.master,
    hcloud_load_balancer_service.load_balancer_service
  ]

  triggers = {
    hcloud_token = var.hcloud_token
  }

  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      export HCLOUD_TOKEN=${self.triggers.hcloud_token}
      bash ${path.module}/delete_worder_nodes.sh
    EOT
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
    source      = "${path.module}/install_kubeadm.sh"
    destination = "/tmp/install_kubeadm.sh"
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
  provisioner "file" {
    source      = "${path.module}/master_setup.yml"
    destination = "/tmp/master_setup.yml"
  }
  provisioner "file" {
    source      = "${path.module}/get_worker_nodes_need_restart.sh"
    destination = "/tmp/get_worker_nodes_need_restart.sh"
  }
  provisioner "file" {
    source      = "${path.module}/restart_worker_node.sh"
    destination = "/tmp/restart_worker_node.sh"
  }
  provisioner "local-exec" {
    command = <<EOT
      if [ ${var.main_master_name} != ${each.key} ]; then
        export MAIN_MASTER_IP=${hcloud_server.master[var.main_master_name].ipv4_address}
        ${path.module}/generate_join_command.sh
      else
        touch ${path.module}/master_join_command.txt
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
      "export SSH_KEY=${hcloud_ssh_key.ssh_public_keys[local.worker_public_ssh_key].id}",
      "export LOCATION=${var.worker_node_location}",
      "export KUBERNETES_VERSION=${var.kubernetes_version}",
      "export WORKER_SERVER_TYPE=${var.worker_node_type}",
      "if [ ${var.main_master_name} != ${each.key} ]; then export MASTER_JOIN_COMMAND=\"$(cat /tmp/master_join_command.txt)\"; fi",
      "apt update -y && apt install ansible -y",
      "ansible-playbook /tmp/master_setup.yml --extra-vars=\"{ ssh_keys: ['${join("','",local.public_ssh_key_list)}'] }\"",
    ]
  }
}

resource "null_resource" "config_master" {
  depends_on = [
    null_resource.setup_master
  ]

  triggers = {
    kubernetes_version = var.kubernetes_version
    worker_node_type   = var.worker_node_type
  }

  connection {
    host        = hcloud_server.master[var.main_master_name].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/install_kubeadm.sh"
    destination = "/tmp/install_kubeadm.sh"
  }
  provisioner "file" {
    source      = "${path.module}/install_cluster_autoscaler.sh"
    destination = "/tmp/install_cluster_autoscaler.sh"
  }
  provisioner "file" {
    source      = "${path.module}/hcloud.sh"
    destination = "/tmp/hcloud.sh"
  }
  provisioner "file" {
    source      = "${path.module}/master_config.yml"
    destination = "/tmp/master_config.yml"
  }
  provisioner "file" {
    source      = "${path.module}/get_worker_nodes_need_restart.sh"
    destination = "/tmp/get_worker_nodes_need_restart.sh"
  }
  provisioner "file" {
    source      = "${path.module}/restart_worker_node.sh"
    destination = "/tmp/restart_worker_node.sh"
  }
  provisioner "file" {
    source      = "${path.module}/master_config.sh"
    destination = "/tmp/master_config.sh"
  }
  provisioner "remote-exec" {
    inline = [
      # Install
      "export HCLOUD_TOKEN=${var.hcloud_token}",
      "export LOAD_BALANCER_IP=${hcloud_load_balancer.master.ipv4}",
      "export SSH_KEY=${hcloud_ssh_key.ssh_public_keys[local.worker_public_ssh_key].id}",
      "export LOCATION=${var.worker_node_location}",
      "export KUBERNETES_VERSION=${var.kubernetes_version}",
      "export WORKER_SERVER_TYPE=${var.worker_node_type}",
      "apt update -y && apt install ansible -y",
      "ansible-playbook /tmp/master_config.yml",
    ]
  }
}

data "external" "get_access_data" {
  depends_on = [null_resource.setup_master]

  program = [
    "bash",
    "-c",
    "PRIVATE_KEY=\"${var.private_key}\" MASTER_IPS=\"${join(" ", [for key, node in hcloud_server.master : node.ipv4_address])}\" ${path.module}/get_access_data.sh"
  ]
}
