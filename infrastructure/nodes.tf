resource "hcloud_ssh_key" "ssh_public_keys" {
  for_each = {for public_ssh_key in local.public_ssh_keys : public_ssh_key.name => public_ssh_key}

  name       = each.value.name
  public_key = each.value.key
}

resource "hcloud_server" "nodes" {
  for_each = { for node in var.nodes : node.name => node }

  depends_on = [hcloud_ssh_key.ssh_public_keys]

  name        = each.value.name
  image       = each.value.image 
  location    = each.value.location
  server_type = each.value.server_type

  ssh_keys = [for name, ssh_public_key in hcloud_ssh_key.ssh_public_keys : ssh_public_key.id]
}

resource "null_resource" "nodes" {
  for_each = hcloud_server.nodes

  depends_on = [
    hcloud_server.nodes,
    hcloud_load_balancer_target.controller,
    hcloud_load_balancer_service.load_balancer_service_6443,
    hcloud_load_balancer_service.load_balancer_service_8132,
    hcloud_load_balancer_service.load_balancer_service_9443
  ]

  triggers = {
    ipv4_address = each.value.ipv4_address
    name = each.value.name
    private_ssh_key_path = var.private_ssh_key_path
  }

  connection {
    host        = self.triggers.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(self.triggers.private_ssh_key_path)
  }

  # Restic need the folder on this location to make it work 
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/lib/kubelet/",
      "ln -s /var/lib/k0s/kubelet/pods/ /var/lib/kubelet/pods"
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "k0s kubectl drain --ignore-daemonsets --delete-emptydir-data ${self.triggers.name} || true",
      "k0s etcd leave ${self.triggers.name} || true"
    ]
  }
}
